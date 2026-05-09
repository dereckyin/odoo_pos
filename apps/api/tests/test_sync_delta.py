"""Sync delta endpoint tests."""

from datetime import datetime, timezone

from app.core import db as db_mod
from app.models import Product

from .helpers import build_tenant, login_pos


async def _setup(client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    async with factory() as db:
        for sku in ("P-1", "P-2", "P-3"):
            db.add(Product(tenant_id=bundle.tenant.id, sku=sku, name=sku, price_cents=100))
        await db.commit()
    token = await login_pos(client, bundle)
    return token


async def test_sync_products_returns_all_when_since_epoch(app, client):
    token = await _setup(client)
    r = await client.get(
        "/sync/products",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert len(body["items"]) == 3
    assert body["next_since"] is not None


async def test_sync_products_filters_by_since(app, client):
    token = await _setup(client)
    r = await client.get(
        "/sync/products",
        params={"since": datetime.now(timezone.utc).isoformat()},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200
    assert r.json()["items"] == []
