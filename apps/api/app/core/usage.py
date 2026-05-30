"""Per-tenant usage counters + plan-limit checks."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import (
    Product,
    Store,
    SubscriptionPlan,
    Tenant,
    TenantSubscription,
    Terminal,
    UsageCounter,
)


def _current_period() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m")


async def bump_usage_counter(
    db: AsyncSession, *, tenant_id: str, metric: str, delta: int = 1
) -> int:
    period = _current_period()
    counter = (
        await db.execute(
            select(UsageCounter).where(
                UsageCounter.tenant_id == tenant_id,
                UsageCounter.metric == metric,
                UsageCounter.period == period,
            )
        )
    ).scalar_one_or_none()
    if counter is None:
        counter = UsageCounter(
            tenant_id=tenant_id, metric=metric, period=period, value=delta
        )
        db.add(counter)
        await db.flush()
        return counter.value
    counter.value = counter.value + delta
    await db.flush()
    return counter.value


async def get_usage(db: AsyncSession, tenant_id: str, metric: str) -> int:
    period = _current_period()
    val = (
        await db.execute(
            select(UsageCounter.value).where(
                UsageCounter.tenant_id == tenant_id,
                UsageCounter.metric == metric,
                UsageCounter.period == period,
            )
        )
    ).scalar_one_or_none()
    return val or 0


async def get_active_plan(db: AsyncSession, tenant_id: str) -> SubscriptionPlan | None:
    """Resolve the tenant's currently-active plan (or the first plan matching
    the tenant's ``plan_code`` for tenants we provisioned manually)."""
    sub = (
        await db.execute(
            select(TenantSubscription)
            .where(
                TenantSubscription.tenant_id == tenant_id,
                TenantSubscription.status == "active",
            )
            .order_by(TenantSubscription.started_at.desc())
        )
    ).scalar_one_or_none()
    if sub:
        return await db.get(SubscriptionPlan, sub.plan_id)
    tenant = await db.get(Tenant, tenant_id)
    if tenant and tenant.plan_code:
        return (
            await db.execute(
                select(SubscriptionPlan).where(SubscriptionPlan.code == tenant.plan_code)
            )
        ).scalar_one_or_none()
    return None


async def assert_can_add_store(db: AsyncSession, tenant_id: str) -> None:
    plan = await get_active_plan(db, tenant_id)
    if plan is None:
        return
    count = (
        await db.execute(
            select(func.count(Store.id)).where(
                Store.tenant_id == tenant_id, Store.deleted_at.is_(None)
            )
        )
    ).scalar() or 0
    if count >= plan.max_stores:
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"plan '{plan.code}' allows up to {plan.max_stores} store(s); upgrade to add more.",
        )


async def assert_can_add_terminal(db: AsyncSession, tenant_id: str) -> None:
    plan = await get_active_plan(db, tenant_id)
    if plan is None:
        return
    count = (
        await db.execute(
            select(func.count(Terminal.id)).where(
                Terminal.tenant_id == tenant_id, Terminal.deleted_at.is_(None)
            )
        )
    ).scalar() or 0
    if count >= plan.max_terminals:
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"plan '{plan.code}' allows up to {plan.max_terminals} terminals.",
        )


async def assert_can_add_product(db: AsyncSession, tenant_id: str) -> None:
    plan = await get_active_plan(db, tenant_id)
    if plan is None:
        return
    count = (
        await db.execute(
            select(func.count(Product.id)).where(
                Product.tenant_id == tenant_id, Product.deleted_at.is_(None)
            )
        )
    ).scalar() or 0
    if count >= plan.max_products:
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"plan '{plan.code}' allows up to {plan.max_products} products.",
        )


async def assert_within_monthly_orders(db: AsyncSession, tenant_id: str) -> None:
    plan = await get_active_plan(db, tenant_id)
    if plan is None:
        return
    used = await get_usage(db, tenant_id, "orders")
    if used >= plan.max_orders_per_month:
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"plan '{plan.code}' monthly order quota exceeded ({plan.max_orders_per_month}).",
        )


def plan_features(plan: SubscriptionPlan | None) -> dict:
    if plan is None:
        return {}
    return plan.features or {}


async def get_tenant_features(db: AsyncSession, tenant_id: str) -> dict:
    plan = await get_active_plan(db, tenant_id)
    return plan_features(plan)


async def assert_plan_feature(
    db: AsyncSession, tenant_id: str, feature: str, *, truthy: bool = True
) -> dict:
    feats = await get_tenant_features(db, tenant_id)
    val = feats.get(feature)
    ok = bool(val) if truthy else val is not None
    if not ok:
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"plan upgrade required for feature '{feature}'",
        )
    return feats


async def assert_member_limit(db: AsyncSession, tenant_id: str) -> None:
    from ..models import Member

    feats = await get_tenant_features(db, tenant_id)
    cap = int(feats.get("max_members") or 0)
    if cap <= 0:
        return
    count = (
        await db.execute(
            select(func.count(Member.id)).where(
                Member.tenant_id == tenant_id, Member.deleted_at.is_(None)
            )
        )
    ).scalar() or 0
    if count >= cap:
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"member limit ({cap}) reached; upgrade plan to add more.",
        )

