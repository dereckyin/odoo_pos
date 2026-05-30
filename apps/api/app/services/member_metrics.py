"""Upsert daily member metrics after orders."""
from __future__ import annotations

from datetime import date, datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import MemberMetricsDaily


async def upsert_member_metrics_for_order(
    db: AsyncSession,
    *,
    tenant_id: str,
    member_id: str,
    revenue_cents: int,
    order_at: datetime,
) -> None:
    if revenue_cents <= 0:
        return
    metric_date = order_at.astimezone(timezone.utc).date()
    row = (
        await db.execute(
            select(MemberMetricsDaily).where(
                MemberMetricsDaily.tenant_id == tenant_id,
                MemberMetricsDaily.member_id == member_id,
                MemberMetricsDaily.metric_date == metric_date,
            )
        )
    ).scalar_one_or_none()
    if row is None:
        db.add(
            MemberMetricsDaily(
                tenant_id=tenant_id,
                member_id=member_id,
                metric_date=metric_date,
                order_count=1,
                revenue_cents=revenue_cents,
                last_order_at=order_at,
            )
        )
    else:
        row.order_count = row.order_count + 1
        row.revenue_cents = row.revenue_cents + revenue_cents
        row.last_order_at = order_at


async def backfill_member_metrics(
    db: AsyncSession, tenant_id: str, metric_date: date
) -> int:
    """Rebuild metrics for one day from orders (admin/cron helper)."""
    from ..models import Order

    rows = (
        await db.execute(
            select(Order).where(
                Order.tenant_id == tenant_id,
                Order.member_id.isnot(None),
                Order.status.in_(("paid", "partiallyRefunded", "refunded")),
            )
        )
    ).scalars().all()
    count = 0
    for o in rows:
        if not o.member_id:
            continue
        ts = o.client_created_at or o.created_at
        if ts.astimezone(timezone.utc).date() != metric_date:
            continue
        await upsert_member_metrics_for_order(
            db,
            tenant_id=tenant_id,
            member_id=o.member_id,
            revenue_cents=o.total_cents,
            order_at=ts,
        )
        count += 1
    return count
