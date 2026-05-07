from datetime import datetime, timezone
from typing import Type

from fastapi import APIRouter, Query
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.deps import CurrentUserDep, DbSession
from ...models import Category, InventoryLevel, Member, MemberLevel, Product, Promotion
from ...schemas.inventory import InventoryLevelRead
from ...schemas.member import MemberLevelRead, MemberRead
from ...schemas.product import CategoryRead, ProductRead
from ...schemas.promotion import PromotionRead
from ...schemas.sync import DeltaPage

router = APIRouter(prefix="/sync", tags=["sync"])


def _now() -> datetime:
    return datetime.now(timezone.utc)


@router.get("/health")
async def health(_: CurrentUserDep) -> dict:
    return {"ok": True, "server_time": _now().isoformat()}


async def _delta(db, model: Type, since: datetime, limit: int):
    stmt = select(model).where(model.updated_at > since).order_by(model.updated_at).limit(limit)
    if hasattr(model, "barcodes"):
        stmt = stmt.options(selectinload(model.barcodes))
    return (await db.execute(stmt)).scalars().unique().all()


@router.get("/products", response_model=DeltaPage[ProductRead])
async def sync_products(
    db: DbSession, _: CurrentUserDep,
    since: datetime = Query(default=datetime(1970, 1, 1, tzinfo=timezone.utc)),
    limit: int = Query(500, le=2000),
):
    rows = await _delta(db, Product, since, limit)
    items = [ProductRead.from_orm_with_barcodes(r) for r in rows]
    next_since = rows[-1].updated_at if rows else _now()
    return DeltaPage[ProductRead](items=items, server_time=_now(), next_since=next_since)


@router.get("/categories", response_model=DeltaPage[CategoryRead])
async def sync_categories(
    db: DbSession, _: CurrentUserDep,
    since: datetime = Query(default=datetime(1970, 1, 1, tzinfo=timezone.utc)),
    limit: int = Query(500, le=2000),
):
    rows = await _delta(db, Category, since, limit)
    items = [CategoryRead.model_validate(r) for r in rows]
    next_since = rows[-1].updated_at if rows else _now()
    return DeltaPage[CategoryRead](items=items, server_time=_now(), next_since=next_since)


@router.get("/members", response_model=DeltaPage[MemberRead])
async def sync_members(
    db: DbSession, _: CurrentUserDep,
    since: datetime = Query(default=datetime(1970, 1, 1, tzinfo=timezone.utc)),
    limit: int = Query(500, le=2000),
):
    rows = await _delta(db, Member, since, limit)
    items = [MemberRead.model_validate(r) for r in rows]
    next_since = rows[-1].updated_at if rows else _now()
    return DeltaPage[MemberRead](items=items, server_time=_now(), next_since=next_since)


@router.get("/member-levels", response_model=DeltaPage[MemberLevelRead])
async def sync_member_levels(
    db: DbSession, _: CurrentUserDep,
    since: datetime = Query(default=datetime(1970, 1, 1, tzinfo=timezone.utc)),
    limit: int = Query(500, le=2000),
):
    rows = await _delta(db, MemberLevel, since, limit)
    items = [MemberLevelRead.model_validate(r) for r in rows]
    next_since = rows[-1].updated_at if rows else _now()
    return DeltaPage[MemberLevelRead](items=items, server_time=_now(), next_since=next_since)


@router.get("/promotions", response_model=DeltaPage[PromotionRead])
async def sync_promotions(
    db: DbSession, _: CurrentUserDep,
    since: datetime = Query(default=datetime(1970, 1, 1, tzinfo=timezone.utc)),
    limit: int = Query(500, le=2000),
):
    rows = await _delta(db, Promotion, since, limit)
    items = [PromotionRead.model_validate(r) for r in rows]
    next_since = rows[-1].updated_at if rows else _now()
    return DeltaPage[PromotionRead](items=items, server_time=_now(), next_since=next_since)


@router.get("/inventory-levels", response_model=DeltaPage[InventoryLevelRead])
async def sync_inventory_levels(
    db: DbSession, _: CurrentUserDep,
    store_id: str | None = None,
    since: datetime = Query(default=datetime(1970, 1, 1, tzinfo=timezone.utc)),
    limit: int = Query(1000, le=5000),
):
    stmt = select(InventoryLevel).where(InventoryLevel.updated_at > since)
    if store_id:
        stmt = stmt.where(InventoryLevel.store_id == store_id)
    stmt = stmt.order_by(InventoryLevel.updated_at).limit(limit)
    rows = (await db.execute(stmt)).scalars().all()
    items = [InventoryLevelRead.model_validate(r) for r in rows]
    next_since = rows[-1].updated_at if rows else _now()
    return DeltaPage[InventoryLevelRead](items=items, server_time=_now(), next_since=next_since)
