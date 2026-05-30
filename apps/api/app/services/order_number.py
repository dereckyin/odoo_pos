"""Human-readable order number allocation."""

from __future__ import annotations

from datetime import date, datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Order, OrderSequence, Store, Tenant
from .business_time import business_date, business_date_str, tenant_timezone


def format_order_no(store_code: str, biz_date: date, seq: int) -> str:
    return f"{store_code}-{biz_date.strftime('%Y%m%d')}-{seq:04d}"


async def allocate_order_no(
    db: AsyncSession,
    *,
    tenant_id: str,
    store_id: str,
    client_created_at: datetime | None,
    fallback_created_at: datetime | None = None,
) -> str:
    tenant = await db.get(Tenant, tenant_id)
    tz = tenant_timezone(tenant.settings if tenant else None)

    store = await db.get(Store, store_id)
    if not store:
        raise ValueError("store not found")

    ts = client_created_at or fallback_created_at or datetime.now(timezone.utc)
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    biz_dt = ts.astimezone(tz).date()

    seq_row = (
        await db.execute(
            select(OrderSequence)
            .where(
                OrderSequence.store_id == store_id,
                OrderSequence.business_date == biz_dt,
            )
            .with_for_update()
        )
    ).scalar_one_or_none()

    if seq_row is None:
        seq_row = OrderSequence(
            tenant_id=tenant_id,
            store_id=store_id,
            business_date=biz_dt,
            last_seq=0,
        )
        db.add(seq_row)
        await db.flush()
        seq_row = (
            await db.execute(
                select(OrderSequence)
                .where(
                    OrderSequence.store_id == store_id,
                    OrderSequence.business_date == biz_dt,
                )
                .with_for_update()
            )
        ).scalar_one()

    seq_row.last_seq += 1
    await db.flush()
    return format_order_no(store.code, biz_dt, seq_row.last_seq)


async def backfill_order_no_for_order(
    db: AsyncSession,
    order: Order,
    store_code: str,
    tz,
    seq_counters: dict[tuple[str, str], int],
) -> str:
    """Assign order_no during migration backfill using in-memory counters."""
    biz = business_date(order, tz)
    key = (order.store_id, business_date_str(order, tz))
    seq_counters[key] = seq_counters.get(key, 0) + 1
    return format_order_no(store_code, biz, seq_counters[key])
