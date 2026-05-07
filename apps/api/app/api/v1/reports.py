from datetime import datetime

from fastapi import APIRouter, Query
from pydantic import BaseModel
from sqlalchemy import func, select

from ...core.deps import AdminDep, DbSession
from ...models import Order, OrderLine

router = APIRouter(prefix="/reports", tags=["reports"])


class SalesSummary(BaseModel):
    total_revenue_cents: int
    total_orders: int
    avg_order_cents: int


class TopProduct(BaseModel):
    product_id: str
    product_name: str
    sku: str
    total_qty: float
    total_revenue_cents: int


@router.get("/sales-summary", response_model=SalesSummary)
async def sales_summary(
    db: DbSession,
    _: AdminDep,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> SalesSummary:
    stmt = select(
        func.coalesce(func.sum(Order.total_cents), 0).label("revenue"),
        func.count(Order.id).label("cnt"),
    ).where(Order.status == "paid")

    if since:
        stmt = stmt.where(Order.created_at >= since)
    if until:
        stmt = stmt.where(Order.created_at <= until)
    if store_id:
        stmt = stmt.where(Order.store_id == store_id)

    row = (await db.execute(stmt)).one()
    revenue = int(row.revenue)
    cnt = int(row.cnt)
    return SalesSummary(
        total_revenue_cents=revenue,
        total_orders=cnt,
        avg_order_cents=revenue // cnt if cnt else 0,
    )


@router.get("/top-products", response_model=list[TopProduct])
async def top_products(
    db: DbSession,
    _: AdminDep,
    since: datetime | None = None,
    until: datetime | None = None,
    limit: int = Query(20, le=100),
) -> list[TopProduct]:
    stmt = (
        select(
            OrderLine.product_id,
            OrderLine.product_name,
            OrderLine.sku,
            func.sum(OrderLine.qty).label("total_qty"),
            func.sum(OrderLine.line_total_cents).label("total_revenue_cents"),
        )
        .join(Order, Order.id == OrderLine.order_id)
        .where(Order.status == "paid")
        .group_by(OrderLine.product_id, OrderLine.product_name, OrderLine.sku)
        .order_by(func.sum(OrderLine.line_total_cents).desc())
        .limit(limit)
    )

    if since:
        stmt = stmt.where(Order.created_at >= since)
    if until:
        stmt = stmt.where(Order.created_at <= until)

    rows = (await db.execute(stmt)).all()
    return [
        TopProduct(
            product_id=r.product_id,
            product_name=r.product_name,
            sku=r.sku,
            total_qty=float(r.total_qty),
            total_revenue_cents=int(r.total_revenue_cents),
        )
        for r in rows
    ]
