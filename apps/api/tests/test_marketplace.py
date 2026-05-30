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


async def test_public_marketplace_products_feed(app, client):
    factory = db_mod.get_session_factory()
    bundle, product, listing = await _seed_listing(factory)

    r = await client.get("/public/marketplace/products")
    assert r.status_code == 200
    products = r.json()
    assert any(p["product_id"] == product.id for p in products)
    assert products[0]["store_is_open"] is True

    r = await client.get("/public/marketplace/products", params={"q": "招牌"})
    assert r.status_code == 200
    assert len(r.json()) >= 1

    r = await client.get("/public/marketplace/products", params={"fulfillment": "pickup"})
    assert r.status_code == 200
    assert all(p["store_slug"] == listing.slug for p in r.json())


async def test_public_marketplace_products_excludes_closed_store(app, client):
    factory = db_mod.get_session_factory()
    bundle, product, listing = await _seed_listing(factory)

    async with factory() as db:
        row = await db.get(MarketplaceListing, listing.id)
        row.business_hours = {"mon": [], "tue": [], "wed": [], "thu": [], "fri": [], "sat": [], "sun": []}
        await db.commit()

    r = await client.get("/public/marketplace/products")
    assert r.status_code == 200
    assert not any(p["product_id"] == product.id for p in r.json())


async def test_marketplace_feed_category_auto_and_override(app, client):
    factory = db_mod.get_session_factory()
    bundle, product, listing = await _seed_listing(factory)

    r = await client.get("/public/marketplace/products")
    assert r.status_code == 200
    hit = next(p for p in r.json() if p["product_id"] == product.id)
    assert hit["feed_category_name"] == "其他"

    from app.models import Category
    from app.services.marketplace_category_seed import CAT_BENTO

    async with factory() as db:
        drink_cat = Category(tenant_id=bundle.tenant.id, name="飲料")
        db.add(drink_cat)
        await db.flush()
        product_row = await db.get(Product, product.id)
        product_row.category_id = drink_cat.id
        await db.commit()

    r = await client.get("/public/marketplace/products")
    hit = next(p for p in r.json() if p["product_id"] == product.id)
    assert hit["feed_category_name"] == "飲料"

    async with factory() as db:
        p = await db.get(Product, product.id)
        p.marketplace_category_id = CAT_BENTO
        await db.commit()

    r = await client.get("/public/marketplace/products")
    hit = next(p for p in r.json() if p["product_id"] == product.id)
    assert hit["feed_category_name"] == "便當"

    r = await client.get("/public/marketplace/products/feed")
    assert r.status_code == 200
    feed = r.json()
    assert feed["sections"]
    assert any(s["category_name"] == "便當" for s in feed["sections"])

    r = await client.get("/public/marketplace/feed-categories")
    assert r.status_code == 200
    cats = r.json()
    assert any(c["name"] == "便當" and c["product_count"] >= 1 for c in cats)
