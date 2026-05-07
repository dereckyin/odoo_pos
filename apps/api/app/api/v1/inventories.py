from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.deps import AdminDep, CurrentUserDep, DbSession
from ...models import (
    InventoryLevel,
    InventoryMovement,
    Stocktake,
    StocktakeLine,
    TransferLine,
    TransferOrder,
)
from ...schemas.inventory import (
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

router = APIRouter(prefix="/inventory", tags=["inventory"])


async def _apply_movement(db, m: InventoryMovement) -> None:
    """Apply a movement to canonical inventory levels."""
    level = (
        await db.execute(
            select(InventoryLevel).where(
                InventoryLevel.store_id == m.store_id, InventoryLevel.product_id == m.product_id
            )
        )
    ).scalar_one_or_none()
    if level is None:
        level = InventoryLevel(
            store_id=m.store_id, product_id=m.product_id, on_hand=m.qty_delta
        )
        db.add(level)
    else:
        level.on_hand = float(level.on_hand) + float(m.qty_delta)


@router.get("/levels", response_model=list[InventoryLevelRead])
async def list_levels(db: DbSession, _: CurrentUserDep, store_id: str | None = None):
    stmt = select(InventoryLevel)
    if store_id:
        stmt = stmt.where(InventoryLevel.store_id == store_id)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.patch("/levels/{level_id}", response_model=InventoryLevelRead)
async def update_level(level_id: str, payload: InventoryLevelUpdate, db: DbSession, _: AdminDep):
    lvl = await db.get(InventoryLevel, level_id)
    if not lvl:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(lvl, k, v)
    await db.commit()
    await db.refresh(lvl)
    return lvl


@router.post("/movements", response_model=MovementRead, status_code=201)
async def record_movement(payload: MovementCreate, db: DbSession, _: CurrentUserDep):
    existing = await db.get(InventoryMovement, payload.id)
    if existing:
        return existing
    m = InventoryMovement(**payload.model_dump())
    db.add(m)
    await _apply_movement(db, m)
    await db.commit()
    await db.refresh(m)
    return m


@router.post("/movements/batch", response_model=list[MovementRead], status_code=201)
async def record_movements(payload: list[MovementCreate], db: DbSession, _: CurrentUserDep):
    results: list[InventoryMovement] = []
    for item in payload:
        existing = await db.get(InventoryMovement, item.id)
        if existing:
            results.append(existing)
            continue
        m = InventoryMovement(**item.model_dump())
        db.add(m)
        await _apply_movement(db, m)
        results.append(m)
    await db.commit()
    for r in results:
        await db.refresh(r)
    return results


@router.post("/transfers", response_model=TransferRead, status_code=201)
async def create_transfer(payload: TransferCreate, db: DbSession, _: CurrentUserDep):
    t = TransferOrder(
        id=payload.id,
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
    await db.commit()
    await db.refresh(t)
    return t


@router.patch("/transfers/{tid}", response_model=TransferRead)
async def update_transfer(tid: str, payload: TransferUpdate, db: DbSession, _: CurrentUserDep):
    t = (
        await db.execute(
            select(TransferOrder).where(TransferOrder.id == tid).options(selectinload(TransferOrder.lines))
        )
    ).scalar_one_or_none()
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    t.status = payload.status
    now = datetime.now(timezone.utc)
    if payload.status == "dispatched":
        t.dispatched_at = now
        for ln in t.lines:
            mvt = InventoryMovement(
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
                store_id=t.to_store_id,
                product_id=ln.product_id,
                qty_delta=qty,
                reason="transferIn",
                ref_type="transfer",
                ref_id=t.id,
            )
            db.add(mvt)
            await _apply_movement(db, mvt)
    await db.commit()
    await db.refresh(t)
    return t


@router.post("/stocktakes", response_model=StocktakeRead, status_code=201)
async def create_stocktake(payload: StocktakeCreate, db: DbSession, _: CurrentUserDep):
    s = Stocktake(id=payload.id, store_id=payload.store_id, note=payload.note)
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
    await db.commit()
    await db.refresh(s)
    return s
