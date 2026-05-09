from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    TenantScope,
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
    PointTransaction,
    Product,
)
from ...schemas.order import OrderCreate, OrderRead

router = APIRouter(prefix="/orders", tags=["orders"])


def _select_order(stmt):
    return stmt.options(selectinload(Order.lines), selectinload(Order.payments))


@router.post("", response_model=OrderRead, status_code=201)
async def upload_order(
    payload: OrderCreate, db: DbSession, scope: TenantScope
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

    # Plan-limit gate (only on NEW orders so retries / idempotent re-uploads
    # never bill twice).
    await assert_within_monthly_orders(db, scope.tenant_id)

    if payload.store_id and payload.store_id != scope.store_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "store_id mismatch")
    if payload.terminal_id and scope.terminal_id and payload.terminal_id != scope.terminal_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "terminal_id mismatch")

    cashier_id = payload.cashier_id or scope.user_id
    if cashier_id != scope.user_id and not scope.is_store_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "cannot upload order for another cashier")

    if payload.member_id:
        member = await db.get(Member, payload.member_id)
        if not member or member.tenant_id != scope.tenant_id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "member not in tenant")

    # All product ids must belong to this tenant.
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

    order = Order(
        id=payload.id,
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
        client_created_at=payload.client_created_at,
    )
    db.add(order)
    await db.flush()

    for ln in payload.lines:
        db.add(OrderLine(order_id=order.id, **ln.model_dump()))
        mvt = InventoryMovement(
            tenant_id=scope.tenant_id,
            store_id=order.store_id,
            product_id=ln.product_id,
            qty_delta=-float(ln.qty),
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
                    InventoryLevel.product_id == ln.product_id,
                )
            )
        ).scalar_one_or_none()
        if level is None:
            db.add(InventoryLevel(
                tenant_id=scope.tenant_id,
                store_id=order.store_id,
                product_id=ln.product_id,
                on_hand=-float(ln.qty),
            ))
        else:
            level.on_hand = float(level.on_hand) - float(ln.qty)

    for p in payload.payments:
        db.add(Payment(order_id=order.id, **p.model_dump()))

    if order.member_id:
        member = await db.get(Member, order.member_id)
        if member:
            earned = max(0, order.total_cents // 100)
            if earned > 0:
                member.points = member.points + earned
                db.add(
                    PointTransaction(
                        tenant_id=scope.tenant_id,
                        member_id=member.id,
                        delta=earned,
                        reason=f"order:{order.id}",
                        order_id=order.id,
                    )
                )
            member.total_spent_cents = member.total_spent_cents + order.total_cents
            member.last_visit_at = datetime.now(timezone.utc)

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


@router.get("", response_model=list[OrderRead])
async def list_orders(
    db: DbSession,
    scope: TenantScope,
    member_id: str | None = None,
    terminal_id: str | None = None,
    store_id: str | None = None,
    limit: int = Query(20, le=200),
    offset: int = 0,
):
    stmt = apply_tenant(_select_order(select(Order)), Order, scope)
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    if member_id:
        stmt = stmt.where(Order.member_id == member_id)
    if terminal_id:
        stmt = stmt.where(Order.terminal_id == terminal_id)
    stmt = stmt.order_by(Order.created_at.desc()).limit(limit).offset(offset)
    rows = (await db.execute(stmt)).scalars().unique().all()
    return rows


@router.get("/{oid}", response_model=OrderRead)
async def get_order(oid: str, db: DbSession, scope: TenantScope):
    o = (
        await db.execute(_select_order(select(Order).where(Order.id == oid)))
    ).scalar_one_or_none()
    if not o:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, o)
    if scope.store_id and not scope.is_tenant_admin and o.store_id != scope.store_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return o
