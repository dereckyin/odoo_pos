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
from ...models import Promotion
from ...schemas.promotion import PromotionCreate, PromotionRead, PromotionUpdate

router = APIRouter(prefix="/promotions", tags=["promotions"])


@router.get("", response_model=list[PromotionRead])
async def list_promotions(
    db: DbSession, scope: TenantScope, active_only: bool = False
):
    stmt = apply_tenant(
        select(Promotion).where(Promotion.deleted_at.is_(None)), Promotion, scope
    )
    if active_only:
        now = datetime.now(timezone.utc)
        stmt = stmt.where(
            Promotion.is_active.is_(True),
            (Promotion.starts_at.is_(None)) | (Promotion.starts_at <= now),
            (Promotion.ends_at.is_(None)) | (Promotion.ends_at >= now),
        )
    stmt = stmt.order_by(Promotion.priority.desc())
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.get("/{pid}", response_model=PromotionRead)
async def get_promotion(pid: str, db: DbSession, scope: TenantScope):
    p = await db.get(Promotion, pid)
    if not p or p.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, p)
    return p


@router.post("", response_model=PromotionRead, status_code=201)
async def create_promotion(
    payload: PromotionCreate, db: DbSession, scope: StoreAdminDep
):
    p = Promotion(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(p)
    await audit(db, scope, action="promotion_create", resource_type="promotion",
                flush=False)
    await db.commit()
    await db.refresh(p)
    return p


@router.patch("/{pid}", response_model=PromotionRead)
async def update_promotion(
    pid: str, payload: PromotionUpdate, db: DbSession, scope: StoreAdminDep
):
    p = await db.get(Promotion, pid)
    if not p or p.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, p)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(p, k, v)
    await audit(db, scope, action="promotion_update", resource_type="promotion",
                resource_id=pid, flush=False)
    await db.commit()
    await db.refresh(p)
    return p


@router.delete("/{pid}", status_code=204)
async def delete_promotion(pid: str, db: DbSession, scope: StoreAdminDep):
    p = await db.get(Promotion, pid)
    if not p:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, p)
    p.deleted_at = datetime.now(timezone.utc)
    await audit(db, scope, action="promotion_delete", resource_type="promotion",
                resource_id=pid, flush=False)
    await db.commit()
