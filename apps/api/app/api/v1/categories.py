from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    StoreAdminDep,
    TenantScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...models import Category
from ...schemas.product import CategoryCreate, CategoryRead, CategoryUpdate

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryRead])
async def list_categories(db: DbSession, scope: TenantScope):
    stmt = apply_tenant(
        select(Category).where(Category.deleted_at.is_(None)), Category, scope
    ).order_by(Category.sort_order)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.post("", response_model=CategoryRead, status_code=201)
async def create_category(payload: CategoryCreate, db: DbSession, scope: StoreAdminDep):
    c = Category(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(c)
    await audit(db, scope, action="category_create", resource_type="category", flush=False)
    await db.commit()
    await db.refresh(c)
    return c


@router.patch("/{cid}", response_model=CategoryRead)
async def update_category(
    cid: str, payload: CategoryUpdate, db: DbSession, scope: StoreAdminDep
):
    c = await db.get(Category, cid)
    if not c or c.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, c)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(c, k, v)
    await audit(db, scope, action="category_update", resource_type="category",
                resource_id=cid, flush=False)
    await db.commit()
    await db.refresh(c)
    return c


@router.delete("/{cid}", status_code=204)
async def delete_category(cid: str, db: DbSession, scope: StoreAdminDep):
    c = await db.get(Category, cid)
    if not c:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, c)
    c.deleted_at = datetime.now(timezone.utc)
    await audit(db, scope, action="category_delete", resource_type="category",
                resource_id=cid, flush=False)
    await db.commit()
