from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import case, func, select

from ...core.deps import DbSession, TenantScope
from ...models import Order, OrderLine, Store, Tenant
from ...services.business_time import tenant_timezone
from ...services.reporting import (
    SALE_STATUSES,
    apply_date_range,
    business_ts,
    net_revenue_expr,
    prior_period,
)
from ...services.weather import fetch_daily_weather
from ...services.tenant_modules import require_business_intelligence
from .reports import _date_bucket, hourly_heatmap, sales_summary

router = APIRouter(
    prefix="/analytics",
    tags=["analytics"],
    dependencies=[Depends(require_business_intelligence)],
)


class StoreComparisonRow(BaseModel):
    store_id: str
    store_name: str
    store_code: str
    latitude: float | None
    longitude: float | None
    revenue_cents: int
    net_cents: int
    order_count: int
    avg_order_cents: int
    refund_cents: int
    refund_rate: float
    prior_revenue_cents: int | None = None
    growth_pct: float | None = None


class AovBucket(BaseModel):
    label: str
    count: int


class DiscountStats(BaseModel):
    total_discount_cents: int
    discounted_orders: int
    discount_rate_pct: float


class AddonStat(BaseModel):
    choice_name: str
    count: int
    revenue_cents: int


class InsightItem(BaseModel):
    text: str
    kind: str


class WeatherDayPoint(BaseModel):
    date: str
    revenue_cents: int
    order_count: int
    temp_c: float | None
    precip_mm: float
    rainy: bool


class WeatherCorrelation(BaseModel):
    rainy_avg_revenue: int
    clear_avg_revenue: int
    rainy_avg_orders: float
    clear_avg_orders: float
    daily: list[WeatherDayPoint]
    insights: list[InsightItem]


class WeekdayPattern(BaseModel):
    weekday: int
    weekday_label: str
    revenue_cents: int
    order_count: int


WEEKDAY_LABELS = ["週一", "週二", "週三", "週四", "週五", "週六", "週日"]


@router.get("/store-comparison", response_model=list[StoreComparisonRow])
async def store_comparison(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    compare_prior: bool = False,
) -> list[StoreComparisonRow]:
    if scope.store_id and not scope.is_tenant_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "tenant admin required for multi-store analytics")

    stmt = (
        select(
            Order.store_id,
            func.coalesce(func.sum(Order.total_cents), 0),
            func.coalesce(func.sum(net_revenue_expr()), 0),
            func.count(Order.id),
            func.coalesce(func.sum(Order.refunded_cents), 0),
        )
        .where(Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES))
        .group_by(Order.store_id)
    )
    stmt = apply_date_range(stmt, since, until)
    current = {r[0]: r for r in (await db.execute(stmt)).all()}

    prior_map: dict[str, int] = {}
    if compare_prior and since and until:
        ps, pu = prior_period(since, until)
        p_stmt = (
            select(Order.store_id, func.coalesce(func.sum(Order.total_cents), 0))
            .where(Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES))
            .group_by(Order.store_id)
        )
        p_stmt = apply_date_range(p_stmt, ps, pu)
        prior_map = {r[0]: int(r[1]) for r in (await db.execute(p_stmt)).all()}

    stores = (
        await db.execute(
            select(Store).where(
                Store.tenant_id == scope.tenant_id, Store.deleted_at.is_(None)
            )
        )
    ).scalars().all()

    rows: list[StoreComparisonRow] = []
    for s in stores:
        cur = current.get(s.id)
        gross = int(cur[1]) if cur else 0
        net = int(cur[2]) if cur else 0
        cnt = int(cur[3]) if cur else 0
        refund = int(cur[4]) if cur else 0
        prior = prior_map.get(s.id)
        growth = None
        if prior and prior > 0:
            growth = round((gross - prior) / prior * 100, 1)
        rows.append(
            StoreComparisonRow(
                store_id=s.id,
                store_name=s.name,
                store_code=s.code,
                latitude=s.latitude,
                longitude=s.longitude,
                revenue_cents=gross,
                net_cents=net,
                order_count=cnt,
                avg_order_cents=gross // cnt if cnt else 0,
                refund_cents=refund,
                refund_rate=round(refund / gross * 100, 2) if gross else 0.0,
                prior_revenue_cents=prior,
                growth_pct=growth,
            )
        )
    rows.sort(key=lambda r: r.revenue_cents, reverse=True)
    return rows


@router.get("/aov-distribution", response_model=list[AovBucket])
async def aov_distribution(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> list[AovBucket]:
    stmt = select(Order.total_cents).where(
        Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES)
    )
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    stmt = apply_date_range(stmt, since, until)
    totals = [int(r[0]) for r in (await db.execute(stmt)).all()]
    buckets = [
        ("NT$0–200", 0, 20000),
        ("NT$200–500", 20000, 50000),
        ("NT$500–1000", 50000, 100000),
        ("NT$1000+", 100000, 10**9),
    ]
    result = []
    for label, lo, hi in buckets:
        result.append(
            AovBucket(label=label, count=sum(1 for t in totals if lo <= t < hi))
        )
    return result


@router.get("/discount-stats", response_model=DiscountStats)
async def discount_stats(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> DiscountStats:
    stmt = select(
        func.coalesce(func.sum(Order.discount_cents), 0),
        func.coalesce(func.sum(case((Order.discount_cents > 0, 1), else_=0)), 0),
        func.coalesce(func.sum(Order.subtotal_cents), 0),
    ).where(Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES))
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    stmt = apply_date_range(stmt, since, until)
    row = (await db.execute(stmt)).one()
    subtotal = int(row[2])
    return DiscountStats(
        total_discount_cents=int(row[0]),
        discounted_orders=int(row[1]),
        discount_rate_pct=round(int(row[0]) / subtotal * 100, 2) if subtotal else 0.0,
    )


@router.get("/top-addons", response_model=list[AddonStat])
async def top_addons(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
    limit: int = Query(15, le=50),
) -> list[AddonStat]:
    stmt = (
        select(OrderLine.options_json)
        .join(Order, Order.id == OrderLine.order_id)
        .where(
            Order.tenant_id == scope.tenant_id,
            Order.status.in_(SALE_STATUSES),
            OrderLine.options_json.isnot(None),
        )
    )
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    stmt = apply_date_range(stmt, since, until)
    rows = (await db.execute(stmt)).scalars().all()
    counts: dict[str, dict] = {}
    for opts in rows:
        if not opts:
            continue
        for o in opts:
            name = o.get("choice_name") or o.get("name") or "未知"
            if name not in counts:
                counts[name] = {"count": 0, "revenue_cents": 0}
            counts[name]["count"] += 1
            counts[name]["revenue_cents"] += int(o.get("price_delta_cents") or 0)
    ranked = sorted(counts.items(), key=lambda x: x[1]["count"], reverse=True)[:limit]
    return [
        AddonStat(choice_name=k, count=v["count"], revenue_cents=v["revenue_cents"])
        for k, v in ranked
    ]


@router.get("/weekday-pattern", response_model=list[WeekdayPattern])
async def weekday_pattern(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> list[WeekdayPattern]:
    tenant = await db.get(Tenant, scope.tenant_id) if scope.tenant_id else None
    tz_name = str(tenant_timezone(tenant.settings if tenant else None))
    ts = business_ts()
    if db.bind.dialect.name == "postgresql":
        weekday = func.extract("dow", func.timezone(tz_name, ts))
    else:
        weekday = func.strftime("%w", ts)

    stmt = select(
        weekday.label("wd"),
        func.coalesce(func.sum(Order.total_cents), 0),
        func.count(Order.id),
    ).where(Order.tenant_id == scope.tenant_id, Order.status.in_(SALE_STATUSES))
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    stmt = apply_date_range(stmt, since, until)
    stmt = stmt.group_by(weekday)
    raw = {}
    for r in (await db.execute(stmt)).all():
        wd = int(float(r.wd))
        if db.bind.dialect.name == "postgresql":
            wd = (wd + 6) % 7
        else:
            wd = (int(r.wd) + 6) % 7
        raw[wd] = (int(r[1]), int(r[2]))
    return [
        WeekdayPattern(
            weekday=i,
            weekday_label=WEEKDAY_LABELS[i],
            revenue_cents=raw.get(i, (0, 0))[0],
            order_count=raw.get(i, (0, 0))[1],
        )
        for i in range(7)
    ]


@router.get("/insights", response_model=list[InsightItem])
async def analytics_insights(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> list[InsightItem]:
    insights: list[InsightItem] = []
    summary = await sales_summary(db, scope, since, until, store_id, compare_prior=True)
    if summary.revenue_change_pct is not None:
        direction = "成長" if summary.revenue_change_pct >= 0 else "下滑"
        insights.append(
            InsightItem(
                kind="trend",
                text=f"與上期相比營收{direction} {abs(summary.revenue_change_pct)}%",
            )
        )
    if summary.qr_ratio > 0:
        insights.append(
            InsightItem(
                kind="channel",
                text=f"QR 點餐占 {summary.qr_ratio}%（{summary.qr_order_count} 筆）",
            )
        )

    heat = await hourly_heatmap(db, scope, since, until, store_id)
    if heat:
        peak = max(heat, key=lambda c: c.revenue_cents)
        total_rev = sum(c.revenue_cents for c in heat) or 1
        pct = round(peak.revenue_cents / total_rev * 100)
        insights.append(
            InsightItem(
                kind="peak",
                text=f"{WEEKDAY_LABELS[peak.weekday]} {peak.hour}:00–{peak.hour + 1}:00 為尖峰時段，貢獻約 {pct}% 營收",
            )
        )
    return insights[:5]


@router.get("/weather-correlation", response_model=WeatherCorrelation)
async def weather_correlation(
    db: DbSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> WeatherCorrelation:
    sid = store_id
    if scope.store_id and not scope.is_tenant_admin:
        sid = scope.store_id
    if not sid:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "store_id required")

    store = await db.get(Store, sid)
    if not store or store.tenant_id != scope.tenant_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if store.latitude is None or store.longitude is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "store has no coordinates; run geocode first",
        )

    tenant = await db.get(Tenant, scope.tenant_id)
    tz_name = str(tenant_timezone(tenant.settings if tenant else None))
    day_col = _date_bucket(db.bind, tz_name)
    stmt = (
        select(
            day_col.label("d"),
            func.coalesce(func.sum(Order.total_cents), 0),
            func.count(Order.id),
        )
        .where(
            Order.tenant_id == scope.tenant_id,
            Order.store_id == sid,
            Order.status.in_(SALE_STATUSES),
        )
        .group_by(day_col)
    )
    stmt = apply_date_range(stmt, since, until)
    sales_by_date = {str(r.d): (int(r[1]), int(r[2])) for r in (await db.execute(stmt)).all()}
    if not sales_by_date:
        return WeatherCorrelation(
            rainy_avg_revenue=0,
            clear_avg_revenue=0,
            rainy_avg_orders=0,
            clear_avg_orders=0,
            daily=[],
            insights=[InsightItem(kind="info", text="選定期間尚無訂單資料")],
        )

    dates = sorted(sales_by_date.keys())
    weather = await fetch_daily_weather(
        store.latitude, store.longitude, dates[0], dates[-1]
    )
    daily: list[WeatherDayPoint] = []
    rainy_rev, clear_rev = [], []
    rainy_cnt, clear_cnt = [], []
    for w in weather:
        rev, cnt = sales_by_date.get(w["date"], (0, 0))
        pt = WeatherDayPoint(
            date=w["date"],
            revenue_cents=rev,
            order_count=cnt,
            temp_c=w.get("temp_c"),
            precip_mm=float(w.get("precip_mm") or 0),
            rainy=bool(w.get("rainy")),
        )
        daily.append(pt)
        if pt.rainy:
            rainy_rev.append(rev)
            rainy_cnt.append(cnt)
        else:
            clear_rev.append(rev)
            clear_cnt.append(cnt)

    insights: list[InsightItem] = []
    if rainy_rev and clear_rev:
        r_avg = sum(rainy_rev) // len(rainy_rev)
        c_avg = sum(clear_rev) // len(clear_rev)
        if c_avg > r_avg * 1.1:
            insights.append(InsightItem(kind="weather", text="晴天日平均營收明顯高於雨天"))
        elif r_avg > c_avg * 1.1:
            insights.append(InsightItem(kind="weather", text="雨天日平均營收反而較高（可能外送/內用結構不同）"))

    return WeatherCorrelation(
        rainy_avg_revenue=sum(rainy_rev) // len(rainy_rev) if rainy_rev else 0,
        clear_avg_revenue=sum(clear_rev) // len(clear_rev) if clear_rev else 0,
        rainy_avg_orders=sum(rainy_cnt) / len(rainy_cnt) if rainy_cnt else 0,
        clear_avg_orders=sum(clear_cnt) / len(clear_cnt) if clear_cnt else 0,
        daily=daily,
        insights=insights,
    )
