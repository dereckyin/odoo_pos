"""Procurement: suppliers + purchase orders + receive into inventory."""

from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import DbSession, StoreAdminDep, apply_tenant, ensure_same_tenant
from ...models import InventoryMovement, Product, PurchaseOrder, PurchaseOrderLine, Store, Supplier
from ...services.inventory_tracking import product_tracks_inventory
from ...schemas.purchasing import (
    PurchaseOrderCreate,
    PurchaseOrderRead,
    PurchaseOrderReceive,
    PurchaseOrderStatusPatch,
    SupplierCreate,
    SupplierRead,
    SupplierUpdate,
)
from .inventories import _apply_movement, _ensure_store_in_tenant

router = APIRouter(prefix="/purchasing", tags=["purchasing"])


async def _supplier_or_404(db, scope: StoreAdminDep, sid: str) -> Supplier:
    s = await db.get(Supplier, sid)
    if not s or s.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "supplier not found")
    ensure_same_tenant(scope, s)
    return s


async def _po_or_404(db, scope: StoreAdminDep, pid: str) -> PurchaseOrder:
    po = (
        await db.execute(
            select(PurchaseOrder)
            .where(PurchaseOrder.id == pid)
            .options(selectinload(PurchaseOrder.lines))
        )
    ).scalar_one_or_none()
    if not po:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "purchase order not found")
    ensure_same_tenant(scope, po)
    return po


async def _ensure_products_in_tenant(db, tenant_id: str, product_ids: set[str]) -> None:
    if not product_ids:
        return
    rows = (
        await db.execute(
            select(Product.id).where(
                Product.tenant_id == tenant_id,
                Product.id.in_(product_ids),
                Product.deleted_at.is_(None),
            )
        )
    ).scalars().all()
    if set(rows) != product_ids:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "one or more products not found in tenant")


def _recompute_po_status(po: PurchaseOrder) -> None:
    lines = po.lines
    if not lines:
        return
    eps = 1e-6
    all_done = all(float(l.qty_received) + eps >= float(l.qty_ordered) for l in lines)
    any_recv = any(float(l.qty_received) > eps for l in lines)
    if all_done:
        po.status = "received"
    elif any_recv:
        po.status = "partial"


# ---------------------------------------------------------------------------
# Suppliers
# ---------------------------------------------------------------------------


@router.get("/suppliers", response_model=list[SupplierRead])
async def list_suppliers(db: DbSession, scope: StoreAdminDep):
    stmt = apply_tenant(
        select(Supplier).where(Supplier.deleted_at.is_(None)), Supplier, scope
    ).order_by(Supplier.code)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.post("/suppliers", response_model=SupplierRead, status_code=201)
async def create_supplier(payload: SupplierCreate, db: DbSession, scope: StoreAdminDep):
    tid = scope.tenant_id
    dup = (
        await db.execute(
            select(Supplier).where(
                Supplier.tenant_id == tid,
                Supplier.code == payload.code,
                Supplier.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if dup:
        raise HTTPException(status.HTTP_409_CONFLICT, "supplier code already exists")
    s = Supplier(tenant_id=tid, **payload.model_dump())
    db.add(s)
    await audit(db, scope, action="supplier_create", resource_type="supplier", resource_id=s.id, flush=False)
    await db.commit()
    await db.refresh(s)
    return s


@router.patch("/suppliers/{sid}", response_model=SupplierRead)
async def update_supplier(
    sid: str, payload: SupplierUpdate, db: DbSession, scope: StoreAdminDep
):
    s = await _supplier_or_404(db, scope, sid)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(s, k, v)
    await audit(db, scope, action="supplier_update", resource_type="supplier", resource_id=sid, flush=False)
    await db.commit()
    await db.refresh(s)
    return s


# ---------------------------------------------------------------------------
# Purchase orders
# ---------------------------------------------------------------------------


@router.get("/orders", response_model=list[PurchaseOrderRead])
async def list_purchase_orders(
    db: DbSession,
    scope: StoreAdminDep,
    store_id: str | None = None,
    status_in: str | None = Query(None, description="Comma-separated statuses"),
):
    stmt = apply_tenant(select(PurchaseOrder), PurchaseOrder, scope).options(
        selectinload(PurchaseOrder.lines)
    )
    if store_id:
        await _ensure_store_in_tenant(db, scope, store_id)
        stmt = stmt.where(PurchaseOrder.store_id == store_id)
    if status_in:
        parts = [p.strip() for p in status_in.split(",") if p.strip()]
        if parts:
            stmt = stmt.where(PurchaseOrder.status.in_(parts))
    stmt = stmt.order_by(PurchaseOrder.created_at.desc()).limit(200)
    rows = (await db.execute(stmt)).scalars().unique().all()
    return rows


@router.post("/orders", response_model=PurchaseOrderRead, status_code=201)
async def create_purchase_order(payload: PurchaseOrderCreate, db: DbSession, scope: StoreAdminDep):
    tid = scope.require_tenant()
    existing = await db.get(PurchaseOrder, payload.id)
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "purchase order id already exists")
    await _ensure_store_in_tenant(db, scope, payload.store_id)
    await _supplier_or_404(db, scope, payload.supplier_id)
    pids = {ln.product_id for ln in payload.lines}
    await _ensure_products_in_tenant(db, tid, pids)
    line_ids = {ln.id for ln in payload.lines}
    if len(line_ids) != len(payload.lines):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "duplicate line id")

    po = PurchaseOrder(
        id=payload.id,
        tenant_id=tid,
        store_id=payload.store_id,
        supplier_id=payload.supplier_id,
        status="draft",
        reference=payload.reference,
        note=payload.note,
    )
    db.add(po)
    await db.flush()
    for ln in payload.lines:
        db.add(
            PurchaseOrderLine(
                id=ln.id,
                purchase_order_id=po.id,
                product_id=ln.product_id,
                qty_ordered=ln.qty_ordered,
                qty_received=0,
            )
        )
    await audit(
        db, scope, action="purchase_order_create", resource_type="purchase_order",
        resource_id=po.id, extra={"store_id": po.store_id}, flush=False,
    )
    await db.commit()
    po = (
        await db.execute(
            select(PurchaseOrder)
            .where(PurchaseOrder.id == po.id)
            .options(selectinload(PurchaseOrder.lines))
        )
    ).scalar_one()
    return po


@router.get("/orders/{pid}", response_model=PurchaseOrderRead)
async def get_purchase_order(pid: str, db: DbSession, scope: StoreAdminDep):
    return await _po_or_404(db, scope, pid)


@router.patch("/orders/{pid}", response_model=PurchaseOrderRead)
async def patch_purchase_order(
    pid: str, payload: PurchaseOrderStatusPatch, db: DbSession, scope: StoreAdminDep
):
    po = await _po_or_404(db, scope, pid)
    new_status = payload.status
    if new_status == "ordered":
        if po.status != "draft":
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "only draft orders can be ordered")
        po.status = "ordered"
        po.ordered_at = datetime.now(timezone.utc)
        await audit(
            db, scope, action="purchase_order_order", resource_type="purchase_order",
            resource_id=pid, flush=False,
        )
    elif new_status == "cancelled":
        if po.status in ("received", "cancelled"):
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "cannot cancel this order")
        if any(float(ln.qty_received) > 0 for ln in po.lines):
            raise HTTPException(status.HTTP_409_CONFLICT, "cannot cancel after inventory was received")
        po.status = "cancelled"
        await audit(
            db, scope, action="purchase_order_cancel", resource_type="purchase_order",
            resource_id=pid, flush=False,
        )
    else:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "unsupported status transition")

    await db.commit()
    po = (
        await db.execute(
            select(PurchaseOrder)
            .where(PurchaseOrder.id == pid)
            .options(selectinload(PurchaseOrder.lines))
        )
    ).scalar_one()
    return po


@router.post("/orders/{pid}/receive", response_model=PurchaseOrderRead)
async def receive_purchase_order(
    pid: str, payload: PurchaseOrderReceive, db: DbSession, scope: StoreAdminDep
):
    po = await _po_or_404(db, scope, pid)
    if po.status not in ("ordered", "partial"):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "receive only allowed when status is ordered or partial",
        )
    tid = scope.require_tenant()
    now = datetime.now(timezone.utc)
    line_by_id = {ln.id: ln for ln in po.lines}
    applied = False

    for item in payload.lines:
        ln = line_by_id.get(item.line_id)
        if not ln:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"unknown line_id {item.line_id}")
        allow = float(ln.qty_ordered) - float(ln.qty_received)
        if allow <= 0:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"line {item.line_id} already fully received")
        take = min(float(item.qty), allow)
        if take <= 0:
            continue
        applied = True
        product = await db.get(Product, ln.product_id)
        if product_tracks_inventory(product):
            mid = str(uuid4())
            m = InventoryMovement(
                id=mid,
                tenant_id=tid,
                store_id=po.store_id,
                product_id=ln.product_id,
                qty_delta=take,
                reason="receive",
                ref_type="purchase_order",
                ref_id=po.id,
                user_id=scope.user_id,
                client_created_at=now,
            )
            db.add(m)
            await _apply_movement(db, m)
        ln.qty_received = float(ln.qty_received) + take

    if not applied:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "no positive receive quantities applied")

    _recompute_po_status(po)
    await audit(
        db, scope, action="purchase_order_receive", resource_type="purchase_order",
        resource_id=pid, flush=False,
    )
    await db.commit()
    po = (
        await db.execute(
            select(PurchaseOrder)
            .where(PurchaseOrder.id == pid)
            .options(selectinload(PurchaseOrder.lines))
        )
    ).scalar_one()
    return po
