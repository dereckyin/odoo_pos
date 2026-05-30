"""Shared reporting query helpers."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select

from ..models import Order, Payment
from ..core.deps import apply_tenant, TenantScope

SALE_STATUSES = ("paid", "partiallyRefunded")


def business_ts():
    return func.coalesce(Order.client_created_at, Order.created_at)


def net_revenue_expr():
    return Order.total_cents - Order.refunded_cents


def base_order_filters(scope: TenantScope, store_id: str | None = None):
    stmt = apply_tenant(select(Order), Order, scope).where(
        Order.status.in_(SALE_STATUSES)
    )
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    return stmt


def apply_date_range(stmt, since: datetime | None, until: datetime | None):
    ts = business_ts()
    if since:
        stmt = stmt.where(ts >= since)
    if until:
        stmt = stmt.where(ts <= until)
    return stmt


def prior_period(since: datetime | None, until: datetime | None) -> tuple[datetime | None, datetime | None]:
    if since is None or until is None:
        return None, None
    delta = until - since
    return since - delta - timedelta(seconds=1), since - timedelta(seconds=1)
