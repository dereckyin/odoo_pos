from datetime import datetime, timezone

from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy import func, select

from ...core.deps import CurrentUserDep, DbSession
from ...models import Member, Order, Product, Promotion

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


class DashboardStats(BaseModel):
    products: int
    active_promotions: int
    members: int
    today_orders: int
    today_revenue_cents: int


@router.get("/stats", response_model=DashboardStats)
async def get_stats(db: DbSession, _: CurrentUserDep) -> DashboardStats:
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

    products_count = (await db.execute(
        select(func.count(Product.id)).where(Product.deleted_at.is_(None), Product.is_active.is_(True))
    )).scalar() or 0

    promo_stmt = select(func.count(Promotion.id)).where(
        Promotion.deleted_at.is_(None),
        Promotion.is_active.is_(True),
        (Promotion.starts_at.is_(None)) | (Promotion.starts_at <= now),
        (Promotion.ends_at.is_(None)) | (Promotion.ends_at >= now),
    )
    active_promotions = (await db.execute(promo_stmt)).scalar() or 0

    members_count = (await db.execute(
        select(func.count(Member.id)).where(Member.deleted_at.is_(None))
    )).scalar() or 0

    today_orders_row = (await db.execute(
        select(
            func.count(Order.id),
            func.coalesce(func.sum(Order.total_cents), 0),
        ).where(Order.status == "paid", Order.created_at >= today_start)
    )).one()

    return DashboardStats(
        products=products_count,
        active_promotions=active_promotions,
        members=members_count,
        today_orders=today_orders_row[0],
        today_revenue_cents=int(today_orders_row[1]),
    )
