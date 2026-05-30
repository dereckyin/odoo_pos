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
from ...schemas.product import CategoryCreate, CategoryRead, CategoryTreeNode, CategoryUpdate
from ...services.category_tree import (
    CategoryTreeError,
    build_tree,
    enrich_category_read,
    load_tenant_categories,
    validate_category_parent,
    assert_category_deletable,
    build_category_maps,
    category_to_read,
)

router = APIRouter(prefix="/categories", tags=["categories"])


async def _list_flat(db: DbSession, scope: TenantScope) -> list[CategoryRead]:
    cats = await load_tenant_categories(db, scope.tenant_id)
    by_id, children_map = build_category_maps(cats)
    rows = list(by_id.values())
    rows.sort(key=lambda r: (r.sort_order, r.name))
    return [category_to_read(r, by_id, children_map) for r in rows]


@router.get("", response_model=list[CategoryRead])
async def list_categories(db: DbSession, scope: TenantScope):
    return await _list_flat(db, scope)


@router.get("/tree", response_model=list[CategoryTreeNode])
async def list_categories_tree(db: DbSession, scope: TenantScope):
    cats = await load_tenant_categories(db, scope.tenant_id)
    return build_tree(cats)


@router.post("", response_model=CategoryRead, status_code=201)
async def create_category(payload: CategoryCreate, db: DbSession, scope: StoreAdminDep):
    try:
        await validate_category_parent(db, scope.tenant_id, None, payload.parent_id)
    except CategoryTreeError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
    c = Category(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(c)
    await db.flush()
    await audit(db, scope, action="category_create", resource_type="category", flush=False)
    await db.commit()
    await db.refresh(c)
    return await enrich_category_read(db, c)


@router.patch("/{cid}", response_model=CategoryRead)
async def update_category(
    cid: str, payload: CategoryUpdate, db: DbSession, scope: StoreAdminDep
):
    c = await db.get(Category, cid)
    if not c or c.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, c)
    data = payload.model_dump(exclude_unset=True)
    new_parent = data.get("parent_id", c.parent_id)
    try:
        await validate_category_parent(db, scope.tenant_id, c.id, new_parent)
    except CategoryTreeError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
    for k, v in data.items():
        setattr(c, k, v)
    await audit(
        db, scope, action="category_update", resource_type="category",
        resource_id=cid, flush=False,
    )
    await db.commit()
    await db.refresh(c)
    return await enrich_category_read(db, c)


@router.delete("/{cid}", status_code=204)
async def delete_category(cid: str, db: DbSession, scope: StoreAdminDep):
    c = await db.get(Category, cid)
    if not c:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, c)
    try:
        await assert_category_deletable(db, c)
    except CategoryTreeError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
    c.deleted_at = datetime.now(timezone.utc)
    await audit(
        db, scope, action="category_delete", resource_type="category",
        resource_id=cid, flush=False,
    )
    await db.commit()
