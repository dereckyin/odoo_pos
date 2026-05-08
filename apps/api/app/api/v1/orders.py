from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.deps import CurrentUserDep, DbSession
from ...models import (
    GuestOrder,
    InventoryLevel,
    InventoryMovement,
    Member,
    Order,
    OrderLine,
    Payment,
    PointTransaction,
)
from ...schemas.order import OrderCreate, OrderRead

router = APIRouter(prefix="/orders", tags=["orders"])


def _select_order(stmt):
    return stmt.options(selectinload(Order.lines), selectinload(Order.payments))


@router.post("", response_model=OrderRead, status_code=201)
async def upload_order(payload: OrderCreate, db: DbSession, user: CurrentUserDep) -> OrderRead:
    """Idempotent: re-uploading the same order id is a no-op (returns the stored one)."""
    existing = (
        await db.execute(_select_order(select(Order).where(Order.id == payload.id)))
    ).scalar_one_or_none()
    if existing:
        return existing  # idempotent

    order = Order(
        id=payload.id,
        store_id=payload.store_id,
        terminal_id=payload.terminal_id,
        cashier_id=payload.cashier_id,
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
        # Decrement inventory + movement
        mvt = InventoryMovement(
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
            db.add(InventoryLevel(store_id=order.store_id, product_id=ln.product_id, on_hand=-float(ln.qty)))
        else:
            level.on_hand = float(level.on_hand) - float(ln.qty)

    for p in payload.payments:
        db.add(Payment(order_id=order.id, **p.model_dump()))

    if order.member_id:
        member = await db.get(Member, order.member_id)
        if member:
            earned = max(0, order.total_cents // 100)  # 1 point per dollar (TWD)
            if earned > 0:
                member.points = member.points + earned
                db.add(
                    PointTransaction(
                        member_id=member.id,
                        delta=earned,
                        reason=f"order:{order.id}",
                        order_id=order.id,
                    )
                )
            member.total_spent_cents = member.total_spent_cents + order.total_cents
            member.last_visit_at = datetime.now(timezone.utc)

    # If this paid order originates from a QR-scanned guest order (table-side
    # ordering), automatically flip the guest order to ``merged``. This is
    # what closes the loop between the customer Vue submission and the
    # cashier's payment at the counter — see plan: "僅櫃台付".
    if order.source_guest_order_id:
        g = await db.get(GuestOrder, order.source_guest_order_id)
        if g and g.status not in ("merged", "cancelled"):
            g.status = "merged"
            g.merged_at = datetime.now(timezone.utc)
            g.merged_order_id = order.id

    await db.commit()
    fresh = (
        await db.execute(_select_order(select(Order).where(Order.id == order.id)))
    ).scalar_one()
    return fresh


@router.get("", response_model=list[OrderRead])
async def list_orders(
    db: DbSession,
    user: CurrentUserDep,
    member_id: str | None = None,
    terminal_id: str | None = None,
    limit: int = Query(20, le=200),
    offset: int = 0,
):
    stmt = _select_order(select(Order)).order_by(Order.created_at.desc()).limit(limit).offset(offset)
    if member_id:
        stmt = stmt.where(Order.member_id == member_id)
    if terminal_id:
        stmt = stmt.where(Order.terminal_id == terminal_id)
    rows = (await db.execute(stmt)).scalars().unique().all()
    return rows


@router.get("/{oid}", response_model=OrderRead)
async def get_order(oid: str, db: DbSession, user: CurrentUserDep):
    o = (await db.execute(_select_order(select(Order).where(Order.id == oid)))).scalar_one_or_none()
    if not o:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return o
