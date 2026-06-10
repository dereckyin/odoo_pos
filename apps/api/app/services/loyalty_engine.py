"""Server-side loyalty: earn, redeem, coupon, auto level upgrade."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Coupon, LoyaltyRule, Member, MemberLevel, PointTransaction, Tenant

DEFAULT_LOYALTY = {
    "earn_enabled": True,
    "redeem_enabled": True,
    "point_value_cents": 1,
    "max_redeem_pct": 50,
    "point_expiry_days": 365,
    "auto_level": True,
}


def loyalty_settings(tenant: Tenant | None) -> dict:
    raw = (tenant.settings or {}).get("loyalty", {}) if tenant else {}
    return {**DEFAULT_LOYALTY, **raw}


async def load_active_earn_rules(db: AsyncSession, tenant_id: str) -> list[LoyaltyRule]:
    now = datetime.now(timezone.utc)
    rows = (
        await db.execute(
            select(LoyaltyRule)
            .where(
                LoyaltyRule.tenant_id == tenant_id,
                LoyaltyRule.deleted_at.is_(None),
                LoyaltyRule.is_active.is_(True),
                LoyaltyRule.rule_type == "earn",
            )
            .order_by(LoyaltyRule.sort_order)
        )
    ).scalars().all()
    out: list[LoyaltyRule] = []
    for r in rows:
        if r.valid_from and r.valid_from > now:
            continue
        if r.valid_to and r.valid_to < now:
            continue
        out.append(r)
    return out


def calculate_earn_points(
    total_cents: int,
    rules: list[LoyaltyRule],
    level_multiplier: float = 1.0,
) -> int:
    if total_cents <= 0:
        return 0
    if not rules:
        return max(0, total_cents // 100)
    earned = 0
    for rule in rules:
        if rule.spend_cents <= 0:
            continue
        base = total_cents // rule.spend_cents
        mult = rule.level_multiplier * level_multiplier
        earned += int(base * rule.points_awarded * mult)
    return max(0, earned)


def max_redeemable_points(
    member_points: int,
    order_total_cents: int,
    settings: dict,
) -> int:
    if not settings.get("redeem_enabled"):
        return 0
    point_value = max(1, int(settings.get("point_value_cents", 1)))
    max_by_pct = int(order_total_cents * settings.get("max_redeem_pct", 50) / 100 // point_value)
    return max(0, min(member_points, max_by_pct))


def points_discount_cents(points: int, settings: dict) -> int:
    return points * max(1, int(settings.get("point_value_cents", 1)))


def coupon_discount_cents(coupon: Coupon, items_total_cents: int) -> int:
    """Compute the monetary discount a coupon applies to a line-items subtotal.

    - ``percentage``: ``value`` is a percent (e.g. 10 => 10% off).
    - ``amount``: ``value`` is a flat cent discount.
    - ``freeItem``: settled item-side at POS; no subtotal discount here.
    """
    if items_total_cents <= 0:
        return 0
    ctype = (coupon.type or "").lower()
    value = int(coupon.value or 0)
    if ctype == "percentage":
        pct = max(0, min(100, value))
        return min(items_total_cents, items_total_cents * pct // 100)
    if ctype == "amount":
        return min(items_total_cents, max(0, value))
    return 0


async def preview_coupon(
    db: AsyncSession,
    *,
    tenant_id: str,
    code: str | None,
    member_id: str | None,
    order_total_cents: int,
) -> Coupon | None:
    """Validate a coupon without consuming it. Raises on invalid coupons."""
    if not code:
        return None
    c = (
        await db.execute(
            select(Coupon).where(
                Coupon.tenant_id == tenant_id,
                Coupon.code == code,
                Coupon.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not c:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "coupon not found")
    if c.used_at:
        raise HTTPException(status.HTTP_409_CONFLICT, "coupon already used")
    now = datetime.now(timezone.utc)
    if c.expires_at and c.expires_at < now:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "coupon expired")
    if c.min_spend_cents and order_total_cents < c.min_spend_cents:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "order below coupon minimum spend")
    if c.member_id and c.member_id != member_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "coupon not for this member")
    return c


async def validate_and_redeem_coupon(
    db: AsyncSession,
    *,
    tenant_id: str,
    code: str | None,
    member_id: str | None,
    order_total_cents: int,
    order_id: str,
) -> Coupon | None:
    if not code:
        return None
    c = (
        await db.execute(
            select(Coupon).where(
                Coupon.tenant_id == tenant_id,
                Coupon.code == code,
                Coupon.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not c:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "coupon not found")
    if c.used_at:
        raise HTTPException(status.HTTP_409_CONFLICT, "coupon already used")
    now = datetime.now(timezone.utc)
    if c.expires_at and c.expires_at < now:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "coupon expired")
    if c.min_spend_cents and order_total_cents < c.min_spend_cents:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "order below coupon minimum spend")
    if c.member_id and c.member_id != member_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "coupon not for this member")
    c.used_at = now
    c.used_in_order_id = order_id
    return c


async def auto_upgrade_level(db: AsyncSession, member: Member, tenant_id: str) -> str | None:
    levels = (
        await db.execute(
            select(MemberLevel)
            .where(MemberLevel.tenant_id == tenant_id, MemberLevel.deleted_at.is_(None))
            .order_by(MemberLevel.sort_order.desc())
        )
    ).scalars().all()
    if not levels:
        return None
    best: MemberLevel | None = None
    for lvl in levels:
        if member.total_spent_cents >= lvl.min_spend and member.points >= lvl.min_points:
            best = lvl
            break
    if best and member.level_id != best.id:
        member.level_id = best.id
        return best.id
    return None


async def apply_order_loyalty(
    db: AsyncSession,
    *,
    tenant: Tenant,
    member: Member,
    order_id: str,
    order_total_cents: int,
    points_redeemed: int = 0,
    coupon_code: str | None = None,
) -> tuple[int, int]:
    """Returns (earned_points, redeemed_points). Mutates member + writes ledger."""
    settings = loyalty_settings(tenant)
    now = datetime.now(timezone.utc)
    expiry = None
    if settings.get("point_expiry_days"):
        expiry = now + timedelta(days=int(settings["point_expiry_days"]))

    if coupon_code:
        await validate_and_redeem_coupon(
            db,
            tenant_id=tenant.id,
            code=coupon_code,
            member_id=member.id,
            order_total_cents=order_total_cents,
            order_id=order_id,
        )

    redeemed = 0
    if points_redeemed > 0:
        if not settings.get("redeem_enabled"):
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "point redemption disabled")
        cap = max_redeemable_points(member.points, order_total_cents, settings)
        if points_redeemed > cap:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"cannot redeem {points_redeemed} points (max {cap})",
            )
        member.points = max(0, member.points - points_redeemed)
        db.add(
            PointTransaction(
                tenant_id=tenant.id,
                member_id=member.id,
                delta=-points_redeemed,
                reason=f"redeem:{order_id}",
                order_id=order_id,
            )
        )
        redeemed = points_redeemed

    earned = 0
    if settings.get("earn_enabled"):
        rules = await load_active_earn_rules(db, tenant.id)
        level_mult = 1.0
        if member.level_id:
            lvl = await db.get(MemberLevel, member.level_id)
            if lvl and lvl.discount_rate < 1.0:
                level_mult = max(1.0, 2.0 - lvl.discount_rate)
        earned = calculate_earn_points(order_total_cents, rules, level_mult)
        if earned > 0:
            member.points = member.points + earned
            db.add(
                PointTransaction(
                    tenant_id=tenant.id,
                    member_id=member.id,
                    delta=earned,
                    reason=f"order:{order_id}",
                    order_id=order_id,
                    expires_at=expiry,
                )
            )

    member.total_spent_cents = member.total_spent_cents + order_total_cents
    member.last_visit_at = now

    if settings.get("auto_level"):
        await auto_upgrade_level(db, member, tenant.id)

    return earned, redeemed


async def reverse_order_loyalty(
    db: AsyncSession,
    *,
    tenant_id: str,
    member: Member,
    order_id: str,
    refund_cents: int,
    original_total_cents: int,
    points_redeemed_on_order: int,
) -> None:
    """Claw back earned points and restore redeemed points on refund."""
    if refund_cents <= 0:
        return
    rules = await load_active_earn_rules(db, tenant_id)
    earned_on_order = calculate_earn_points(original_total_cents, rules)
    ratio = min(1.0, refund_cents / max(1, original_total_cents))
    deduct = max(0, int(earned_on_order * ratio))
    if deduct > 0:
        member.points = max(0, member.points - deduct)
        db.add(
            PointTransaction(
                tenant_id=tenant_id,
                member_id=member.id,
                delta=-deduct,
                reason=f"refund:{order_id}",
                order_id=order_id,
            )
        )
    restore_redeemed = max(0, int(points_redeemed_on_order * ratio))
    if restore_redeemed > 0:
        member.points = member.points + restore_redeemed
        db.add(
            PointTransaction(
                tenant_id=tenant_id,
                member_id=member.id,
                delta=restore_redeemed,
                reason=f"refund_redeem_restore:{order_id}",
                order_id=order_id,
            )
        )
    member.total_spent_cents = max(0, member.total_spent_cents - refund_cents)
