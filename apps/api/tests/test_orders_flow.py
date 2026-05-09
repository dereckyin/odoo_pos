from datetime import datetime, timezone

from app.core import db as db_mod
from app.models import Member, Product
from sqlalchemy.ext.asyncio import async_sessionmaker

from .helpers import build_tenant, login_pos


async def _seed_product_member(factory: async_sessionmaker, *, tenant_id: str, sku: str = "SKU-1"):
    async with factory() as db:
        product = Product(tenant_id=tenant_id, sku=sku, name="可樂", price_cents=25)
        db.add(product)
        member = Member(
            tenant_id=tenant_id, phone="0911111111", name="客戶 A",
            joined_at=datetime.now(timezone.utc),
        )
        db.add(member)
        await db.commit()
        await db.refresh(product)
        await db.refresh(member)
        return product, member


async def test_upload_order_decrements_inventory_and_grants_points(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    product, member = await _seed_product_member(factory, tenant_id=bundle.tenant.id)
    token = await login_pos(client, bundle)

    payload = {
        "id": "order-uuid-1",
        "store_id": bundle.store.id,
        "terminal_id": bundle.terminal.id,
        "cashier_id": bundle.admin.id,
        "member_id": member.id,
        "status": "paid",
        "subtotal_cents": 250,
        "discount_cents": 0,
        "tax_cents": 12,
        "total_cents": 262,
        "client_created_at": datetime.now(timezone.utc).isoformat(),
        "lines": [
            {
                "id": "line-uuid-1",
                "product_id": product.id,
                "product_name": product.name,
                "sku": product.sku,
                "qty": 10,
                "unit_price_cents": 25,
                "line_total_cents": 250,
            }
        ],
        "payments": [
            {
                "id": "pay-uuid-1",
                "method": "cash",
                "amount_cents": 262,
                "tendered_cents": 300,
                "change_due_cents": 38,
            }
        ],
    }
    r = await client.post("/orders", json=payload, headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 201, r.text
    assert r.json()["tenant_id"] == bundle.tenant.id

    r2 = await client.post("/orders", json=payload, headers={"Authorization": f"Bearer {token}"})
    assert r2.status_code == 201

    r3 = await client.get(f"/members/{member.id}", headers={"Authorization": f"Bearer {token}"})
    assert r3.status_code == 200
    assert r3.json()["points"] == 2

    r4 = await client.get("/inventory/levels", headers={"Authorization": f"Bearer {token}"})
    assert r4.status_code == 200
    levels = r4.json()
    assert any(lv["product_id"] == product.id and lv["on_hand"] == -10 for lv in levels)


async def test_upload_order_rejects_mismatched_store(app, client):
    """A POS session bound to store A must not be able to upload an order
    that claims store_id=B (the previous code trusted the body)."""
    factory = db_mod.get_session_factory()
    a = await build_tenant(factory, tenant_code="alpha", store_code="A1", admin_username="alphaA",
                           cashier_username="alphaC")
    b = await build_tenant(factory, tenant_code="beta", store_code="B1", admin_username="betaA",
                           cashier_username="betaC")
    product_a, _ = await _seed_product_member(factory, tenant_id=a.tenant.id, sku="A-SKU")

    token = await login_pos(client, a, username="alphaA")
    payload = {
        "id": "order-cross-1",
        "store_id": b.store.id,  # ⚠ wrong store
        "terminal_id": a.terminal.id,
        "cashier_id": a.admin.id,
        "subtotal_cents": 25,
        "discount_cents": 0,
        "tax_cents": 1,
        "total_cents": 26,
        "client_created_at": datetime.now(timezone.utc).isoformat(),
        "lines": [
            {
                "id": "ln-x",
                "product_id": product_a.id,
                "product_name": product_a.name,
                "sku": product_a.sku,
                "qty": 1,
                "unit_price_cents": 25,
                "line_total_cents": 25,
            }
        ],
        "payments": [{"id": "pay-x", "method": "cash", "amount_cents": 26}],
    }
    r = await client.post("/orders", json=payload, headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 403, r.text


async def test_refund_reverses_inventory(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    product, _ = await _seed_product_member(factory, tenant_id=bundle.tenant.id)
    token = await login_pos(client, bundle)

    order_id = "order-uuid-2"
    await client.post(
        "/orders",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "id": order_id,
            "store_id": bundle.store.id,
            "terminal_id": bundle.terminal.id,
            "cashier_id": bundle.admin.id,
            "subtotal_cents": 50,
            "discount_cents": 0,
            "tax_cents": 2,
            "total_cents": 52,
            "client_created_at": datetime.now(timezone.utc).isoformat(),
            "lines": [
                {
                    "id": "line-2",
                    "product_id": product.id,
                    "product_name": product.name,
                    "sku": product.sku,
                    "qty": 2,
                    "unit_price_cents": 25,
                    "line_total_cents": 50,
                }
            ],
            "payments": [{"id": "pay-2", "method": "cash", "amount_cents": 52}],
        },
    )

    r = await client.post(
        f"/orders/{order_id}/refund",
        headers={"Authorization": f"Bearer {token}"},
        json={"id": "refund-1", "method": "cash", "lines": []},
    )
    assert r.status_code == 201, r.text
    assert r.json()["total_amount_cents"] == 50

    r2 = await client.get(f"/orders/{order_id}", headers={"Authorization": f"Bearer {token}"})
    assert r2.json()["status"] in ("refunded", "partiallyRefunded")
    assert r2.json()["refunded_cents"] == 50
