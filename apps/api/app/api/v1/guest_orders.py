"""Staff endpoints for the guest-order (table-side ordering) workflow.

State machine:

    submitted -> accepted -> ready -> merged
                                  \-> cancelled

Inventory is intentionally NOT touched by any of these endpoints. When the
cashier completes payment at the counter, the existing ``POST /orders``
upload path stamps ``source_guest_order_id`` and we flip the guest order
to ``merged``.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.deps import CurrentUserDep, DbSession
from ...models import GuestOrder, Order
from ...schemas.guest_order import (
    CancelRequest,
    GuestOrderLineRead,
    GuestOrderRead,
    MergeRequest,
)

router = APIRouter(prefix="/guest-orders", tags=["guest-orders"])


def _to_read(g: GuestOrder) -> GuestOrderRead:
    return GuestOrderRead(
        id=g.id,
        store_id=g.store_id,
        table_id=g.table_id,
        table_label=g.table.label if g.table else None,
        status=g.status,
        customer_note=g.customer_note,
        party_size=g.party_size,
        estimated_subtotal_cents=g.estimated_subtotal_cents,
        accepted_at=g.accepted_at,
        ready_at=g.ready_at,
        merged_at=g.merged_at,
        cancelled_at=g.cancelled_at,
        accepted_by_user_id=g.accepted_by_user_id,
        merged_order_id=g.merged_order_id,
        cancel_reason=g.cancel_reason,
        created_at=g.created_at,
        updated_at=g.updated_at,
        lines=[GuestOrderLineRead.model_validate(ln) for ln in g.lines],
    )


async def _load(db, gid: str) -> GuestOrder:
    g = (
        await db.execute(
            select(GuestOrder)
            .where(GuestOrder.id == gid)
            .options(selectinload(GuestOrder.lines), selectinload(GuestOrder.table))
        )
    ).scalar_one_or_none()
    if not g:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "guest order not found")
    return g


@router.get("", response_model=list[GuestOrderRead])
async def list_guest_orders(
    db: DbSession,
    user: CurrentUserDep,
    store_id: str | None = Query(default=None),
    status_in: str = Query(
        default="submitted,accepted,ready",
        description="comma-separated subset of: submitted,accepted,ready,merged,cancelled",
    ),
    limit: int = Query(default=100, le=500),
):
    statuses = [s.strip() for s in status_in.split(",") if s.strip()]
    target_store = store_id or user.store_id
    stmt = (
        select(GuestOrder)
        .where(GuestOrder.store_id == target_store)
        .where(GuestOrder.status.in_(statuses))
        .options(selectinload(GuestOrder.lines), selectinload(GuestOrder.table))
        .order_by(GuestOrder.created_at.desc())
        .limit(limit)
    )
    rows = (await db.execute(stmt)).scalars().all()
    return [_to_read(g) for g in rows]


@router.get("/{gid}", response_model=GuestOrderRead)
async def get_guest_order(gid: str, db: DbSession, _: CurrentUserDep):
    return _to_read(await _load(db, gid))


@router.post("/{gid}/accept", response_model=GuestOrderRead)
async def accept(gid: str, db: DbSession, user: CurrentUserDep):
    g = await _load(db, gid)
    if g.status != "submitted":
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot accept from status={g.status}")
    g.status = "accepted"
    g.accepted_at = datetime.now(timezone.utc)
    g.accepted_by_user_id = user.user_id
    await db.commit()
    await db.refresh(g)
    return _to_read(g)


@router.post("/{gid}/ready", response_model=GuestOrderRead)
async def mark_ready(gid: str, db: DbSession, _: CurrentUserDep):
    g = await _load(db, gid)
    if g.status != "accepted":
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot mark ready from status={g.status}")
    g.status = "ready"
    g.ready_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(g)
    return _to_read(g)


@router.post("/{gid}/cancel", response_model=GuestOrderRead)
async def cancel(gid: str, payload: CancelRequest, db: DbSession, _: CurrentUserDep):
    g = await _load(db, gid)
    if g.status in ("merged", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"already {g.status}")
    g.status = "cancelled"
    g.cancelled_at = datetime.now(timezone.utc)
    g.cancel_reason = payload.reason
    await db.commit()
    await db.refresh(g)
    return _to_read(g)


@router.post("/{gid}/merge", response_model=GuestOrderRead)
async def merge_into_order(gid: str, payload: MergeRequest, db: DbSession, _: CurrentUserDep):
    """Mark a guest order as merged into a paid Order.

    This expects the cashier (POS) to have already uploaded the canonical
    paid Order via ``POST /orders``. We just flip the guest_order's status
    here and stamp ``source_guest_order_id`` on the Order so reports can
    reconcile both sides.
    """
    g = await _load(db, gid)
    if g.status not in ("ready", "accepted", "submitted"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot merge from status={g.status}")
    order = await db.get(Order, payload.order_id)
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "paid order not found; upload it first")
    if order.store_id != g.store_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "order and guest order belong to different stores")

    order.source_guest_order_id = g.id
    g.status = "merged"
    g.merged_at = datetime.now(timezone.utc)
    g.merged_order_id = order.id
    await db.commit()
    await db.refresh(g)
    return _to_read(g)
