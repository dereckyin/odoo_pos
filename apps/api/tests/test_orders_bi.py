"""Tests for order numbers, list filters, and report aggregates."""

from datetime import datetime, timezone

from app.core import db as db_mod
from app.models import Product
from sqlalchemy.ext.asyncio import async_sessionmaker

from .helpers import build_tenant, login_admin, login_pos


async def _seed_product(factory: async_sessionmaker, *, tenant_id: str):
    async with factory() as db:
        product = Product(tenant_id=tenant_id, sku="SKU-BI", name="測試商品", price_cents=100)
        db.add(product)
        await db.commit()
        await db.refresh(product)
        return product


async def _upload_order(client, bundle, product, order_id: str, total: int = 100):
    token = await login_pos(client, bundle)
    payload = {
        "id": order_id,
        "member_id": None,
        "status": "paid",
        "subtotal_cents": total,
        "discount_cents": 0,
        "tax_cents": 0,
        "total_cents": total,
        "client_created_at": datetime.now(timezone.utc).isoformat(),
        "lines": [
            {
                "id": f"line-{order_id}",
                "product_id": product.id,
                "product_name": product.name,
                "sku": product.sku,
                "qty": 1,
                "unit_price_cents": total,
                "line_total_cents": total,
            }
        ],
        "payments": [{"id": f"pay-{order_id}", "method": "cash", "amount_cents": total}],
    }
    r = await client.post("/orders", json=payload, headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 201, r.text
    return r.json()


async def test_order_no_assigned_on_upload(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    product = await _seed_product(factory, tenant_id=bundle.tenant.id)
    data = await _upload_order(client, bundle, product, "order-bi-1")
    assert data["order_no"]
    assert bundle.store.code in data["order_no"]


async def test_list_orders_paginated_with_filters(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    product = await _seed_product(factory, tenant_id=bundle.tenant.id)
    await _upload_order(client, bundle, product, "order-bi-2")
    await _upload_order(client, bundle, product, "order-bi-3", total=200)

    admin_token = await login_admin(client, bundle)
    headers = {"Authorization": f"Bearer {admin_token}"}
    r = await client.get("/orders", params={"limit": 1, "offset": 0}, headers=headers)
    assert r.status_code == 200
    body = r.json()
    assert "items" in body
    assert "total" in body
    assert body["total"] >= 2
    assert len(body["items"]) == 1
    assert body["items"][0].get("store_name")


async def test_sales_summary_report(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    product = await _seed_product(factory, tenant_id=bundle.tenant.id)
    await _upload_order(client, bundle, product, "order-bi-4", total=300)

    admin_token = await login_admin(client, bundle)
    headers = {"Authorization": f"Bearer {admin_token}"}
    r = await client.get("/reports/sales-summary", headers=headers)
    assert r.status_code == 200
    data = r.json()
    assert data["total_orders"] >= 1
    assert data["total_revenue_cents"] >= 300
    assert "net_revenue_cents" in data


async def test_order_no_unique_per_store_day(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    product = await _seed_product(factory, tenant_id=bundle.tenant.id)
    a = await _upload_order(client, bundle, product, "order-bi-5a")
    b = await _upload_order(client, bundle, product, "order-bi-5b")
    assert a["order_no"] != b["order_no"]
    prefix_a = "-".join(a["order_no"].split("-")[:2])
    prefix_b = "-".join(b["order_no"].split("-")[:2])
    assert prefix_a == prefix_b
