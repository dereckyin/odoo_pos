from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from ...core.deps import CurrentUserDep, DbSession
from ...models import Coupon
from ...schemas.member import CouponCreate, CouponRead

router = APIRouter(prefix="/coupons", tags=["coupons"])


@router.get("", response_model=list[CouponRead])
async def list_coupons(db: DbSession, _: CurrentUserDep, member_id: str | None = None):
    stmt = select(Coupon).where(Coupon.deleted_at.is_(None))
    if member_id:
        stmt = stmt.where(Coupon.member_id == member_id)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.post("", response_model=CouponRead, status_code=201)
async def create_coupon(payload: CouponCreate, db: DbSession, _: CurrentUserDep):
    c = Coupon(**payload.model_dump())
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return c


@router.post("/{code}/redeem", response_model=CouponRead)
async def redeem_coupon(code: str, db: DbSession, _: CurrentUserDep, order_id: str):
    c = (await db.execute(select(Coupon).where(Coupon.code == code))).scalar_one_or_none()
    if not c:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if c.used_at:
        raise HTTPException(status.HTTP_409_CONFLICT, "coupon already used")
    c.used_at = datetime.now(timezone.utc)
    c.used_in_order_id = order_id
    await db.commit()
    await db.refresh(c)
    return c
