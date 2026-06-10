"""Shared marketplace order creation used by single + multi-store checkout."""
from __future__ import annotations

from dataclasses import dataclass
from uuid import uuid4

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import GuestOrder, GuestOrderLine, MarketplaceListing, Member, Product, Store
from ..schemas.guest_order import GuestOrderLineCreate
from .loyalty_engine import (
    coupon_discount_cents,
    loyalty_settings,
    max_redeemable_points,
    points_discount_cents,
    preview_coupon,
)
from .marketplace import get_or_create_web_dinein_table, is_store_open
from .option_validation import (
    OptionValidationError,
    load_product_option_context,
    validate_line_options,
)
from .public_menu import product_orderable_via_public_menu

FULFILLMENT_TYPES = ("pickup", "delivery", "dine_in")
PAYMENT_METHODS = ("counter", "online")


@dataclass
class MarketplaceOrderInput:
    fulfillment_type: str
    payment_method: str
    customer_name: str
    customer_phone: str
    customer_note: str | None = None
    party_size: int | None = None
    member_id: str | None = None
    delivery_address: str | None = None
    delivery_lat: float | None = None
    delivery_lng: float | None = None
    delivery_note: str | None = None
    table_label: str | None = None
    points_redeemed: int = 0
    coupon_code: str | None = None
    available_points: int | None = None  # cross-store balance for redeem cap
    lines: list[GuestOrderLineCreate] | None = None


async def build_marketplace_order(
    db: AsyncSession,
    *,
    listing: MarketplaceListing,
    store: Store,
    data: MarketplaceOrderInput,
    order_group_id: str | None = None,
) -> tuple[GuestOrder, str, int]:
    """Validate inputs and persist a marketplace ``GuestOrder`` (+ lines).

    Returns ``(guest_order, access_token, estimated_subtotal_cents)``. The
    caller is responsible for committing the transaction.
    """
    if not data.lines:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "empty cart")
    if data.fulfillment_type not in FULFILLMENT_TYPES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid fulfillment_type")
    if data.payment_method not in PAYMENT_METHODS:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid payment_method")
    if not is_store_open(listing.business_hours):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"{listing.display_name} 目前休息中")

    if data.fulfillment_type == "pickup" and not listing.supports_pickup:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "pickup not supported")
    if data.fulfillment_type == "delivery" and not listing.supports_delivery:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "delivery not supported")
    if data.fulfillment_type == "dine_in" and not listing.supports_dine_in:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "dine_in not supported")
    if data.payment_method == "counter" and not listing.payment_counter:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "counter payment not supported")
    if data.payment_method == "online" and not listing.payment_online:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "online payment not supported")
    if data.fulfillment_type == "delivery" and not data.delivery_address:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "delivery_address required")

    table_id = None
    if data.fulfillment_type == "dine_in":
        table = await get_or_create_web_dinein_table(db, store)
        table_id = table.id
        if data.table_label:
            table.label = data.table_label[:32]
            await db.flush()

    product_ids = list({ln.product_id for ln in data.lines})
    from sqlalchemy import select

    products = (
        await db.execute(
            select(Product).where(
                Product.id.in_(product_ids),
                Product.tenant_id == store.tenant_id,
                Product.deleted_at.is_(None),
                Product.is_active.is_(True),
            )
        )
    ).scalars().all()
    by_id = {p.id: p for p in products}
    option_ctx = await load_product_option_context(db, store.tenant_id, product_ids)

    delivery_fee = listing.delivery_fee_cents if data.fulfillment_type == "delivery" else 0
    items_total = 0
    line_models: list[GuestOrderLine] = []
    for ln in data.lines:
        p = by_id.get(ln.product_id)
        if not p:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"product not available: {ln.product_id}")
        if not await product_orderable_via_public_menu(db, p):
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"product not available: {ln.product_id}")
        try:
            options_json = validate_line_options(
                p.id,
                p.price_cents,
                p.price_cents + sum(o.price_delta_cents for o in (ln.options or [])),
                ln.options,
                option_ctx,
            )
        except OptionValidationError as e:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
        unit_price = p.price_cents + sum(o["price_delta_cents"] for o in options_json)
        line_total = round(unit_price * ln.qty)
        items_total += line_total
        line_models.append(
            GuestOrderLine(
                product_id=p.id,
                product_name=p.name,
                sku=p.sku,
                qty=ln.qty,
                unit_price_cents=unit_price,
                line_total_cents=line_total,
                note=ln.note,
                options_json=options_json or None,
            )
        )

    if items_total < listing.min_order_cents:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"{listing.display_name} 最低消費為 ${listing.min_order_cents}",
        )

    # Validate the member belongs to this tenant (already resolved by caller).
    member: Member | None = None
    if data.member_id:
        member = await db.get(Member, data.member_id)
        if not member or member.tenant_id != store.tenant_id or member.deleted_at:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid member")

    # Loyalty discounts (online only; counter orders settle loyalty at POS).
    discount = 0
    points_redeemed = 0
    coupon_code = None
    tenant = store  # placeholder; need tenant for settings
    if data.payment_method == "online" and member is not None:
        from ..models import Tenant

        tenant = await db.get(Tenant, store.tenant_id)
        settings = loyalty_settings(tenant)
        pre_discount_total = items_total + delivery_fee
        if data.coupon_code:
            c = await preview_coupon(
                db,
                tenant_id=store.tenant_id,
                code=data.coupon_code,
                member_id=member.id,
                order_total_cents=pre_discount_total,
            )
            if c is not None:
                discount += coupon_discount_cents(c, items_total)
                coupon_code = data.coupon_code
        if data.points_redeemed and data.points_redeemed > 0:
            remaining = max(0, pre_discount_total - discount)
            available = (
                data.available_points if data.available_points is not None else member.points
            )
            cap = max_redeemable_points(available, remaining, settings)
            points_redeemed = min(data.points_redeemed, cap)
            discount += points_discount_cents(points_redeemed, settings)

    estimated = max(0, items_total + delivery_fee - discount)

    access_token = str(uuid4())
    payment_status = "pending" if data.payment_method == "online" else None
    delivery_status = "pending" if data.fulfillment_type == "delivery" else None

    g = GuestOrder(
        tenant_id=store.tenant_id,
        store_id=store.id,
        table_id=table_id,
        channel="marketplace",
        fulfillment_type=data.fulfillment_type,
        status="submitted",
        customer_name=data.customer_name,
        customer_phone=data.customer_phone,
        customer_note=data.customer_note,
        party_size=data.party_size,
        member_id=data.member_id,
        order_group_id=order_group_id,
        delivery_address=data.delivery_address,
        delivery_lat=data.delivery_lat,
        delivery_lng=data.delivery_lng,
        delivery_note=data.delivery_note,
        delivery_status=delivery_status,
        payment_method=data.payment_method,
        payment_status=payment_status,
        estimated_subtotal_cents=estimated,
        points_redeemed=points_redeemed,
        coupon_code=coupon_code,
        discount_cents=discount,
        extras={"access_token": access_token, "store_slug": listing.slug},
    )
    db.add(g)
    await db.flush()
    for lm in line_models:
        lm.order_id = g.id
        db.add(lm)
    return g, access_token, estimated


async def settle_marketplace_online_loyalty(db: AsyncSession, g: GuestOrder) -> None:
    """Apply redemption + coupon + earning to the unified member when a
    marketplace online order is confirmed paid. Idempotent via an extras flag.
    """
    from ..models import (
        AllianceMember,
        AlliancePointLedger,
        MemberLevel,
        Tenant,
        TenantMemberLink,
    )
    from .loyalty_engine import (
        auto_upgrade_level,
        calculate_earn_points,
        load_active_earn_rules,
        loyalty_settings,
        validate_and_redeem_coupon,
    )
    from .marketplace_member import get_or_create_marketplace_alliance

    if not g.member_id:
        return
    if g.extras and g.extras.get("loyalty_settled"):
        return

    member = await db.get(Member, g.member_id)
    tenant = await db.get(Tenant, g.tenant_id)
    if not member or not tenant:
        return
    settings = loyalty_settings(tenant)
    charged = g.estimated_subtotal_cents

    net = await get_or_create_marketplace_alliance(db)
    from sqlalchemy import select as _select

    link = (
        await db.execute(
            _select(TenantMemberLink).where(
                TenantMemberLink.alliance_id == net.id,
                TenantMemberLink.member_id == member.id,
            )
        )
    ).scalar_one_or_none()
    am: AllianceMember | None = (
        await db.get(AllianceMember, link.alliance_member_id) if link else None
    )

    # Coupon consume (tenant-scoped).
    if g.coupon_code:
        try:
            await validate_and_redeem_coupon(
                db,
                tenant_id=tenant.id,
                code=g.coupon_code,
                member_id=member.id,
                order_total_cents=charged + (g.discount_cents or 0),
                order_id=g.id,
            )
        except Exception:  # noqa: BLE001 - coupon already gone shouldn't block payment
            pass

    # Redeem cross-store points.
    if am and g.points_redeemed and g.points_redeemed > 0:
        am.points = max(0, am.points - g.points_redeemed)
        db.add(
            AlliancePointLedger(
                alliance_id=net.id,
                alliance_member_id=am.id,
                tenant_id=tenant.id,
                delta=-g.points_redeemed,
                reason=f"redeem:{g.id}",
                order_id=g.id,
            )
        )

    # Earn on the charged amount.
    if settings.get("earn_enabled"):
        rules = await load_active_earn_rules(db, tenant.id)
        level_mult = 1.0
        if member.level_id:
            lvl = await db.get(MemberLevel, member.level_id)
            if lvl and lvl.discount_rate < 1.0:
                level_mult = max(1.0, 2.0 - lvl.discount_rate)
        earned = calculate_earn_points(charged, rules, level_mult)
        if earned > 0 and am:
            am.points += earned
            db.add(
                AlliancePointLedger(
                    alliance_id=net.id,
                    alliance_member_id=am.id,
                    tenant_id=tenant.id,
                    delta=earned,
                    reason=f"order:{g.id}",
                    order_id=g.id,
                )
            )

    member.total_spent_cents = (member.total_spent_cents or 0) + charged
    if settings.get("auto_level"):
        await auto_upgrade_level(db, member, tenant.id)

    if g.extras is None:
        g.extras = {}
    g.extras = {**g.extras, "loyalty_settled": True}
