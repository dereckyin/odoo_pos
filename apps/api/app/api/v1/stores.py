from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    StoreAdminDep,
    TenantAdminDep,
    TenantScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...core.usage import assert_can_add_store
from ...models import Store, Terminal
from ...schemas.store import StoreCreate, StoreRead, StoreUpdate, TerminalRead
from ...services.geocoding import geocode_store_rate_limited
from ...services.online_ordering import normalize_online_ordering_patch

router = APIRouter(prefix="/stores", tags=["stores"])


@router.get("", response_model=list[StoreRead])
async def list_stores(db: DbSession, scope: TenantScope):
    rows = (
        await db.execute(
            apply_tenant(select(Store).where(Store.deleted_at.is_(None)), Store, scope)
        )
    ).scalars().all()
    return rows


@router.post("", response_model=StoreRead, status_code=201)
async def create_store(payload: StoreCreate, db: DbSession, scope: TenantAdminDep):
    await assert_can_add_store(db, scope.tenant_id)
    data = payload.model_dump()
    oo = data.pop("online_ordering_json", None)
    if oo is not None:
        data["online_ordering_json"] = normalize_online_ordering_patch(oo)
    s = Store(tenant_id=scope.tenant_id, **data)
    db.add(s)
    await audit(db, scope, action="store_create", resource_type="store", flush=False)
    await db.commit()
    await db.refresh(s)
    return s


@router.get("/{store_id}", response_model=StoreRead)
async def get_store(store_id: str, db: DbSession, scope: TenantScope):
    s = await db.get(Store, store_id)
    if not s or s.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, s)
    return s


@router.patch("/{store_id}", response_model=StoreRead)
async def update_store(
    store_id: str, payload: StoreUpdate, db: DbSession, scope: TenantAdminDep
):
    s = await db.get(Store, store_id)
    if not s or s.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, s)
    data = payload.model_dump(exclude_unset=True)
    if "online_ordering_json" in data:
        oo = data["online_ordering_json"]
        data["online_ordering_json"] = (
            normalize_online_ordering_patch(oo) if oo is not None else None
        )
    for k, v in data.items():
        setattr(s, k, v)
    await audit(db, scope, action="store_update", resource_type="store",
                resource_id=store_id, flush=False)
    await db.commit()
    await db.refresh(s)
    return s


@router.delete("/{store_id}", status_code=204)
async def delete_store(store_id: str, db: DbSession, scope: TenantAdminDep):
    s = await db.get(Store, store_id)
    if not s:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, s)
    s.deleted_at = datetime.now(timezone.utc)
    await audit(db, scope, action="store_delete", resource_type="store",
                resource_id=store_id, flush=False)
    await db.commit()


@router.post("/{store_id}/geocode", response_model=StoreRead)
async def geocode_store_endpoint(store_id: str, db: DbSession, scope: TenantAdminDep):
    s = await db.get(Store, store_id)
    if not s or s.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, s)
    try:
        await geocode_store_rate_limited(db, s)
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e
    await db.commit()
    await db.refresh(s)
    return s


@router.get("/{store_id}/terminals", response_model=list[TerminalRead])
async def list_terminals(store_id: str, db: DbSession, scope: TenantScope):
    s = await db.get(Store, store_id)
    if not s:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, s)
    rows = (
        await db.execute(
            select(Terminal).where(
                Terminal.store_id == store_id, Terminal.deleted_at.is_(None)
            )
        )
    ).scalars().all()
    return rows
