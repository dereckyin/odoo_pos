from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    TenantScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...models import Coupon
from ...schemas.member import CouponCreate, CouponRead
from ...services.loyalty_engine import coupon_discount_cents, preview_coupon

router = APIRouter(prefix="/coupons", tags=["coupons"])


class CouponPreviewRequest(BaseModel):
    code: str
    order_total_cents: int
    member_id: str | None = None


class CouponPreviewResponse(BaseModel):
    code: str
    type: str
    value: float
    discount_cents: int


@router.post("/preview", response_model=CouponPreviewResponse)
async def preview_coupon_endpoint(
    payload: CouponPreviewRequest, db: DbSession, scope: TenantScope
):
    """Validate a coupon and return the discount it would apply (no consumption)."""
    coupon = await preview_coupon(
        db,
        tenant_id=scope.tenant_id,
        code=payload.code,
        member_id=payload.member_id,
        order_total_cents=payload.order_total_cents,
    )
    if not coupon:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "coupon not found")
    discount = coupon_discount_cents(coupon, payload.order_total_cents)
    return CouponPreviewResponse(
        code=coupon.code,
        type=coupon.type,
        value=coupon.value,
        discount_cents=discount,
    )


@router.get("", response_model=list[CouponRead])
async def list_coupons(
    db: DbSession, scope: TenantScope, member_id: str | None = None
):
    stmt = apply_tenant(
        select(Coupon).where(Coupon.deleted_at.is_(None)), Coupon, scope
    )
    if member_id:
        stmt = stmt.where(Coupon.member_id == member_id)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.post("", response_model=CouponRead, status_code=201)
async def create_coupon(
    payload: CouponCreate, db: DbSession, scope: TenantScope
):
    c = Coupon(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(c)
    await audit(db, scope, action="coupon_create", resource_type="coupon", flush=False)
    await db.commit()
    await db.refresh(c)
    return c


@router.post("/{code}/redeem", response_model=CouponRead)
async def redeem_coupon(
    code: str, db: DbSession, scope: TenantScope, order_id: str
):
    c = (
        await db.execute(
            select(Coupon).where(
                Coupon.tenant_id == scope.tenant_id,
                Coupon.code == code,
                Coupon.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not c:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, c)
    if c.used_at:
        raise HTTPException(status.HTTP_409_CONFLICT, "coupon already used")
    now = datetime.now(timezone.utc)
    if c.expires_at and c.expires_at < now:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "coupon expired")
    c.used_at = now
    c.used_in_order_id = order_id
    await audit(db, scope, action="coupon_redeem", resource_type="coupon",
                resource_id=c.id, extra={"order_id": order_id}, flush=False)
    await db.commit()
    await db.refresh(c)
    return c
