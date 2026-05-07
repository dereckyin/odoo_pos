"""Sync delta endpoint tests."""

from datetime import datetime, timezone

from app.core import db as db_mod
from app.core.security import hash_password
from app.models import Product, Store, Terminal, User


async def _login(client) -> str:
    factory = db_mod.get_session_factory()
    async with factory() as db:
        store = Store(code="S001", name="Demo")
        db.add(store)
        await db.flush()
        db.add(Terminal(store_id=store.id, code="T01", api_key_hash=hash_password("k")))
        db.add(
            User(
                username="admin",
                password_hash=hash_password("admin123"),
                display_name="Admin",
                role="admin",
                store_id=store.id,
            )
        )
        for sku in ("P-1", "P-2", "P-3"):
            db.add(Product(sku=sku, name=sku, price_cents=100))
        await db.commit()
    r = await client.post(
        "/auth/login",
        json={"username": "admin", "password": "admin123", "terminal_code": "T01"},
    )
    return r.json()["access_token"]


async def test_sync_products_returns_all_when_since_epoch(app, client):
    token = await _login(client)
    r = await client.get(
        "/sync/products",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert len(body["items"]) == 3
    assert body["next_since"] is not None


async def test_sync_products_filters_by_since(app, client):
    token = await _login(client)
    r = await client.get(
        "/sync/products",
        params={"since": datetime.now(timezone.utc).isoformat()},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200
    assert r.json()["items"] == []
