from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    NonKitchenScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...core.usage import assert_within_monthly_orders, bump_usage_counter
from ...models import (
    GuestOrder,
    InventoryLevel,
    InventoryMovement,
    Member,
    Order,
    OrderLine,
    Payment,
    PosShift,
    Product,
    Tenant,
    TenantMemberLink,
)
from ...schemas.order import OrderCreate, OrderListItem, OrderListResponse, OrderRead
from ...services.option_validation import (
    OptionValidationError,
    load_product_option_context,
    validate_line_options,
)
from ...services.order_number import allocate_order_no
from ...services.order_query import (
    apply_order_filters,
    enrich_order_item,
    enrich_single_order,
    load_order_display_maps,
)
from ...services.loyalty_engine import apply_order_loyalty
from ...services.loyalty_eligibility import resolve_product_eligibility
from ...services.alliance_service import earn_alliance_points, tenant_alliance
from ...services.member_metrics import upsert_member_metrics_for_order
from ...services.webhooks import emit_webhook
from ...services.business_time import tenant_timezone
from ...services.consignment_books import (
    PRODUCT_KIND_CONSIGNMENT,
    calc_consignment_shares,
    get_consignment_settings,
)
from ...services.inventory_tracking import product_tracks_inventory

router = APIRouter(prefix="/orders", tags=["orders"])


def _select_order(stmt):
    return stmt.options(selectinload(Order.lines), selectinload(Order.payments))


@router.post("", response_model=OrderRead, status_code=201)
async def upload_order(
    payload: OrderCreate, db: DbSession, scope: NonKitchenScope
) -> OrderRead:
    """Idempotent: re-uploading the same order id is a no-op (returns the
    stored one). Tenant / store / cashier are derived from the JWT;
    matching fields in the payload are accepted only when they agree."""
    if not scope.store_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "session is not bound to a store; use POS login (with terminal) to upload orders",
        )

    existing = (
        await db.execute(_select_order(select(Order).where(Order.id == payload.id)))
    ).scalar_one_or_none()
    if existing:
        ensure_same_tenant(scope, existing)
        return existing

    await assert_within_monthly_orders(db, scope.tenant_id)

    if payload.store_id and payload.store_id != scope.store_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "store_id mismatch")
    if payload.terminal_id and scope.terminal_id and payload.terminal_id != scope.terminal_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "terminal_id mismatch")

    cashier_id = payload.cashier_id or scope.user_id
    if cashier_id != scope.user_id and not scope.is_store_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "cannot upload order for another cashier")

    # Attribute the order to the cashier's currently-open shift (for 交班結帳)
    # when the client didn't tag it explicitly.
    shift_id = payload.shift_id
    if shift_id is None:
        shift_stmt = select(PosShift.id).where(
            PosShift.tenant_id == scope.tenant_id,
            PosShift.user_id == cashier_id,
            PosShift.status == "open",
        )
        if scope.terminal_id:
            shift_stmt = shift_stmt.where(PosShift.terminal_id == scope.terminal_id)
        shift_id = (await db.execute(shift_stmt.order_by(PosShift.opened_at.desc()))).scalars().first()

    if payload.member_id:
        member = await db.get(Member, payload.member_id)
        if not member or member.tenant_id != scope.tenant_id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "member not in tenant")

    product_ids = list({ln.product_id for ln in payload.lines})
    if product_ids:
        owned = (
            await db.execute(
                select(Product.id).where(
                    Product.id.in_(product_ids),
                    Product.tenant_id == scope.tenant_id,
                )
            )
        ).scalars().all()
        if len(owned) != len(product_ids):
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST, "one or more products do not belong to this tenant"
            )

    products_by_id: dict[str, Product] = {}
    if product_ids:
        product_rows = (
            await db.execute(
                select(Product).where(
                    Product.id.in_(product_ids),
                    Product.tenant_id == scope.tenant_id,
                )
            )
        ).scalars().all()
        products_by_id = {p.id: p for p in product_rows}

    option_ctx = await load_product_option_context(db, scope.tenant_id, product_ids)
    validated_lines: list[dict] = []
    try:
        for ln in payload.lines:
            p = products_by_id[ln.product_id]
            options_json = validate_line_options(
                ln.product_id,
                p.price_cents,
                ln.unit_price_cents,
                ln.options_json,
                option_ctx,
            )
            line_data = ln.model_dump()
            line_data["options_json"] = options_json or None
            validated_lines.append(line_data)
    except OptionValidationError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e

    order_no = await allocate_order_no(
        db,
        tenant_id=scope.tenant_id,
        store_id=scope.store_id,
        client_created_at=payload.client_created_at,
    )

    order = Order(
        id=payload.id,
        order_no=order_no,
        tenant_id=scope.tenant_id,
        store_id=scope.store_id,
        terminal_id=scope.terminal_id or payload.terminal_id,
        cashier_id=cashier_id,
        member_id=payload.member_id,
        status=payload.status,
        subtotal_cents=payload.subtotal_cents,
        discount_cents=payload.discount_cents,
        tax_cents=payload.tax_cents,
        total_cents=payload.total_cents,
        invoice_carrier=payload.invoice_carrier,
        note=payload.note,
        source_guest_order_id=payload.source_guest_order_id,
        shift_id=shift_id,
        points_redeemed=payload.points_redeemed,
        coupon_code=payload.coupon_code,
        client_created_at=payload.client_created_at,
    )
    db.add(order)
    await db.flush()

    consignment_cfg = await get_consignment_settings(db, scope.tenant_id)
    book_share_pct = consignment_cfg["book_share_pct"]

    created_lines: list[OrderLine] = []
    for ln_data in validated_lines:
        p = products_by_id.get(ln_data["product_id"])
        kind = getattr(p, "product_kind", "regular") if p else "regular"
        ln_data = dict(ln_data)
        ln_data["product_kind"] = kind
        if kind == PRODUCT_KIND_CONSIGNMENT:
            book_share, restaurant_share = calc_consignment_shares(
                ln_data["line_total_cents"], book_share_pct
            )
            ln_data["consignment_book_share_cents"] = book_share
            ln_data["consignment_restaurant_share_cents"] = restaurant_share
        else:
            ln_data["consignment_book_share_cents"] = 0
            ln_data["consignment_restaurant_share_cents"] = 0
        line_obj = OrderLine(order_id=order.id, **ln_data)
        db.add(line_obj)
        created_lines.append(line_obj)
        if ln_data.get("sku") == "MARKETPLACE-DELIVERY-FEE":
            continue
        if not product_tracks_inventory(p):
            continue
        mvt = InventoryMovement(
            tenant_id=scope.tenant_id,
            store_id=order.store_id,
            product_id=ln_data["product_id"],
            qty_delta=-float(ln_data["qty"]),
            reason="sale",
            ref_type="order",
            ref_id=order.id,
            terminal_id=order.terminal_id,
            user_id=order.cashier_id,
            client_created_at=payload.client_created_at,
        )
        db.add(mvt)
        level = (
            await db.execute(
                select(InventoryLevel).where(
                    InventoryLevel.store_id == order.store_id,
                    InventoryLevel.product_id == ln_data["product_id"],
                )
            )
        ).scalar_one_or_none()
        if level is None:
            db.add(InventoryLevel(
                tenant_id=scope.tenant_id,
                store_id=order.store_id,
                product_id=ln_data["product_id"],
                on_hand=-float(ln_data["qty"]),
            ))
        else:
            level.on_hand = float(level.on_hand) - float(ln_data["qty"])

    for p in payload.payments:
        db.add(Payment(order_id=order.id, **p.model_dump()))

    if order.member_id:
        member = await db.get(Member, order.member_id)
        tenant = await db.get(Tenant, scope.tenant_id)
        if member and tenant:
            eligibility = await resolve_product_eligibility(
                db, scope.tenant_id, [ln.product_id for ln in created_lines]
            )
            earned, _ = await apply_order_loyalty(
                db,
                tenant=tenant,
                member=member,
                order_id=order.id,
                order_total_cents=order.total_cents,
                points_redeemed=payload.points_redeemed,
                coupon_code=payload.coupon_code,
                lines=created_lines,
                eligibility=eligibility,
            )
            await upsert_member_metrics_for_order(
                db,
                tenant_id=scope.tenant_id,
                member_id=member.id,
                revenue_cents=order.total_cents,
                order_at=payload.client_created_at,
            )
            if earned > 0:
                await emit_webhook(
                    db,
                    tenant_id=scope.tenant_id,
                    event="points.earned",
                    payload={
                        "member_id": member.id,
                        "order_id": order.id,
                        "delta": earned,
                        "balance": member.points,
                    },
                )
            at = await tenant_alliance(db, scope.tenant_id)
            if at and earned > 0:
                link = (
                    await db.execute(
                        select(TenantMemberLink).where(
                            TenantMemberLink.tenant_id == scope.tenant_id,
                            TenantMemberLink.member_id == member.id,
                        )
                    )
                ).scalar_one_or_none()
                if link:
                    await earn_alliance_points(
                        db,
                        alliance_id=at.alliance_id,
                        alliance_member_id=link.alliance_member_id,
                        tenant_id=scope.tenant_id,
                        order_id=order.id,
                        points=earned,
                    )

    if order.source_guest_order_id:
        g = await db.get(GuestOrder, order.source_guest_order_id)
        if g and g.tenant_id == scope.tenant_id and g.status not in ("merged", "cancelled"):
            g.status = "merged"
            g.merged_at = datetime.now(timezone.utc)
            g.merged_order_id = order.id

    await bump_usage_counter(db, tenant_id=scope.tenant_id, metric="orders", delta=1)
    await audit(db, scope, action="order_upload", resource_type="order",
                resource_id=order.id, extra={"total_cents": order.total_cents}, flush=False)
    await db.commit()
    fresh = (
        await db.execute(_select_order(select(Order).where(Order.id == order.id)))
    ).scalar_one()
    return fresh


@router.get("", response_model=OrderListResponse)
async def list_orders(
    db: DbSession,
    scope: NonKitchenScope,
    member_id: str | None = None,
    terminal_id: str | None = None,
    store_id: str | None = None,
    status: str | None = None,
    payment_method: str | None = None,
    since: datetime | None = None,
    until: datetime | None = None,
    q: str | None = None,
    limit: int = Query(20, le=200),
    offset: int = 0,
):
    tenant = await db.get(Tenant, scope.tenant_id) if scope.tenant_id else None
    tz = tenant_timezone(tenant.settings if tenant else None)

    base = apply_tenant(_select_order(select(Order)), Order, scope)
    filtered = apply_order_filters(
        base,
        scope=scope,
        since=since,
        until=until,
        status=status,
        store_id=store_id,
        member_id=member_id,
        terminal_id=terminal_id,
        payment_method=payment_method,
        q=q,
        tz=tz,
    )

    count_base = apply_tenant(select(Order), Order, scope)
    count_filtered = apply_order_filters(
        count_base,
        scope=scope,
        since=since,
        until=until,
        status=status,
        store_id=store_id,
        member_id=member_id,
        terminal_id=terminal_id,
        payment_method=payment_method,
        q=q,
        tz=tz,
    )
    total = int((await db.execute(select(func.count()).select_from(count_filtered.subquery()))).scalar_one())

    stmt = filtered.order_by(func.coalesce(Order.client_created_at, Order.created_at).desc()).limit(limit).offset(offset)
    rows = (await db.execute(stmt)).scalars().unique().all()

    store_map, cashier_map, member_map = await load_order_display_maps(db, rows)
    items = [
        enrich_order_item(
            o,
            store_name=store_map.get(o.store_id),
            cashier_name=cashier_map.get(o.cashier_id),
            member_name=member_map.get(o.member_id) if o.member_id else None,
        )
        for o in rows
    ]
    return OrderListResponse(items=items, total=total, offset=offset, limit=limit)


@router.get("/{oid}", response_model=OrderListItem)
async def get_order(oid: str, db: DbSession, scope: NonKitchenScope):
    o = (
        await db.execute(_select_order(select(Order).where(
            (Order.id == oid) | (Order.order_no == oid)
        )))
    ).scalar_one_or_none()
    if not o:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, o)
    if scope.store_id and not scope.is_tenant_admin and o.store_id != scope.store_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    item = await enrich_single_order(db, o)
    return item
