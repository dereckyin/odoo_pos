"""Scheduled loyalty maintenance: point expiry + birthday rewards.

Designed to be invoked from a cron / scheduled task hitting the platform
maintenance endpoint (or directly in a worker).
"""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import (
    AllianceMember,
    AllianceNetwork,
    AlliancePointLedger,
    Member,
    PointTransaction,
    Tenant,
    TenantMemberLink,
)
from .loyalty_engine import loyalty_settings
from .marketplace_member import MARKETPLACE_ALLIANCE_CODE

BIRTHDAY_REWARD_POINTS = 100


async def _marketplace_alliance_id(db: AsyncSession) -> str | None:
    """Return the platform marketplace alliance id, or ``None`` if it has never
    been provisioned (i.e. no tenant has enabled marketplace yet).

    Unlike ``get_or_create_marketplace_alliance`` this never creates the network,
    so maintenance jobs are a true no-op on platforms without marketplace.
    """
    net = (
        await db.execute(
            select(AllianceNetwork).where(
                AllianceNetwork.code == MARKETPLACE_ALLIANCE_CODE,
                AllianceNetwork.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    return net.id if net else None


async def run_point_expiry(db: AsyncSession) -> int:
    """Deduct earned points whose ``expires_at`` has passed, scoped to members
    who belong to the platform marketplace alliance.

    Non-marketplace tenants (e.g. plain table-side ordering) are never touched:
    their tenant-local members are excluded entirely.

    Idempotent: an expired earn entry is only clawed back once, tracked via a
    matching ``expire:<txn_id>`` reversal transaction.
    """
    market_alliance_id = await _marketplace_alliance_id(db)
    if not market_alliance_id:
        return 0
    market_member_ids = set(
        (
            await db.execute(
                select(TenantMemberLink.member_id).where(
                    TenantMemberLink.alliance_id == market_alliance_id,
                )
            )
        ).scalars().all()
    )
    if not market_member_ids:
        return 0

    now = datetime.now(timezone.utc)
    earned = (
        await db.execute(
            select(PointTransaction).where(
                PointTransaction.delta > 0,
                PointTransaction.expires_at.is_not(None),
                PointTransaction.expires_at < now,
                PointTransaction.member_id.in_(market_member_ids),
            )
        )
    ).scalars().all()
    if not earned:
        return 0
    already = set(
        (
            await db.execute(
                select(PointTransaction.reason).where(
                    PointTransaction.reason.like("expire:%")
                )
            )
        ).scalars().all()
    )
    expired_count = 0
    for txn in earned:
        marker = f"expire:{txn.id}"
        if marker in already:
            continue
        member = await db.get(Member, txn.member_id)
        if not member:
            continue
        deduct = min(member.points, txn.delta)
        if deduct > 0:
            member.points = max(0, member.points - deduct)
        db.add(
            PointTransaction(
                tenant_id=txn.tenant_id,
                member_id=txn.member_id,
                delta=-deduct,
                reason=marker,
            )
        )
        expired_count += 1
    await db.commit()
    return expired_count


async def run_birthday_rewards(
    db: AsyncSession, *, points: int = BIRTHDAY_REWARD_POINTS
) -> int:
    """Grant a birthday bonus to marketplace members whose birthday is today.

    Scoped to the platform marketplace alliance so Enterprise/other alliances are
    never affected; a no-op when marketplace has not been provisioned.
    """
    market_alliance_id = await _marketplace_alliance_id(db)
    if not market_alliance_id:
        return 0
    now = datetime.now(timezone.utc)
    today_md = now.strftime("%m-%d")
    year = now.year
    members = (
        await db.execute(
            select(AllianceMember).where(
                AllianceMember.alliance_id == market_alliance_id,
                AllianceMember.deleted_at.is_(None),
                AllianceMember.birthday.is_not(None),
            )
        )
    ).scalars().all()
    rewarded = 0
    for am in members:
        if not am.birthday or len(am.birthday) < 5:
            continue
        if am.birthday[5:10] != today_md:
            continue
        if am.birthday_reward_year == year:
            continue
        am.points += points
        am.birthday_reward_year = year
        db.add(
            AlliancePointLedger(
                alliance_id=am.alliance_id,
                alliance_member_id=am.id,
                delta=points,
                reason="birthday_bonus",
            )
        )
        rewarded += 1
    await db.commit()
    return rewarded


async def run_tenant_birthday_rewards(db: AsyncSession) -> int:
    """Grant in-store (tenant-local) members a birthday bonus today.

    Each tenant's bonus amount comes from its loyalty settings
    (``birthday_bonus_points``); tenants with 0 are skipped. Idempotent per
    member per year via a ``birthday:<year>`` ledger marker.
    """
    now = datetime.now(timezone.utc)
    year = now.year
    today_month = now.month
    today_day = now.day

    members = (
        await db.execute(
            select(Member).where(
                Member.deleted_at.is_(None),
                Member.birthday.is_not(None),
            )
        )
    ).scalars().all()
    if not members:
        return 0

    bonus_by_tenant: dict[str, int] = {}

    async def _bonus_for(tenant_id: str) -> int:
        if tenant_id not in bonus_by_tenant:
            tenant = await db.get(Tenant, tenant_id)
            settings = loyalty_settings(tenant)
            bonus_by_tenant[tenant_id] = int(settings.get("birthday_bonus_points") or 0)
        return bonus_by_tenant[tenant_id]

    rewarded = 0
    for m in members:
        if not m.birthday:
            continue
        if m.birthday.month != today_month or m.birthday.day != today_day:
            continue
        points = await _bonus_for(m.tenant_id)
        if points <= 0:
            continue
        marker = f"birthday:{year}"
        already = (
            await db.execute(
                select(PointTransaction.id).where(
                    PointTransaction.member_id == m.id,
                    PointTransaction.reason == marker,
                ).limit(1)
            )
        ).first()
        if already:
            continue
        m.points = (m.points or 0) + points
        db.add(
            PointTransaction(
                tenant_id=m.tenant_id,
                member_id=m.id,
                delta=points,
                reason=marker,
            )
        )
        rewarded += 1
    await db.commit()
    return rewarded
