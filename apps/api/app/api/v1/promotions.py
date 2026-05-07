from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from ...core.deps import AdminDep, CurrentUserDep, DbSession
from ...models import Promotion
from ...schemas.promotion import PromotionCreate, PromotionRead, PromotionUpdate

router = APIRouter(prefix="/promotions", tags=["promotions"])


@router.get("", response_model=list[PromotionRead])
async def list_promotions(db: DbSession, _: CurrentUserDep, active_only: bool = False):
    stmt = select(Promotion).where(Promotion.deleted_at.is_(None))
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
async def get_promotion(pid: str, db: DbSession, _: CurrentUserDep):
    p = await db.get(Promotion, pid)
    if not p or p.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return p


@router.post("", response_model=PromotionRead, status_code=201)
async def create_promotion(payload: PromotionCreate, db: DbSession, _: AdminDep):
    p = Promotion(**payload.model_dump())
    db.add(p)
    await db.commit()
    await db.refresh(p)
    return p


@router.patch("/{pid}", response_model=PromotionRead)
async def update_promotion(pid: str, payload: PromotionUpdate, db: DbSession, _: AdminDep):
    p = await db.get(Promotion, pid)
    if not p or p.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(p, k, v)
    await db.commit()
    await db.refresh(p)
    return p


@router.delete("/{pid}", status_code=204)
async def delete_promotion(pid: str, db: DbSession, _: AdminDep):
    p = await db.get(Promotion, pid)
    if not p:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    p.deleted_at = datetime.now(timezone.utc)
    await db.commit()
