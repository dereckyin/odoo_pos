from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from ...core.deps import AdminDep, CurrentUserDep, DbSession
from ...models import Store, Terminal
from ...schemas.store import StoreCreate, StoreRead, StoreUpdate, TerminalRead

router = APIRouter(prefix="/stores", tags=["stores"])


@router.get("", response_model=list[StoreRead])
async def list_stores(db: DbSession, _: CurrentUserDep):
    rows = (await db.execute(select(Store).where(Store.deleted_at.is_(None)))).scalars().all()
    return rows


@router.post("", response_model=StoreRead, status_code=201)
async def create_store(payload: StoreCreate, db: DbSession, _: AdminDep):
    s = Store(**payload.model_dump())
    db.add(s)
    await db.commit()
    await db.refresh(s)
    return s


@router.get("/{store_id}", response_model=StoreRead)
async def get_store(store_id: str, db: DbSession, _: CurrentUserDep):
    s = await db.get(Store, store_id)
    if not s or s.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return s


@router.patch("/{store_id}", response_model=StoreRead)
async def update_store(store_id: str, payload: StoreUpdate, db: DbSession, _: AdminDep):
    s = await db.get(Store, store_id)
    if not s or s.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(s, k, v)
    await db.commit()
    await db.refresh(s)
    return s


@router.delete("/{store_id}", status_code=204)
async def delete_store(store_id: str, db: DbSession, _: AdminDep):
    s = await db.get(Store, store_id)
    if not s:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    s.deleted_at = datetime.now(timezone.utc)
    await db.commit()


@router.get("/{store_id}/terminals", response_model=list[TerminalRead])
async def list_terminals(store_id: str, db: DbSession, _: CurrentUserDep):
    rows = (
        await db.execute(select(Terminal).where(Terminal.store_id == store_id, Terminal.deleted_at.is_(None)))
    ).scalars().all()
    return rows
