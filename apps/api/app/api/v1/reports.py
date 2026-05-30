from datetime import datetime

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import case, func, select

from ...core.deps import DbSession, TenantScope
from ...models import Category, Order, OrderLine, Payment, Product, Tenant
from ...services.business_time import tenant_timezone
from ...services.reporting import (
    SALE_STATUSES,
    apply_date_range,
    business_ts,
    net_revenue_expr,
    prior_period,
)

router = APIRouter(prefix="/reports", tags=["reports"])


class SalesSummary(BaseModel):
    total_revenue_cents: int
    net_revenue_cents: int
    total_orders: int
    avg_order_cents: int
    refund_cents: int
    refund_rate: float
    qr_order_count: int
    qr_ratio: float
    prior_revenue_cents: int | None = None
    prior_order_count: int | None = None
    revenue_change_pct: float | None = None


class DailyPoint(BaseModel):
    date: str
    revenue_cents: int
    net_cents: int
    order_count: int


class HeatmapCell(BaseModel):
    weekday: int
    hour: int
    order_count: int
    revenue_cents: int


class PaymentMixItem(BaseModel):
    method: str
    count: int
    amount_cents: int


class TopProduct(BaseModel):
    product_id: str
    product_name: str
    sku: str
    total_qty: float
    total_revenue_cents: int


class CategoryMixItem(BaseModel):
    category_id: str | None
    category_name: str
    revenue_cents: int
    qty: float


def _date_bucket(db_bind, tz_name: str):
    ts = business_ts()
    if db_bind.dialect.name == "postgresql":
        return func.date(func.timezone(tz_name, ts))
    return func.date(ts)


async def _summary_for_period(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None,
    until: datetime | None,
    store_id: str | None,
) -> tuple[int, int, int, int, int]:
    stmt = select(
        func.coalesce(func.sum(Order.total_cents), 0),
        func.coalesce(func.sum(net_revenue_expr()), 0),
        func.count(Order.id),
        func.coalesce(func.sum(Order.refunded_cents), 0),
        func.coalesce(
            func.sum(case((Order.source_guest_order_id.isnot(None), 1), else_=0)), 0
        ),
    ).where(Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES))
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    stmt = apply_date_range(stmt, since, until)
    row = (await db.execute(stmt)).one()
    return int(row[0]), int(row[1]), int(row[2]), int(row[3]), int(row[4])


@router.get("/sales-summary", response_model=SalesSummary)
async def sales_summary(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
    compare_prior: bool = False,
) -> SalesSummary:
    gross, net, cnt, refund, qr_cnt = await _summary_for_period(
        db, scope, since, until, store_id
    )
    prior_gross_val: int | None = None
    prior_cnt_val: int | None = None
    change_pct: float | None = None
    if compare_prior and since and until:
        ps, pu = prior_period(since, until)
        prior_gross, _, prior_cnt, _, _ = await _summary_for_period(
            db, scope, ps, pu, store_id
        )
        prior_gross_val = prior_gross
        prior_cnt_val = prior_cnt
        if prior_gross:
            change_pct = round((gross - prior_gross) / prior_gross * 100, 1)

    return SalesSummary(
        total_revenue_cents=gross,
        net_revenue_cents=net,
        total_orders=cnt,
        avg_order_cents=gross // cnt if cnt else 0,
        refund_cents=refund,
        refund_rate=round(refund / gross * 100, 2) if gross else 0.0,
        qr_order_count=qr_cnt,
        qr_ratio=round(qr_cnt / cnt * 100, 1) if cnt else 0.0,
        prior_revenue_cents=prior_gross_val,
        prior_order_count=prior_cnt_val,
        revenue_change_pct=change_pct,
    )


@router.get("/daily-series", response_model=list[DailyPoint])
async def daily_series(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> list[DailyPoint]:
    tenant = await db.get(Tenant, scope.tenant_id) if scope.tenant_id else None
    tz_name = str(tenant_timezone(tenant.settings if tenant else None))

    day_col = _date_bucket(db.bind, tz_name)
    stmt = (
        select(
            day_col.label("d"),
            func.coalesce(func.sum(Order.total_cents), 0),
            func.coalesce(func.sum(net_revenue_expr()), 0),
            func.count(Order.id),
        )
        .where(Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES))
    )
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    stmt = apply_date_range(stmt, since, until)
    stmt = stmt.group_by(day_col).order_by(day_col)

    rows = (await db.execute(stmt)).all()
    return [
        DailyPoint(
            date=str(r.d),
            revenue_cents=int(r[1]),
            net_cents=int(r[2]),
            order_count=int(r[3]),
        )
        for r in rows
    ]


@router.get("/hourly-heatmap", response_model=list[HeatmapCell])
async def hourly_heatmap(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> list[HeatmapCell]:
    tenant = await db.get(Tenant, scope.tenant_id) if scope.tenant_id else None
    tz_name = str(tenant_timezone(tenant.settings if tenant else None))
    ts = business_ts()
    if db.bind.dialect.name == "postgresql":
        local_ts = func.timezone(tz_name, ts)
        weekday = func.extract("dow", local_ts)
        hour = func.extract("hour", local_ts)
    else:
        weekday = func.strftime("%w", ts)
        hour = func.strftime("%H", ts)

    stmt = select(
        weekday.label("wd"),
        hour.label("hr"),
        func.count(Order.id),
        func.coalesce(func.sum(Order.total_cents), 0),
    ).where(Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES))
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    stmt = apply_date_range(stmt, since, until)
    stmt = stmt.group_by(weekday, hour)

    rows = (await db.execute(stmt)).all()
    result = []
    for r in rows:
        wd = int(float(r.wd))
        # PG dow: 0=Sun; normalize to 0=Mon
        if db.bind.dialect.name == "postgresql":
            wd = (wd + 6) % 7
        else:
            wd = (int(r.wd) + 6) % 7
        result.append(
            HeatmapCell(
                weekday=wd,
                hour=int(float(r.hr)),
                order_count=int(r[2]),
                revenue_cents=int(r[3]),
            )
        )
    return result


@router.get("/payment-mix", response_model=list[PaymentMixItem])
async def payment_mix(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> list[PaymentMixItem]:
    stmt = (
        select(
            Payment.method,
            func.count(Payment.id),
            func.coalesce(func.sum(Payment.amount_cents), 0),
        )
        .join(Order, Order.id == Payment.order_id)
        .where(Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES))
    )
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    stmt = apply_date_range(stmt, since, until)
    stmt = stmt.group_by(Payment.method).order_by(func.sum(Payment.amount_cents).desc())
    rows = (await db.execute(stmt)).all()
    return [
        PaymentMixItem(method=r[0], count=int(r[1]), amount_cents=int(r[2]))
        for r in rows
    ]


@router.get("/top-products", response_model=list[TopProduct])
async def top_products(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
    limit: int = Query(20, le=100),
) -> list[TopProduct]:
    if scope.tenant_id is None and not scope.is_platform_super:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "tenant required")
    base = (
        select(
            OrderLine.product_id,
            OrderLine.product_name,
            OrderLine.sku,
            func.sum(OrderLine.qty).label("total_qty"),
            func.sum(OrderLine.line_total_cents).label("total_revenue_cents"),
        )
        .join(Order, Order.id == OrderLine.order_id)
        .where(Order.status.in_(SALE_STATUSES), Order.tenant_id == scope.tenant_id)
        .group_by(OrderLine.product_id, OrderLine.product_name, OrderLine.sku)
        .order_by(func.sum(OrderLine.line_total_cents).desc())
        .limit(limit)
    )
    if scope.store_id and not scope.is_tenant_admin:
        base = base.where(Order.store_id == scope.store_id)
    elif store_id:
        base = base.where(Order.store_id == store_id)
    if since:
        base = base.where(business_ts() >= since)
    if until:
        base = base.where(business_ts() <= until)

    rows = (await db.execute(base)).all()
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


@router.get("/category-mix", response_model=list[CategoryMixItem])
async def category_mix(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> list[CategoryMixItem]:
    stmt = (
        select(
            Product.category_id,
            Category.name,
            func.coalesce(func.sum(OrderLine.line_total_cents), 0),
            func.coalesce(func.sum(OrderLine.qty), 0),
        )
        .join(Product, Product.id == OrderLine.product_id)
        .join(Order, Order.id == OrderLine.order_id)
        .outerjoin(Category, Category.id == Product.category_id)
        .where(Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES))
        .group_by(Product.category_id, Category.name)
        .order_by(func.sum(OrderLine.line_total_cents).desc())
    )
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    if since:
        stmt = stmt.where(business_ts() >= since)
    if until:
        stmt = stmt.where(business_ts() <= until)

    rows = (await db.execute(stmt)).all()
    return [
        CategoryMixItem(
            category_id=r[0],
            category_name=r[1] or "未分類",
            revenue_cents=int(r[2]),
            qty=float(r[3]),
        )
        for r in rows
    ]
