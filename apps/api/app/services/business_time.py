"""Business-time helpers for orders and reporting."""

from __future__ import annotations

from datetime import date, datetime, timezone
from zoneinfo import ZoneInfo

DEFAULT_TENANT_TIMEZONE = "Asia/Taipei"


def tenant_timezone(settings: dict | None) -> ZoneInfo:
    tz_name = (settings or {}).get("timezone") or DEFAULT_TENANT_TIMEZONE
    try:
        return ZoneInfo(tz_name)
    except Exception:
        return ZoneInfo(DEFAULT_TENANT_TIMEZONE)


def order_business_datetime(order) -> datetime:
    """Primary sale timestamp: POS checkout time, else server insert time."""
    ts = order.client_created_at or order.created_at
    if ts.tzinfo is None:
        return ts.replace(tzinfo=timezone.utc)
    return ts


def business_date(order, tz: ZoneInfo) -> date:
    return order_business_datetime(order).astimezone(tz).date()


def business_date_str(order, tz: ZoneInfo) -> str:
    return business_date(order, tz).strftime("%Y%m%d")
