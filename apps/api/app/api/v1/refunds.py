from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import DbSession, TenantScope, ensure_same_tenant
from ...models import (
    InventoryLevel,
    InventoryMovement,
    Member,
    Order,
    OrderLine,
    Product,
    Refund,
    RefundLine,
    Tenant,
)
from ...schemas.order import RefundCreate, RefundRead
from ...services.inventory_tracking import product_tracks_inventory
from ...services.loyalty_engine import reverse_order_loyalty

router = APIRouter(prefix="/orders", tags=["refunds"])


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def _tenant_requires_refund_approval(db, tenant_id: str | None) -> bool:
    if not tenant_id:
        return False
    tenant = await db.get(Tenant, tenant_id)
    settings = (tenant.settings or {}) if tenant else {}
    return bool(settings.get("require_refund_approval", False))


async def apply_refund_effects(db, refund: Refund, order: Order) -> None:
    """Materialise an approved refund: restock inventory, bump the order's
    refunded total/status, and reverse loyalty. Idempotency is the caller's
    responsibility (only ever called once per refund, on approval)."""
    lines = (
        await db.execute(
            select(RefundLine).where(RefundLine.refund_id == refund.id)
        )
    ).scalars().all()
    order_lines = {ln.id: ln for ln in order.lines}
    product_ids = {ln.product_id for ln in order.lines}
    products_by_id = {
        p.id: p
        for p in (await db.execute(select(Product).where(Product.id.in_(product_ids)))).scalars()
    }

    for rl in lines:
        ol = order_lines.get(rl.order_line_id)
        if not ol:
            continue
        p = products_by_id.get(ol.product_id)
        if product_tracks_inventory(p):
            db.add(InventoryMovement(
                tenant_id=order.tenant_id,
                store_id=order.store_id,
                product_id=ol.product_id,
                qty_delta=float(rl.qty),
                reason="refund",
                ref_type="refund",
                ref_id=refund.id,
                terminal_id=order.terminal_id,
                user_id=refund.user_id,
            ))
            level = (
                await db.execute(
                    select(InventoryLevel).where(
                        InventoryLevel.store_id == order.store_id,
                        InventoryLevel.product_id == ol.product_id,
                    )
                )
            ).scalar_one_or_none()
            if level is None:
                db.add(InventoryLevel(
                    tenant_id=order.tenant_id,
                    store_id=order.store_id,
                    product_id=ol.product_id,
                    on_hand=float(rl.qty),
                ))
            else:
                level.on_hand = float(level.on_hand) + float(rl.qty)

    total_cents = refund.total_amount_cents
    order.refunded_cents = order.refunded_cents + total_cents
    order.status = "refunded" if order.refunded_cents >= order.total_cents else "partiallyRefunded"

    if order.member_id:
        member = await db.get(Member, order.member_id)
        if member:
            await reverse_order_loyalty(
                db,
                tenant_id=order.tenant_id,
                member=member,
                order_id=order.id,
                refund_cents=total_cents,
                original_total_cents=order.total_cents,
                points_redeemed_on_order=order.points_redeemed or 0,
            )


@router.post("/{oid}/refund", response_model=RefundRead, status_code=201)
async def refund_order(
    oid: str, payload: RefundCreate, db: DbSession, scope: TenantScope
) -> Refund:
    order = (
        await db.execute(
            select(Order).where(Order.id == oid).options(selectinload(Order.lines))
        )
    ).scalar_one_or_none()
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "order not found")
    ensure_same_tenant(scope, order)
    if scope.store_id and not scope.is_tenant_admin and order.store_id != scope.store_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "order not found")
    if order.status not in ("paid", "partiallyRefunded"):
        raise HTTPException(status.HTTP_409_CONFLICT, "order not refundable")

    existing = await db.get(Refund, payload.id)
    if existing:
        return existing

    full = not payload.lines
    total_cents = 0
    line_map = {ln.id: ln for ln in order.lines}

    if full:
        line_inputs = [(ln.id, ln.qty, ln.line_total_cents) for ln in order.lines]
    else:
        line_inputs = []
        for r in payload.lines:
            ln: OrderLine | None = line_map.get(r.order_line_id)
            if not ln:
                raise HTTPException(
                    status.HTTP_400_BAD_REQUEST,
                    f"order line {r.order_line_id} not found",
                )
            line_inputs.append((ln.id, r.qty, r.amount_cents))

    requires_approval = await _tenant_requires_refund_approval(db, order.tenant_id)
    # Store-admins (店長以上) may always approve on the spot; cashiers route to
    # review only when the tenant turned the approval requirement on.
    needs_review = requires_approval and not scope.is_store_admin

    refund = Refund(
        id=payload.id,
        order_id=order.id,
        user_id=payload.user_id or scope.user_id,
        method=payload.method,
        total_amount_cents=0,
        reason=payload.reason,
        status="pending" if needs_review else "approved",
    )
    db.add(refund)
    await db.flush()

    for line_id, qty, amount in line_inputs:
        db.add(
            RefundLine(refund_id=refund.id, order_line_id=line_id, qty=qty, amount_cents=amount)
        )
        total_cents += amount
    refund.total_amount_cents = total_cents

    if not needs_review:
        refund.approver_id = scope.user_id
        refund.decided_at = _now()
        await apply_refund_effects(db, refund, order)

    await audit(db, scope, action="order_refund", resource_type="order",
                resource_id=order.id,
                extra={"total_cents": total_cents, "status": refund.status}, flush=False)
    await db.commit()
    await db.refresh(refund)
    return refund
