"""Stock transfer end-to-end test (multi-tenant aware)."""

from datetime import datetime, timezone

from app.core import db as db_mod
from app.models import Product, Store, Terminal

from .helpers import build_tenant, login_pos


async def _bootstrap(client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    async with factory() as db:
        store_b = Store(tenant_id=bundle.tenant.id, code="S002", name="B")
        db.add(store_b)
        await db.flush()
        # Add a terminal to store B as well so transfer endpoints can reach it.
        from app.core.security import hash_secret
        db.add(Terminal(
            tenant_id=bundle.tenant.id, store_id=store_b.id, code="T02",
            api_key_hash=hash_secret("k"),
        ))
        product = Product(tenant_id=bundle.tenant.id, sku="MILK", name="Milk", price_cents=100)
        db.add(product)
        await db.commit()
        await db.refresh(store_b)
        await db.refresh(product)
    token = await login_pos(client, bundle)
    return token, bundle.store.id, store_b.id, product.id


async def test_transfer_dispatch_and_receive_updates_levels(app, client):
    token, store_a, store_b, product_id = await _bootstrap(client)
    headers = {"Authorization": f"Bearer {token}"}

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

    r = await client.patch(
        "/inventory/transfers/trf-1",
        headers=headers,
        json={"status": "dispatched"},
    )
    assert r.status_code == 200, r.text

    r = await client.get("/inventory/levels", params={"store_id": store_a}, headers=headers)
    assert any(lv["product_id"] == product_id and lv["on_hand"] == 70 for lv in r.json())

    r = await client.patch(
        "/inventory/transfers/trf-1",
        headers=headers,
        json={"status": "received"},
    )
    assert r.status_code == 200, r.text

    r = await client.get("/inventory/levels", params={"store_id": store_b}, headers=headers)
    assert any(lv["product_id"] == product_id and lv["on_hand"] == 30 for lv in r.json())
