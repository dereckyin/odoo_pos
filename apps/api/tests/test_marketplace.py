"""Marketplace listing and public order flow."""
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.core import db as db_mod
from app.models import MarketplaceListing, Product

from .helpers import build_tenant, login_admin


async def _seed_listing(factory: async_sessionmaker):
    bundle = await build_tenant(factory)
    async with factory() as db:
        product = Product(
            tenant_id=bundle.tenant.id,
            sku="MP-1",
            name="招牌便當",
            price_cents=12000,
            is_active=True,
        )
        db.add(product)
        listing = MarketplaceListing(
            tenant_id=bundle.tenant.id,
            store_id=bundle.store.id,
            slug="test-bento",
            status="approved",
            display_name="測試便當店",
            supports_pickup=True,
            payment_counter=True,
        )
        db.add(listing)
        await db.commit()
        await db.refresh(product)
        await db.refresh(listing)
        return bundle, product, listing


async def test_public_marketplace_list_and_order(app, client):
    factory = db_mod.get_session_factory()
    bundle, product, listing = await _seed_listing(factory)

    r = await client.get("/public/marketplace/stores")
    assert r.status_code == 200
    stores = r.json()
    assert any(s["slug"] == listing.slug for s in stores)

    r = await client.get(f"/public/marketplace/stores/{listing.slug}/menu")
    assert r.status_code == 200
    menu = r.json()
    assert menu["meta"]["slug"] == listing.slug
    assert any(p["id"] == product.id for p in menu["products"])

    r = await client.post(
        f"/public/marketplace/stores/{listing.slug}/orders",
        json={
            "fulfillment_type": "pickup",
            "payment_method": "counter",
            "customer_name": "王小明",
            "customer_phone": "0912345678",
            "lines": [{"product_id": product.id, "qty": 1}],
        },
    )
    assert r.status_code == 201, r.text
    created = r.json()
    assert created["order_id"]
    assert created["access_token"]

    r = await client.get(
        f"/public/marketplace/orders/{created['order_id']}",
        params={"access_token": created["access_token"]},
    )
    assert r.status_code == 200
    assert r.json()["status"] == "submitted"


async def test_marketplace_admin_create_and_submit(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_admin(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.post(
        "/marketplace/listings",
        json={"store_id": bundle.store.id, "display_name": "新店家"},
        headers=headers,
    )
    assert r.status_code == 201, r.text
    listing_id = r.json()["id"]

    r = await client.post(f"/marketplace/listing/{listing_id}/submit", headers=headers)
    assert r.status_code == 200
    assert r.json()["status"] == "pending"
