"""Phase 4 tests: subscription plan limit enforcement + data export."""
from app.core import db as db_mod
from app.models import SubscriptionPlan, Tenant, TenantSubscription
from datetime import datetime, timezone

from .helpers import build_tenant, login_admin


async def _attach_plan(factory, tenant_id: str, *, max_stores=2, max_terminals=4,
                      max_orders_per_month=1000, max_products=100, code="starter"):
    async with factory() as db:
        plan = SubscriptionPlan(
            code=code,
            name=code.title(),
            price_cents=0,
            interval="month",
            max_stores=max_stores,
            max_terminals=max_terminals,
            max_orders_per_month=max_orders_per_month,
            max_products=max_products,
            is_active=True,
        )
        db.add(plan)
        await db.flush()
        db.add(TenantSubscription(
            tenant_id=tenant_id,
            plan_id=plan.id,
            status="active",
            started_at=datetime.now(timezone.utc),
        ))
        # Also stamp tenant.plan_code for the alternate plan-resolution path.
        tenant = await db.get(Tenant, tenant_id)
        tenant.plan_code = plan.code
        await db.commit()


async def test_plan_limit_blocks_extra_store(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    # Tighten the plan to just 1 store (the seeded MAIN store already counts).
    await _attach_plan(factory, bundle.tenant.id, max_stores=1)
    token = await login_admin(client, bundle)

    r = await client.post(
        "/stores",
        json={"code": "S002", "name": "Second store"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 402, r.text
    assert "store" in r.json()["detail"].lower()


async def test_plan_limit_blocks_extra_product(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    await _attach_plan(factory, bundle.tenant.id, max_products=1)
    token = await login_admin(client, bundle)

    # First product within quota.
    r = await client.post(
        "/products",
        json={"sku": "SKU-1", "name": "Cola", "price_cents": 4500},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 201
    # Second exceeds quota → 402.
    r = await client.post(
        "/products",
        json={"sku": "SKU-2", "name": "Tea", "price_cents": 3000},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 402, r.text


async def test_export_returns_tenant_snapshot(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    await _attach_plan(factory, bundle.tenant.id)
    token = await login_admin(client, bundle)

    # Seed one product so the snapshot isn't trivially empty.
    await client.post(
        "/products",
        json={"sku": "SKU-EXP", "name": "Pen", "price_cents": 100},
        headers={"Authorization": f"Bearer {token}"},
    )

    r = await client.get(
        "/tenant/export",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["tenant"]["id"] == bundle.tenant.id
    assert any(p["sku"] == "SKU-EXP" for p in data["products"])
    # Sensitive columns are scrubbed.
    for u in data["users"]:
        assert "password_hash" not in u
    for t in data["terminals"]:
        assert "api_key_hash" not in t


async def test_export_isolated_per_tenant(app, client):
    factory = db_mod.get_session_factory()
    a = await build_tenant(factory, tenant_code="alpha", store_code="A1",
                           admin_username="alpha_admin", cashier_username="alpha_cashier")
    b = await build_tenant(factory, tenant_code="beta", store_code="B1",
                           admin_username="beta_admin", cashier_username="beta_cashier")
    a_token = await login_admin(client, a, username="alpha_admin")

    r = await client.get(
        "/tenant/export",
        headers={"Authorization": f"Bearer {a_token}"},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["tenant"]["id"] == a.tenant.id
    # No cross-tenant leakage.
    user_ids = {u["id"] for u in data["users"]}
    assert b.admin.id not in user_ids
    assert b.cashier.id not in user_ids
