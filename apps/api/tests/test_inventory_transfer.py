"""Stock transfer end-to-end test."""

from datetime import datetime, timezone

from app.core import db as db_mod
from app.core.security import hash_password
from app.models import Product, Store, Terminal, User


async def _bootstrap(client):
    factory = db_mod.get_session_factory()
    async with factory() as db:
        store_a = Store(code="S001", name="A")
        store_b = Store(code="S002", name="B")
        db.add_all([store_a, store_b])
        await db.flush()
        db.add(Terminal(store_id=store_a.id, code="T01", api_key_hash=hash_password("k")))
        db.add(
            User(
                username="admin",
                password_hash=hash_password("admin123"),
                display_name="Admin",
                role="admin",
                store_id=store_a.id,
            )
        )
        product = Product(sku="MILK", name="Milk", price_cents=100)
        db.add(product)
        await db.commit()
        await db.refresh(store_a)
        await db.refresh(store_b)
        await db.refresh(product)
    r = await client.post(
        "/auth/login",
        json={"username": "admin", "password": "admin123", "terminal_code": "T01"},
    )
    return r.json()["access_token"], store_a.id, store_b.id, product.id


async def test_transfer_dispatch_and_receive_updates_levels(app, client):
    token, store_a, store_b, product_id = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {token}"}

    # Seed: store A has 100 units (via direct movement)
    seed = await client.post(
        "/inventory/movements",
        headers=headers,
        json={
            "id": "mv-seed",
            "store_id": store_a,
            "product_id": product_id,
            "qty_delta": 100,
            "reason": "purchase",
            "client_created_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    assert seed.status_code == 201, seed.text

    # Create transfer
    r = await client.post(
        "/inventory/transfers",
        headers=headers,
        json={
            "id": "trf-1",
            "from_store_id": store_a,
            "to_store_id": store_b,
            "status": "draft",
            "lines": [
                {"id": "trfln-1", "product_id": product_id, "qty": 30, "received_qty": None}
            ],
        },
    )
    assert r.status_code == 201, r.text

    # Dispatch
    r = await client.patch(
        "/inventory/transfers/trf-1",
        headers=headers,
        json={"status": "dispatched"},
    )
    assert r.status_code == 200, r.text

    # Source store should now have 70
    r = await client.get("/inventory/levels", params={"store_id": store_a}, headers=headers)
    assert any(lv["product_id"] == product_id and lv["on_hand"] == 70 for lv in r.json())

    # Receive
    r = await client.patch(
        "/inventory/transfers/trf-1",
        headers=headers,
        json={"status": "received"},
    )
    assert r.status_code == 200, r.text

    r = await client.get("/inventory/levels", params={"store_id": store_b}, headers=headers)
    assert any(lv["product_id"] == product_id and lv["on_hand"] == 30 for lv in r.json())
