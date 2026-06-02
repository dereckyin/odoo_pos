"""Admin / staff endpoints for managing dining tables.

Tables hold the ``public_token`` printed onto the QR code on each physical
table tent. Tokens are kept opaque and high-entropy; rotating a token
effectively invalidates any previously printed QR for that table.
"""
import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    StoreAdminDep,
    TenantScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...models import DiningTable, Store
from ...schemas.dining_table import (
    DiningTableCreate,
    DiningTableRead,
    DiningTableTokenResponse,
    DiningTableUpdate,
)
from ...services.tenant_modules import require_online_ordering

router = APIRouter(
    prefix="/admin/tables",
    tags=["admin-tables"],
    dependencies=[Depends(require_online_ordering)],
)


def _new_token() -> str:
    return secrets.token_urlsafe(24)[:32]


@router.get("", response_model=list[DiningTableRead])
async def list_tables(
    db: DbSession,
    scope: TenantScope,
    store_id: str | None = Query(default=None),
    include_inactive: bool = Query(default=False),
):
    stmt = apply_tenant(
        select(DiningTable).where(DiningTable.deleted_at.is_(None)),
        DiningTable, scope,
    )
    target_store = store_id or scope.store_id
    if target_store:
        stmt = stmt.where(DiningTable.store_id == target_store)
    if not include_inactive:
        stmt = stmt.where(DiningTable.is_active.is_(True))
    stmt = stmt.order_by(DiningTable.label)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.post("", response_model=DiningTableRead, status_code=201)
async def create_table(
    payload: DiningTableCreate, db: DbSession, scope: StoreAdminDep
):
    target_store = payload.store_id or scope.store_id
    if not target_store:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "store_id required")
    store = await db.get(Store, target_store)
    if not store or store.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    ensure_same_tenant(scope, store)

    dup = (
        await db.execute(
            select(DiningTable).where(
                DiningTable.store_id == target_store,
                DiningTable.label == payload.label,
                DiningTable.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if dup:
        raise HTTPException(status.HTTP_409_CONFLICT, "label already used in this store")

    t = DiningTable(
        tenant_id=scope.tenant_id,
        store_id=target_store,
        label=payload.label,
        seats=payload.seats,
        is_active=payload.is_active,
        note=payload.note,
        public_token=_new_token(),
    )
    db.add(t)
    await audit(db, scope, action="dining_table_create", resource_type="dining_table",
                flush=False)
    await db.commit()
    await db.refresh(t)
    return t


@router.get("/{tid}", response_model=DiningTableRead)
async def get_table(tid: str, db: DbSession, scope: TenantScope):
    t = await db.get(DiningTable, tid)
    if not t or t.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, t)
    return t


@router.patch("/{tid}", response_model=DiningTableRead)
async def update_table(
    tid: str, payload: DiningTableUpdate, db: DbSession, scope: StoreAdminDep
):
    t = await db.get(DiningTable, tid)
    if not t or t.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, t)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(t, k, v)
    await audit(db, scope, action="dining_table_update", resource_type="dining_table",
                resource_id=tid, flush=False)
    await db.commit()
    await db.refresh(t)
    return t


@router.delete("/{tid}", status_code=204)
async def delete_table(tid: str, db: DbSession, scope: StoreAdminDep):
    t = await db.get(DiningTable, tid)
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, t)
    t.deleted_at = datetime.now(timezone.utc)
    await audit(db, scope, action="dining_table_delete", resource_type="dining_table",
                resource_id=tid, flush=False)
    await db.commit()


@router.post("/{tid}/rotate-token", response_model=DiningTableTokenResponse)
async def rotate_token(tid: str, db: DbSession, scope: StoreAdminDep):
    t = await db.get(DiningTable, tid)
    if not t or t.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, t)
    t.public_token = _new_token()
    await audit(db, scope, action="dining_table_rotate_token", resource_type="dining_table",
                resource_id=tid, flush=False)
    await db.commit()
    await db.refresh(t)
    return DiningTableTokenResponse(id=t.id, public_token=t.public_token)
