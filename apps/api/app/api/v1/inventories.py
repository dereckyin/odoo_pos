from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    StoreAdminDep,
    TenantScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...models import (
    InventoryLevel,
    InventoryMovement,
    Product,
    Store,
    Stocktake,
    StocktakeLine,
    TransferLine,
    TransferOrder,
)
from ...schemas.inventory import (
    InventoryAdjustCreate,
    InventoryLevelRead,
    InventoryLevelUpdate,
    MovementCreate,
    MovementRead,
    StocktakeCreate,
    StocktakeRead,
    TransferCreate,
    TransferRead,
    TransferUpdate,
)
from ...services.inventory_tracking import product_tracks_inventory

router = APIRouter(prefix="/inventory", tags=["inventory"])


def _resolve_store_id(scope, requested: str | None) -> str:
    """Pick the store id to operate on. If the JWT carries one (POS session)
    that's authoritative; otherwise the caller (admin) must supply one."""
    if scope.store_id:
        if requested and requested != scope.store_id:
            raise HTTPException(
                status.HTTP_403_FORBIDDEN,
                "store_id in payload does not match session store",
            )
        return scope.store_id
    if not requested:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "store_id required (your session is not bound to one)",
        )
    return requested


async def _ensure_store_in_tenant(db, scope, store_id: str) -> None:
    s = await db.get(Store, store_id)
    if not s or s.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    ensure_same_tenant(scope, s)


async def _apply_movement(db, m: InventoryMovement) -> None:
    level = (
        await db.execute(
            select(InventoryLevel).where(
                InventoryLevel.store_id == m.store_id,
                InventoryLevel.product_id == m.product_id,
            )
        )
    ).scalar_one_or_none()
    if level is None:
        level = InventoryLevel(
            tenant_id=m.tenant_id,
            store_id=m.store_id,
            product_id=m.product_id,
            on_hand=m.qty_delta,
        )
        db.add(level)
    else:
        level.on_hand = float(level.on_hand) + float(m.qty_delta)


def _level_read(
    lvl: InventoryLevel,
    store_map: dict[str, str],
    product_map: dict[str, Product],
) -> InventoryLevelRead:
    p = product_map.get(lvl.product_id)
    return InventoryLevelRead.model_validate(lvl).model_copy(
        update={
            "store_name": store_map.get(lvl.store_id),
            "product_name": p.name if p else None,
            "product_sku": p.sku if p else None,
        }
    )


@router.get("/levels", response_model=list[InventoryLevelRead])
async def list_levels(
    db: DbSession, scope: TenantScope, store_id: str | None = None
):
    stmt = apply_tenant(select(InventoryLevel), InventoryLevel, scope)
    if store_id:
        stmt = stmt.where(InventoryLevel.store_id == store_id)
    elif scope.store_id:
        stmt = stmt.where(InventoryLevel.store_id == scope.store_id)
    rows = (await db.execute(stmt)).scalars().all()
    if not rows:
        return []
    store_ids = {r.store_id for r in rows}
    product_ids = {r.product_id for r in rows}
    store_map = {
        s.id: s.name
        for s in (await db.execute(select(Store).where(Store.id.in_(store_ids)))).scalars()
    }
    product_map = {
        p.id: p
        for p in (await db.execute(select(Product).where(Product.id.in_(product_ids)))).scalars()
    }
    return [
        _level_read(lvl, store_map, product_map)
        for lvl in rows
        if product_tracks_inventory(product_map.get(lvl.product_id))
    ]


async def _product_or_404(db, scope, product_id: str) -> Product:
    p = await db.get(Product, product_id)
    if not p or p.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "product not found")
    ensure_same_tenant(scope, p)
    return p


@router.post("/adjust", response_model=InventoryLevelRead)
async def adjust_inventory(
    payload: InventoryAdjustCreate, db: DbSession, scope: StoreAdminDep
):
    if payload.mode not in ("delta", "set"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "mode must be delta or set")
    if payload.reason not in ("adjustment", "initial"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "reason must be adjustment or initial")
    if payload.mode == "set" and payload.qty < 0:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "target on_hand cannot be negative")

    await _ensure_store_in_tenant(db, scope, payload.store_id)
    product = await _product_or_404(db, scope, payload.product_id)
    if not product_tracks_inventory(product):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "此商品不追蹤庫存")

    level = (
        await db.execute(
            select(InventoryLevel).where(
                InventoryLevel.store_id == payload.store_id,
                InventoryLevel.product_id == payload.product_id,
            )
        )
    ).scalar_one_or_none()
    current = float(level.on_hand) if level else 0.0
    if payload.mode == "set":
        qty_delta = float(payload.qty) - current
    else:
        qty_delta = float(payload.qty)

    if qty_delta == 0:
        if level is None:
            level = InventoryLevel(
                tenant_id=scope.tenant_id,
                store_id=payload.store_id,
                product_id=payload.product_id,
                on_hand=0,
            )
            db.add(level)
            await db.flush()
        store_map = {
            payload.store_id: (
                await db.get(Store, payload.store_id)
            ).name
        }
        return _level_read(level, store_map, {product.id: product})

    m = InventoryMovement(
        id=str(uuid4()),
        tenant_id=scope.tenant_id,
        store_id=payload.store_id,
        product_id=payload.product_id,
        qty_delta=qty_delta,
        reason=payload.reason,
        ref_type="inventory_adjust",
        user_id=scope.user_id,
        note=payload.note,
    )
    db.add(m)
    await _apply_movement(db, m)
    await audit(
        db,
        scope,
        action="inventory_adjust",
        resource_type="inventory_level",
        resource_id=payload.product_id,
        extra={
            "store_id": payload.store_id,
            "mode": payload.mode,
            "qty": payload.qty,
            "qty_delta": qty_delta,
            "reason": payload.reason,
        },
        flush=False,
    )
    await db.commit()
    level = (
        await db.execute(
            select(InventoryLevel).where(
                InventoryLevel.store_id == payload.store_id,
                InventoryLevel.product_id == payload.product_id,
            )
        )
    ).scalar_one()
    store = await db.get(Store, payload.store_id)
    return _level_read(level, {payload.store_id: store.name if store else None}, {product.id: product})


@router.patch("/levels/{level_id}", response_model=InventoryLevelRead)
async def update_level(
    level_id: str, payload: InventoryLevelUpdate, db: DbSession, scope: StoreAdminDep
):
    lvl = await db.get(InventoryLevel, level_id)
    if not lvl:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, lvl)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(lvl, k, v)
    await audit(db, scope, action="inventory_level_update", resource_type="inventory_level",
                resource_id=level_id, flush=False)
    await db.commit()
    await db.refresh(lvl)
    return lvl


@router.post("/movements", response_model=MovementRead, status_code=201)
async def record_movement(
    payload: MovementCreate, db: DbSession, scope: TenantScope
):
    existing = await db.get(InventoryMovement, payload.id)
    if existing:
        ensure_same_tenant(scope, existing)
        return existing

    target_store = _resolve_store_id(scope, payload.store_id)
    await _ensure_store_in_tenant(db, scope, target_store)

    product = await db.get(Product, payload.product_id)
    if product and not product_tracks_inventory(product):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "此商品不追蹤庫存")

    data = payload.model_dump()
    data["store_id"] = target_store
    data["user_id"] = data.get("user_id") or scope.user_id
    data["terminal_id"] = data.get("terminal_id") or scope.terminal_id
    m = InventoryMovement(tenant_id=scope.tenant_id, **data)
    db.add(m)
    await _apply_movement(db, m)
    await audit(db, scope, action="inventory_movement", resource_type="inventory_movement",
                resource_id=payload.id, extra={"reason": payload.reason}, flush=False)
    await db.commit()
    await db.refresh(m)
    return m


@router.post("/movements/batch", response_model=list[MovementRead], status_code=201)
async def record_movements(
    payload: list[MovementCreate], db: DbSession, scope: TenantScope
):
    results: list[InventoryMovement] = []
    for item in payload:
        existing = await db.get(InventoryMovement, item.id)
        if existing:
            ensure_same_tenant(scope, existing)
            results.append(existing)
            continue
        target_store = _resolve_store_id(scope, item.store_id)
        await _ensure_store_in_tenant(db, scope, target_store)
        data = item.model_dump()
        data["store_id"] = target_store
        data["user_id"] = data.get("user_id") or scope.user_id
        data["terminal_id"] = data.get("terminal_id") or scope.terminal_id
        m = InventoryMovement(tenant_id=scope.tenant_id, **data)
        db.add(m)
        await _apply_movement(db, m)
        results.append(m)
    await db.commit()
    for r in results:
        await db.refresh(r)
    return results


@router.post("/transfers", response_model=TransferRead, status_code=201)
async def create_transfer(
    payload: TransferCreate, db: DbSession, scope: StoreAdminDep
):
    await _ensure_store_in_tenant(db, scope, payload.from_store_id)
    await _ensure_store_in_tenant(db, scope, payload.to_store_id)
    t = TransferOrder(
        id=payload.id,
        tenant_id=scope.tenant_id,
        from_store_id=payload.from_store_id,
        to_store_id=payload.to_store_id,
        status=payload.status,
        note=payload.note,
    )
    db.add(t)
    await db.flush()
    for ln in payload.lines:
        db.add(
            TransferLine(
                id=ln.id,
                transfer_id=t.id,
                product_id=ln.product_id,
                qty=ln.qty,
                received_qty=ln.received_qty,
            )
        )
    await audit(db, scope, action="transfer_create", resource_type="transfer_order",
                resource_id=t.id, flush=False)
    await db.commit()
    await db.refresh(t)
    return t


@router.patch("/transfers/{tid}", response_model=TransferRead)
async def update_transfer(
    tid: str, payload: TransferUpdate, db: DbSession, scope: StoreAdminDep
):
    t = (
        await db.execute(
            select(TransferOrder)
            .where(TransferOrder.id == tid)
            .options(selectinload(TransferOrder.lines))
        )
    ).scalar_one_or_none()
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, t)
    t.status = payload.status
    now = datetime.now(timezone.utc)
    if payload.status == "dispatched":
        t.dispatched_at = now
        for ln in t.lines:
            mvt = InventoryMovement(
                tenant_id=t.tenant_id,
                store_id=t.from_store_id,
                product_id=ln.product_id,
                qty_delta=-float(ln.qty),
                reason="transferOut",
                ref_type="transfer",
                ref_id=t.id,
            )
            db.add(mvt)
            await _apply_movement(db, mvt)
    elif payload.status == "received":
        t.received_at = now
        for ln in t.lines:
            qty = float(ln.received_qty if ln.received_qty is not None else ln.qty)
            mvt = InventoryMovement(
                tenant_id=t.tenant_id,
                store_id=t.to_store_id,
                product_id=ln.product_id,
                qty_delta=qty,
                reason="transferIn",
                ref_type="transfer",
                ref_id=t.id,
            )
            db.add(mvt)
            await _apply_movement(db, mvt)
    await audit(db, scope, action="transfer_update", resource_type="transfer_order",
                resource_id=tid, extra={"status": payload.status}, flush=False)
    await db.commit()
    await db.refresh(t)
    return t


@router.post("/stocktakes", response_model=StocktakeRead, status_code=201)
async def create_stocktake(
    payload: StocktakeCreate, db: DbSession, scope: StoreAdminDep
):
    target_store = _resolve_store_id(scope, payload.store_id)
    await _ensure_store_in_tenant(db, scope, target_store)
    s = Stocktake(
        id=payload.id, tenant_id=scope.tenant_id, store_id=target_store, note=payload.note
    )
    db.add(s)
    await db.flush()
    for ln in payload.lines:
        db.add(
            StocktakeLine(
                id=ln.id,
                stocktake_id=s.id,
                product_id=ln.product_id,
                expected_qty=ln.expected_qty,
                actual_qty=ln.actual_qty,
            )
        )
        diff = ln.actual_qty - ln.expected_qty
        if diff != 0:
            mvt = InventoryMovement(
                tenant_id=scope.tenant_id,
                store_id=s.store_id,
                product_id=ln.product_id,
                qty_delta=diff,
                reason="adjustment",
                ref_type="stocktake",
                ref_id=s.id,
            )
            db.add(mvt)
            await _apply_movement(db, mvt)
    s.completed_at = datetime.now(timezone.utc)
    await audit(db, scope, action="stocktake_complete", resource_type="stocktake",
                resource_id=s.id, flush=False)
    await db.commit()
    await db.refresh(s)
    return s
