from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from ...core.deps import AdminDep, CurrentUserDep, DbSession
from ...models import Category
from ...schemas.product import CategoryCreate, CategoryRead, CategoryUpdate

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryRead])
async def list_categories(db: DbSession, _: CurrentUserDep):
    rows = (
        await db.execute(
            select(Category).where(Category.deleted_at.is_(None)).order_by(Category.sort_order)
        )
    ).scalars().all()
    return rows


@router.post("", response_model=CategoryRead, status_code=201)
async def create_category(payload: CategoryCreate, db: DbSession, _: AdminDep):
    c = Category(**payload.model_dump())
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return c


@router.patch("/{cid}", response_model=CategoryRead)
async def update_category(cid: str, payload: CategoryUpdate, db: DbSession, _: AdminDep):
    c = await db.get(Category, cid)
    if not c or c.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(c, k, v)
    await db.commit()
    await db.refresh(c)
    return c


@router.delete("/{cid}", status_code=204)
async def delete_category(cid: str, db: DbSession, _: AdminDep):
    c = await db.get(Category, cid)
    if not c:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    c.deleted_at = datetime.now(timezone.utc)
    await db.commit()
