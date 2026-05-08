"""Admin / staff endpoints for managing dining tables.

Tables hold the ``public_token`` printed onto the QR code on each physical
table tent. Tokens are kept opaque and high-entropy; rotating a token
effectively invalidates any previously printed QR for that table.
"""
import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from ...core.deps import AdminDep, CurrentUserDep, DbSession
from ...models import DiningTable, Store
from ...schemas.dining_table import (
    DiningTableCreate,
    DiningTableRead,
    DiningTableTokenResponse,
    DiningTableUpdate,
)

router = APIRouter(prefix="/admin/tables", tags=["admin-tables"])


def _new_token() -> str:
    """Return a 32-char URL-safe random token (collision-resistant enough for
    this scale; uniqueness is also enforced by a UNIQUE index)."""
    return secrets.token_urlsafe(24)[:32]


@router.get("", response_model=list[DiningTableRead])
async def list_tables(
    db: DbSession,
    _: CurrentUserDep,
    store_id: str | None = Query(default=None),
    include_inactive: bool = Query(default=False),
):
    stmt = select(DiningTable).where(DiningTable.deleted_at.is_(None))
    if store_id:
        stmt = stmt.where(DiningTable.store_id == store_id)
    if not include_inactive:
        stmt = stmt.where(DiningTable.is_active.is_(True))
    stmt = stmt.order_by(DiningTable.label)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.post("", response_model=DiningTableRead, status_code=201)
async def create_table(payload: DiningTableCreate, db: DbSession, _: AdminDep):
    store = await db.get(Store, payload.store_id)
    if not store or store.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")

    # Reject duplicate label within the same active store.
    dup = (
        await db.execute(
            select(DiningTable).where(
                DiningTable.store_id == payload.store_id,
                DiningTable.label == payload.label,
                DiningTable.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if dup:
        raise HTTPException(status.HTTP_409_CONFLICT, "label already used in this store")

    t = DiningTable(public_token=_new_token(), **payload.model_dump())
    db.add(t)
    await db.commit()
    await db.refresh(t)
    return t


@router.get("/{tid}", response_model=DiningTableRead)
async def get_table(tid: str, db: DbSession, _: CurrentUserDep):
    t = await db.get(DiningTable, tid)
    if not t or t.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return t


@router.patch("/{tid}", response_model=DiningTableRead)
async def update_table(tid: str, payload: DiningTableUpdate, db: DbSession, _: AdminDep):
    t = await db.get(DiningTable, tid)
    if not t or t.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(t, k, v)
    await db.commit()
    await db.refresh(t)
    return t


@router.delete("/{tid}", status_code=204)
async def delete_table(tid: str, db: DbSession, _: AdminDep):
    t = await db.get(DiningTable, tid)
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    t.deleted_at = datetime.now(timezone.utc)
    await db.commit()


@router.post("/{tid}/rotate-token", response_model=DiningTableTokenResponse)
async def rotate_token(tid: str, db: DbSession, _: AdminDep):
    t = await db.get(DiningTable, tid)
    if not t or t.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    t.public_token = _new_token()
    await db.commit()
    await db.refresh(t)
    return DiningTableTokenResponse(id=t.id, public_token=t.public_token)
