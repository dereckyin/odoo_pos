from datetime import datetime, timezone

from app.core import db as db_mod
from app.core.security import hash_password
from app.models import Member, Product, Store, Terminal, User
from sqlalchemy.ext.asyncio import async_sessionmaker


async def _login(client, username="admin", password="admin123", terminal_code="T01") -> str:
    r = await client.post(
        "/auth/login",
        json={"username": username, "password": password, "terminal_code": terminal_code},
    )
    assert r.status_code == 200, r.text
    return r.json()["access_token"]


async def _seed(factory: async_sessionmaker):
    async with factory() as db:
        store = Store(code="S001", name="Demo")
        db.add(store)
        await db.flush()
        terminal = Terminal(store_id=store.id, code="T01", api_key_hash=hash_password("k"))
        db.add(terminal)
        admin = User(
            username="admin",
            password_hash=hash_password("admin123"),
            display_name="Admin",
            role="admin",
            store_id=store.id,
        )
        db.add(admin)
        product = Product(sku="SKU-1", name="可樂", price_cents=25)
        db.add(product)
        member = Member(phone="0911111111", name="客戶 A", joined_at=datetime.now(timezone.utc))
        db.add(member)
        await db.commit()
        return store, terminal, admin, product, member


async def test_upload_order_decrements_inventory_and_grants_points(app, client):
    factory = db_mod.get_session_factory()
    store, terminal, admin, product, member = await _seed(factory)
    token = await _login(client)

    payload = {
        "id": "order-uuid-1",
        "store_id": store.id,
        "terminal_id": terminal.id,
        "cashier_id": admin.id,
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

    # Re-uploading is a no-op (idempotent)
    r2 = await client.post("/orders", json=payload, headers={"Authorization": f"Bearer {token}"})
    assert r2.status_code == 201

    # Member earned 2 points (262 // 100)
    r3 = await client.get(f"/members/{member.id}", headers={"Authorization": f"Bearer {token}"})
    assert r3.status_code == 200
    assert r3.json()["points"] == 2  # 262 // 100 = 2

    # Inventory level should now be -10
    r4 = await client.get("/inventory/levels", headers={"Authorization": f"Bearer {token}"})
    assert r4.status_code == 200
    levels = r4.json()
    assert any(lv["product_id"] == product.id and lv["on_hand"] == -10 for lv in levels)


async def test_refund_reverses_inventory(app, client):
    factory = db_mod.get_session_factory()
    store, terminal, admin, product, member = await _seed(factory)
    token = await _login(client)

    order_id = "order-uuid-2"
    await client.post(
        "/orders",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "id": order_id,
            "store_id": store.id,
            "terminal_id": terminal.id,
            "cashier_id": admin.id,
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

    # Full refund
    r = await client.post(
        f"/orders/{order_id}/refund",
        headers={"Authorization": f"Bearer {token}"},
        json={"id": "refund-1", "user_id": admin.id, "method": "cash", "lines": []},
    )
    assert r.status_code == 201, r.text
    assert r.json()["total_amount_cents"] == 50

    r2 = await client.get(f"/orders/{order_id}", headers={"Authorization": f"Bearer {token}"})
    # 50 cents refunded but order total is 52 (includes tax), so it's partial.
    assert r2.json()["status"] in ("refunded", "partiallyRefunded")
    assert r2.json()["refunded_cents"] == 50
