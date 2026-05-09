from datetime import datetime, timezone

from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy import func, select

from ...core.deps import DbSession, TenantScope, apply_tenant
from ...models import Member, Order, Product, Promotion

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


class DashboardStats(BaseModel):
    products: int
    active_promotions: int
    members: int
    today_orders: int
    today_revenue_cents: int


@router.get("/stats", response_model=DashboardStats)
async def get_stats(db: DbSession, scope: TenantScope) -> DashboardStats:
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

    products_count = (await db.execute(
        apply_tenant(
            select(func.count(Product.id)).where(
                Product.deleted_at.is_(None), Product.is_active.is_(True)
            ),
            Product,
            scope,
        )
    )).scalar() or 0

    promo_stmt = apply_tenant(
        select(func.count(Promotion.id)).where(
            Promotion.deleted_at.is_(None),
            Promotion.is_active.is_(True),
            (Promotion.starts_at.is_(None)) | (Promotion.starts_at <= now),
            (Promotion.ends_at.is_(None)) | (Promotion.ends_at >= now),
        ),
        Promotion,
        scope,
    )
    active_promotions = (await db.execute(promo_stmt)).scalar() or 0

    members_count = (await db.execute(
        apply_tenant(
            select(func.count(Member.id)).where(Member.deleted_at.is_(None)),
            Member,
            scope,
        )
    )).scalar() or 0

    orders_stmt = apply_tenant(
        select(
            func.count(Order.id),
            func.coalesce(func.sum(Order.total_cents), 0),
        ).where(Order.status == "paid", Order.created_at >= today_start),
        Order,
        scope,
    )
    if scope.store_id and not scope.is_tenant_admin:
        orders_stmt = orders_stmt.where(Order.store_id == scope.store_id)
    today_orders_row = (await db.execute(orders_stmt)).one()

    return DashboardStats(
        products=products_count,
        active_promotions=active_promotions,
        members=members_count,
        today_orders=today_orders_row[0],
        today_revenue_cents=int(today_orders_row[1]),
    )
