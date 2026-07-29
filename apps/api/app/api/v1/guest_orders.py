"""Staff endpoints for the guest-order (table-side ordering) workflow.

State machine:

    submitted -> accepted -> ready -> merged
                                  \\-> cancelled
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    TenantScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...models import GuestOrder, Order
from pydantic import BaseModel

from ...schemas.guest_order import (
    CancelRequest,
    GuestOrderLineRead,
    GuestOrderRead,
    MergeRequest,
)
from ...services.tenant_modules import require_guest_order_admin
from .table_sessions import close_sessions_for_guest_table

# Uber Eats style delivery sub-states.
DELIVERY_FLOW = ("pending", "preparing", "out_for_delivery", "delivered")


class DeliveryStatusUpdate(BaseModel):
    status: str

router = APIRouter(
    prefix="/guest-orders",
    tags=["guest-orders"],
    dependencies=[Depends(require_guest_order_admin)],
)


def _to_read(g: GuestOrder) -> GuestOrderRead:
    return GuestOrderRead(
        id=g.id,
        tenant_id=g.tenant_id,
        store_id=g.store_id,
        table_id=g.table_id,
        table_label=g.table.label if g.table else None,
        channel=g.channel,
        fulfillment_type=g.fulfillment_type,
        customer_name=g.customer_name,
        customer_phone=g.customer_phone,
        delivery_address=g.delivery_address,
        delivery_note=g.delivery_note,
        delivery_status=g.delivery_status,
        payment_method=g.payment_method,
        payment_status=g.payment_status,
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


async def _load(db, scope, gid: str) -> GuestOrder:
    g = (
        await db.execute(
            select(GuestOrder)
            .where(GuestOrder.id == gid)
            .options(selectinload(GuestOrder.lines), selectinload(GuestOrder.table))
        )
    ).scalar_one_or_none()
    if not g:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "guest order not found")
    ensure_same_tenant(scope, g)
    return g


@router.get("", response_model=list[GuestOrderRead])
async def list_guest_orders(
    db: DbSession,
    scope: TenantScope,
    store_id: str | None = Query(default=None),
    channel: str | None = Query(default=None, description="table_qr|marketplace|shopping"),
    fulfillment_type: str | None = Query(default=None),
    status_in: str = Query(
        default="submitted,accepted,ready",
        description="comma-separated subset of: submitted,accepted,ready,merged,cancelled",
    ),
    limit: int = Query(default=100, le=500),
):
    statuses = [s.strip() for s in status_in.split(",") if s.strip()]
    target_store = store_id or scope.store_id
    stmt = apply_tenant(select(GuestOrder), GuestOrder, scope)
    if target_store:
        stmt = stmt.where(GuestOrder.store_id == target_store)
    if channel:
        stmt = stmt.where(GuestOrder.channel == channel)
    if fulfillment_type:
        stmt = stmt.where(GuestOrder.fulfillment_type == fulfillment_type)
    stmt = (
        stmt.where(GuestOrder.status.in_(statuses))
        .options(selectinload(GuestOrder.lines), selectinload(GuestOrder.table))
        .order_by(GuestOrder.created_at.desc())
        .limit(limit)
    )
    rows = (await db.execute(stmt)).scalars().all()
    return [_to_read(g) for g in rows]


@router.get("/{gid}", response_model=GuestOrderRead)
async def get_guest_order(gid: str, db: DbSession, scope: TenantScope):
    return _to_read(await _load(db, scope, gid))


@router.post("/{gid}/accept", response_model=GuestOrderRead)
async def accept(gid: str, db: DbSession, scope: TenantScope):
    g = await _load(db, scope, gid)
    if g.status != "submitted":
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot accept from status={g.status}")
    g.status = "accepted"
    g.accepted_at = datetime.now(timezone.utc)
    g.accepted_by_user_id = scope.user_id
    await audit(db, scope, action="guest_order_accept", resource_type="guest_order",
                resource_id=gid, flush=False)
    await db.commit()
    await db.refresh(g)
    return _to_read(g)


@router.post("/{gid}/ready", response_model=GuestOrderRead)
async def mark_ready(gid: str, db: DbSession, scope: TenantScope):
    g = await _load(db, scope, gid)
    if g.status != "accepted":
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot mark ready from status={g.status}")
    g.status = "ready"
    g.ready_at = datetime.now(timezone.utc)
    await audit(db, scope, action="guest_order_ready", resource_type="guest_order",
                resource_id=gid, flush=False)
    await db.commit()
    await db.refresh(g)
    return _to_read(g)


@router.post("/{gid}/cancel", response_model=GuestOrderRead)
async def cancel(
    gid: str, payload: CancelRequest, db: DbSession, scope: TenantScope
):
    g = await _load(db, scope, gid)
    if g.status in ("merged", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"already {g.status}")
    g.status = "cancelled"
    g.cancelled_at = datetime.now(timezone.utc)
    g.cancel_reason = payload.reason
    await audit(db, scope, action="guest_order_cancel", resource_type="guest_order",
                resource_id=gid, flush=False)
    await db.commit()
    await db.refresh(g)
    return _to_read(g)


@router.post("/{gid}/complete", response_model=GuestOrderRead)
async def complete_online_paid(gid: str, db: DbSession, scope: TenantScope):
    """Mark a marketplace online-paid guest order as merged without creating a POS payment."""
    g = await _load(db, scope, gid)
    if g.channel != "marketplace":
        raise HTTPException(status.HTTP_409_CONFLICT, "complete is only for marketplace orders")
    if g.payment_method != "online" or g.payment_status != "paid":
        raise HTTPException(status.HTTP_409_CONFLICT, "order is not online-paid")
    if g.status not in ("ready", "accepted"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot complete from status={g.status}")
    if g.fulfillment_type == "delivery" and g.delivery_status != "delivered":
        raise HTTPException(status.HTTP_409_CONFLICT, "delivery orders must be marked delivered first")

    g.status = "merged"
    g.merged_at = datetime.now(timezone.utc)
    await audit(
        db,
        scope,
        action="guest_order_complete",
        resource_type="guest_order",
        resource_id=gid,
        flush=False,
    )
    await db.commit()
    await db.refresh(g)
    return _to_read(g)


@router.post("/{gid}/delivery-status", response_model=GuestOrderRead)
async def set_delivery_status(
    gid: str, payload: DeliveryStatusUpdate, db: DbSession, scope: TenantScope
):
    """Advance the delivery sub-state (pending -> preparing -> out_for_delivery
    -> delivered) for a marketplace delivery order."""
    g = await _load(db, scope, gid)
    if g.fulfillment_type != "delivery":
        raise HTTPException(status.HTTP_409_CONFLICT, "not a delivery order")
    if payload.status not in DELIVERY_FLOW:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid delivery status")
    if g.status in ("merged", "cancelled"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"order is {g.status}")
    g.delivery_status = payload.status
    await audit(
        db,
        scope,
        action="guest_order_delivery_status",
        resource_type="guest_order",
        resource_id=gid,
        extra={"delivery_status": payload.status},
        flush=False,
    )
    await db.commit()
    await db.refresh(g)
    return _to_read(g)


@router.post("/{gid}/deliver", response_model=GuestOrderRead)
async def mark_delivered(gid: str, db: DbSession, scope: TenantScope):
    g = await _load(db, scope, gid)
    if g.fulfillment_type != "delivery":
        raise HTTPException(status.HTTP_409_CONFLICT, "not a delivery order")
    if g.status not in ("accepted", "ready"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot deliver from status={g.status}")
    if g.delivery_status == "delivered":
        raise HTTPException(status.HTTP_409_CONFLICT, "already delivered")

    g.delivery_status = "delivered"
    await audit(
        db,
        scope,
        action="guest_order_deliver",
        resource_type="guest_order",
        resource_id=gid,
        flush=False,
    )
    await db.commit()
    await db.refresh(g)
    return _to_read(g)


@router.post("/{gid}/merge", response_model=GuestOrderRead)
async def merge_into_order(
    gid: str, payload: MergeRequest, db: DbSession, scope: TenantScope
):
    g = await _load(db, scope, gid)
    if g.status not in ("ready", "accepted", "submitted"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot merge from status={g.status}")
    order = await db.get(Order, payload.order_id)
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "paid order not found; upload it first")
    ensure_same_tenant(scope, order)
    if order.store_id != g.store_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "order and guest order belong to different stores")

    order.source_guest_order_id = g.id
    g.status = "merged"
    g.merged_at = datetime.now(timezone.utc)
    g.merged_order_id = order.id
    await close_sessions_for_guest_table(db, g.table_id)
    await audit(db, scope, action="guest_order_merge", resource_type="guest_order",
                resource_id=gid, flush=False)
    await db.commit()
    await db.refresh(g)
    return _to_read(g)
