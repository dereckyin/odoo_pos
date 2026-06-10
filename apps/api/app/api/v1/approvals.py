"""Refund / void approval workflow (layer-1 manager 退貨/作廢審核).

Cashiers may file a refund (routed to "pending" when the tenant requires it)
or a void request; a store manager or above approves/rejects here. Approving a
refund materialises its inventory/loyalty effects; approving a void reverses the
whole order.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import DbSession, StoreAdminDep, TenantScope, apply_tenant, ensure_same_tenant
from ...models import (
    InventoryLevel,
    InventoryMovement,
    Member,
    Order,
    Product,
    Refund,
    Store,
    User,
)
from ...schemas.order import (
    OrderApprovalItem,
    RefundDecisionRequest,
    RefundListItem,
    VoidDecisionRequest,
    VoidRequestCreate,
)
from ...services.inventory_tracking import product_tracks_inventory
from ...services.loyalty_engine import reverse_order_loyalty
from .refunds import apply_refund_effects

router = APIRouter(prefix="/approvals", tags=["approvals"])


def _now() -> datetime:
    return datetime.now(timezone.utc)


# ---------------------------------------------------------------------------
# Refund review
# ---------------------------------------------------------------------------

@router.get("/refunds", response_model=list[RefundListItem])
async def list_refunds(
    db: DbSession,
    scope: StoreAdminDep,
    status_filter: str | None = Query(default=None, alias="status"),
):
    stmt = (
        select(Refund, Order, Store, User)
        .join(Order, Refund.order_id == Order.id)
        .join(Store, Order.store_id == Store.id, isouter=True)
        .join(User, Refund.user_id == User.id, isouter=True)
    )
    stmt = apply_tenant(stmt, Order, scope)
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    if status_filter:
        stmt = stmt.where(Refund.status == status_filter)
    stmt = stmt.order_by(Refund.created_at.desc()).limit(500)
    rows = (await db.execute(stmt)).all()
    items: list[RefundListItem] = []
    for refund, order, store, user in rows:
        items.append(
            RefundListItem.model_validate(refund).model_copy(
                update={
                    "order_no": order.order_no,
                    "store_name": store.name if store else None,
                    "user_name": user.display_name if user else None,
                }
            )
        )
    return items


async def _refund_or_404(db, scope, rid: str) -> tuple[Refund, Order]:
    refund = await db.get(Refund, rid)
    if not refund:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "refund not found")
    order = (
        await db.execute(
            select(Order).where(Order.id == refund.order_id).options(selectinload(Order.lines))
        )
    ).scalar_one_or_none()
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "order not found")
    ensure_same_tenant(scope, order)
    if scope.store_id and not scope.is_tenant_admin and order.store_id != scope.store_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "refund not found")
    return refund, order


@router.post("/refunds/{rid}/approve", status_code=204)
async def approve_refund(rid: str, db: DbSession, scope: StoreAdminDep) -> None:
    refund, order = await _refund_or_404(db, scope, rid)
    if refund.status != "pending":
        raise HTTPException(status.HTTP_409_CONFLICT, "refund not pending")
    refund.status = "approved"
    refund.approver_id = scope.user_id
    refund.decided_at = _now()
    await apply_refund_effects(db, refund, order)
    await audit(db, scope, action="refund_approve", resource_type="refund",
                resource_id=refund.id, flush=False)
    await db.commit()


@router.post("/refunds/{rid}/reject", status_code=204)
async def reject_refund(
    rid: str, payload: RefundDecisionRequest, db: DbSession, scope: StoreAdminDep
) -> None:
    refund, _order = await _refund_or_404(db, scope, rid)
    if refund.status != "pending":
        raise HTTPException(status.HTTP_409_CONFLICT, "refund not pending")
    refund.status = "rejected"
    refund.approver_id = scope.user_id
    refund.decided_at = _now()
    refund.reject_reason = payload.reason
    await audit(db, scope, action="refund_reject", resource_type="refund",
                resource_id=refund.id, flush=False)
    await db.commit()


# ---------------------------------------------------------------------------
# Void review
# ---------------------------------------------------------------------------

@router.get("/voids", response_model=list[OrderApprovalItem])
async def list_void_requests(
    db: DbSession,
    scope: StoreAdminDep,
    status_filter: str | None = Query(default="pending", alias="status"),
):
    stmt = select(Order, Store).join(Store, Order.store_id == Store.id, isouter=True)
    stmt = apply_tenant(stmt, Order, scope)
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    if status_filter:
        stmt = stmt.where(Order.void_status == status_filter)
    else:
        stmt = stmt.where(Order.void_status.isnot(None))
    stmt = stmt.order_by(Order.created_at.desc()).limit(500)
    rows = (await db.execute(stmt)).all()
    return [
        OrderApprovalItem.model_validate(order).model_copy(
            update={"store_name": store.name if store else None}
        )
        for order, store in rows
    ]


@router.post("/voids", response_model=OrderApprovalItem, status_code=201)
async def create_void_request(
    payload: VoidRequestCreate, db: DbSession, scope: TenantScope
) -> Order:
    order = (
        await db.execute(
            select(Order).where(Order.id == payload.order_id).options(selectinload(Order.lines))
        )
    ).scalar_one_or_none()
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "order not found")
    ensure_same_tenant(scope, order)
    if scope.store_id and not scope.is_tenant_admin and order.store_id != scope.store_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "order not found")
    if order.status != "paid":
        raise HTTPException(status.HTTP_409_CONFLICT, "only paid orders can be voided")
    if order.void_status == "pending":
        return order
    order.void_status = "pending"
    order.void_reason = payload.reason
    # Store-admins voiding directly are auto-approved.
    if scope.is_store_admin:
        await _apply_void(db, order, scope.user_id)
    await audit(db, scope, action="void_request", resource_type="order",
                resource_id=order.id, flush=False)
    await db.commit()
    await db.refresh(order)
    return order


async def _apply_void(db, order: Order, approver_id: str) -> None:
    """Reverse a paid order entirely: restock everything, reverse loyalty,
    and flip the order to voided."""
    order_lines = order.lines
    product_ids = {ln.product_id for ln in order_lines}
    products_by_id = {
        p.id: p
        for p in (await db.execute(select(Product).where(Product.id.in_(product_ids)))).scalars()
    }
    for ln in order_lines:
        p = products_by_id.get(ln.product_id)
        if product_tracks_inventory(p):
            db.add(InventoryMovement(
                tenant_id=order.tenant_id,
                store_id=order.store_id,
                product_id=ln.product_id,
                qty_delta=float(ln.qty),
                reason="void",
                ref_type="void",
                ref_id=order.id,
                terminal_id=order.terminal_id,
                user_id=approver_id,
            ))
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
                    tenant_id=order.tenant_id,
                    store_id=order.store_id,
                    product_id=ln.product_id,
                    on_hand=float(ln.qty),
                ))
            else:
                level.on_hand = float(level.on_hand) + float(ln.qty)

    if order.member_id:
        member = await db.get(Member, order.member_id)
        if member:
            await reverse_order_loyalty(
                db,
                tenant_id=order.tenant_id,
                member=member,
                order_id=order.id,
                refund_cents=order.total_cents,
                original_total_cents=order.total_cents,
                points_redeemed_on_order=order.points_redeemed or 0,
            )

    order.status = "voided"
    order.void_status = "approved"
    order.voided_by = approver_id
    order.voided_at = _now()


async def _void_order_or_404(db, scope, oid: str) -> Order:
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
    return order


@router.post("/voids/{oid}/approve", status_code=204)
async def approve_void(oid: str, db: DbSession, scope: StoreAdminDep) -> None:
    order = await _void_order_or_404(db, scope, oid)
    if order.void_status != "pending":
        raise HTTPException(status.HTTP_409_CONFLICT, "no pending void")
    if order.status != "paid":
        raise HTTPException(status.HTTP_409_CONFLICT, "order not voidable")
    await _apply_void(db, order, scope.user_id)
    await audit(db, scope, action="void_approve", resource_type="order",
                resource_id=order.id, flush=False)
    await db.commit()


@router.post("/voids/{oid}/reject", status_code=204)
async def reject_void(
    oid: str, payload: VoidDecisionRequest, db: DbSession, scope: StoreAdminDep
) -> None:
    order = await _void_order_or_404(db, scope, oid)
    if order.void_status != "pending":
        raise HTTPException(status.HTTP_409_CONFLICT, "no pending void")
    order.void_status = "rejected"
    order.void_reason = payload.reason or order.void_reason
    await audit(db, scope, action="void_reject", resource_type="order",
                resource_id=order.id, flush=False)
    await db.commit()
