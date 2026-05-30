"""Cross-tenant data-leak regression tests.

These exist specifically to catch the original audit findings: a tenant must
NEVER be able to read or write another tenant's products, members, orders,
inventory or reports.
"""
from datetime import datetime, timezone

from app.core import db as db_mod
from app.models import Member, Product

from .helpers import build_tenant, login_admin, login_pos


async def _seed_product(factory, tenant_id: str, sku: str = "P-1") -> Product:
    async with factory() as db:
        p = Product(tenant_id=tenant_id, sku=sku, name="Demo", price_cents=100)
        db.add(p)
        await db.commit()
        await db.refresh(p)
        return p


async def test_products_are_scoped_to_tenant(app, client):
    factory = db_mod.get_session_factory()
    a = await build_tenant(factory, tenant_code="t-a", admin_username="aA", cashier_username="aC")
    b = await build_tenant(factory, tenant_code="t-b", admin_username="bA", cashier_username="bC")
    p_a = await _seed_product(factory, a.tenant.id, sku="A-1")
    p_b = await _seed_product(factory, b.tenant.id, sku="B-1")

    a_token = await login_admin(client, a, username="aA")
    r = await client.get("/products", headers={"Authorization": f"Bearer {a_token}"})
    assert r.status_code == 200
    skus = {p["sku"] for p in r.json()}
    assert skus == {"A-1"}

    # Tenant A directly trying to fetch tenant B's product → 404 (not 403, to
    # avoid leaking existence).
    r = await client.get(
        f"/products/{p_b.id}", headers={"Authorization": f"Bearer {a_token}"}
    )
    assert r.status_code == 404


async def test_members_are_scoped_to_tenant(app, client):
    factory = db_mod.get_session_factory()
    a = await build_tenant(factory, tenant_code="m-a", admin_username="aM", cashier_username="aMC")
    b = await build_tenant(factory, tenant_code="m-b", admin_username="bM", cashier_username="bMC")

    async with factory() as db:
        ma = Member(tenant_id=a.tenant.id, phone="0911111111", name="A 客戶",
                    joined_at=datetime.now(timezone.utc))
        mb = Member(tenant_id=b.tenant.id, phone="0911111111", name="B 客戶",
                    joined_at=datetime.now(timezone.utc))
        db.add_all([ma, mb])
        await db.commit()
        await db.refresh(ma)
        await db.refresh(mb)

    a_token = await login_admin(client, a, username="aM")

    # Same phone exists in both tenants — A's lookup returns A's row only.
    r = await client.get(
        "/members/by-phone/0911111111",
        headers={"Authorization": f"Bearer {a_token}"},
    )
    assert r.status_code == 200
    assert r.json()["id"] == ma.id

    # Cross-tenant id → 404.
    r = await client.get(
        f"/members/{mb.id}", headers={"Authorization": f"Bearer {a_token}"}
    )
    assert r.status_code == 404


async def test_orders_list_does_not_leak_other_tenants(app, client):
    """Even after both tenants upload orders, each side must only see its
    own."""
    factory = db_mod.get_session_factory()
    a = await build_tenant(factory, tenant_code="o-a", admin_username="aO", cashier_username="aOC")
    b = await build_tenant(factory, tenant_code="o-b", admin_username="bO", cashier_username="bOC")
    p_a = await _seed_product(factory, a.tenant.id, sku="OA-1")
    p_b = await _seed_product(factory, b.tenant.id, sku="OB-1")

    a_token = await login_pos(client, a, username="aO")
    b_token = await login_pos(client, b, username="bO")

    def _payload(bundle, product, oid):
        return {
            "id": oid,
            "store_id": bundle.store.id,
            "terminal_id": bundle.terminal.id,
            "cashier_id": bundle.admin.id,
            "subtotal_cents": 100,
            "discount_cents": 0,
            "tax_cents": 5,
            "total_cents": 105,
            "client_created_at": datetime.now(timezone.utc).isoformat(),
            "lines": [{
                "id": f"{oid}-l1",
                "product_id": product.id,
                "product_name": product.name,
                "sku": product.sku,
                "qty": 1,
                "unit_price_cents": 100,
                "line_total_cents": 100,
            }],
            "payments": [{"id": f"{oid}-p1", "method": "cash", "amount_cents": 105}],
        }

    r = await client.post(
        "/orders", json=_payload(a, p_a, "ord-a-1"),
        headers={"Authorization": f"Bearer {a_token}"}
    )
    assert r.status_code == 201, r.text
    r = await client.post(
        "/orders", json=_payload(b, p_b, "ord-b-1"),
        headers={"Authorization": f"Bearer {b_token}"}
    )
    assert r.status_code == 201

    # A's listing contains only A's order.
    r = await client.get("/orders", headers={"Authorization": f"Bearer {a_token}"})
    assert r.status_code == 200
    ids = {o["id"] for o in r.json()["items"]}
    assert ids == {"ord-a-1"}

    # A cannot fetch B's order by id.
    r = await client.get(
        "/orders/ord-b-1", headers={"Authorization": f"Bearer {a_token}"}
    )
    assert r.status_code == 404


async def test_dashboard_stats_are_tenant_scoped(app, client):
    factory = db_mod.get_session_factory()
    a = await build_tenant(factory, tenant_code="d-a", admin_username="aD", cashier_username="aDC")
    b = await build_tenant(factory, tenant_code="d-b", admin_username="bD", cashier_username="bDC")
    await _seed_product(factory, a.tenant.id, sku="DA-1")
    await _seed_product(factory, a.tenant.id, sku="DA-2")
    await _seed_product(factory, b.tenant.id, sku="DB-1")

    a_token = await login_admin(client, a, username="aD")
    r = await client.get("/dashboard/stats", headers={"Authorization": f"Bearer {a_token}"})
    assert r.status_code == 200
    assert r.json()["products"] == 2
