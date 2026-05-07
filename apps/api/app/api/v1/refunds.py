
from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.deps import CurrentUserDep, DbSession
from ...models import (
    InventoryLevel,
    InventoryMovement,
    Member,
    Order,
    OrderLine,
    PointTransaction,
    Refund,
    RefundLine,
)
from ...schemas.order import RefundCreate, RefundRead

router = APIRouter(prefix="/orders", tags=["refunds"])


@router.post("/{oid}/refund", response_model=RefundRead, status_code=201)
async def refund_order(oid: str, payload: RefundCreate, db: DbSession, user: CurrentUserDep) -> Refund:
    order = (
        await db.execute(
            select(Order).where(Order.id == oid).options(selectinload(Order.lines))
        )
    ).scalar_one_or_none()
    if not order:
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
                raise HTTPException(status.HTTP_400_BAD_REQUEST, f"order line {r.order_line_id} not found")
            line_inputs.append((ln.id, r.qty, r.amount_cents))

    refund = Refund(
        id=payload.id,
        order_id=order.id,
        user_id=payload.user_id,
        method=payload.method,
        total_amount_cents=0,
        reason=payload.reason,
    )
    db.add(refund)
    await db.flush()

    for line_id, qty, amount in line_inputs:
        ln = line_map[line_id]
        db.add(RefundLine(refund_id=refund.id, order_line_id=line_id, qty=qty, amount_cents=amount))
        # Reverse inventory movement
        mvt = InventoryMovement(
            store_id=order.store_id,
            product_id=ln.product_id,
            qty_delta=float(qty),
            reason="refund",
            ref_type="refund",
            ref_id=refund.id,
            terminal_id=order.terminal_id,
            user_id=payload.user_id,
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
            db.add(InventoryLevel(store_id=order.store_id, product_id=ln.product_id, on_hand=float(qty)))
        else:
            level.on_hand = float(level.on_hand) + float(qty)
        total_cents += amount

    refund.total_amount_cents = total_cents
    order.refunded_cents = order.refunded_cents + total_cents
    order.status = "refunded" if order.refunded_cents >= order.total_cents else "partiallyRefunded"

    if order.member_id:
        member = await db.get(Member, order.member_id)
        if member:
            deduct = max(0, total_cents // 100)
            if deduct > 0:
                member.points = max(0, member.points - deduct)
                db.add(
                    PointTransaction(
                        member_id=member.id,
                        delta=-deduct,
                        reason=f"refund:{refund.id}",
                        order_id=order.id,
                    )
                )

    await db.commit()
    await db.refresh(refund)
    return refund
