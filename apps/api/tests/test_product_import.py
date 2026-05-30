"""Tests for product CSV import."""

from io import BytesIO

from sqlalchemy import select

from app.core import db as db_mod
from app.models import Category, Product

from .helpers import build_tenant, login_admin


async def _create_category_tree(factory, tenant_id: str) -> dict[str, str]:
    async with factory() as db:
        drink = Category(tenant_id=tenant_id, name="飲料")
        db.add(drink)
        await db.flush()
        hand = Category(tenant_id=tenant_id, name="手搖", parent_id=drink.id)
        db.add(hand)
        await db.flush()
        milk = Category(tenant_id=tenant_id, name="奶茶", parent_id=hand.id)
        bento = Category(tenant_id=tenant_id, name="便當/熟食")
        db.add_all([milk, bento])
        await db.commit()
        return {
            "飲料": drink.id,
            "飲料 / 手搖 / 奶茶": milk.id,
            "便當/熟食": bento.id,
        }


def _csv_bytes(content: str) -> bytes:
    return content.encode("utf-8-sig")


async def test_import_csv_resolves_category_path(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    paths = await _create_category_tree(factory, bundle.tenant.id)
    token = await login_admin(client, bundle)

    csv_content = """sku,name,price_cents,category_path,barcode,is_weighted,unit
NEW-001,珍珠奶茶,55,飲料 / 手搖 / 奶茶,NEW-001,0,杯
NEW-002,御便當,95,便當/熟食,NEW-002,0,個
"""
    r = await client.post(
        "/products/import-csv",
        files={"file": ("products.csv", BytesIO(_csv_bytes(csv_content)), "text/csv")},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["created"] == 2
    assert body["skipped"] == 0
    assert body["errors"] == []

    async with factory() as db:
        p1 = (
            await db.execute(
                select(Product).where(Product.tenant_id == bundle.tenant.id, Product.sku == "NEW-001")
            )
        ).scalar_one()
        assert p1.category_id == paths["飲料 / 手搖 / 奶茶"]


async def test_import_csv_skips_unknown_category_path(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    await _create_category_tree(factory, bundle.tenant.id)
    token = await login_admin(client, bundle)

    csv_content = """sku,name,price_cents,category_path,barcode,is_weighted,unit
OK-001,可樂,25,飲料,OK-001,0,個
BAD-001,不存在分類,30,飲料 / 不存在,BAD-001,0,個
"""
    r = await client.post(
        "/products/import-csv",
        files={"file": ("products.csv", BytesIO(_csv_bytes(csv_content)), "text/csv")},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["created"] == 1
    assert body["skipped"] == 1
    assert len(body["errors"]) == 1
    assert body["errors"][0]["sku"] == "BAD-001"
    assert "分類路徑不存在" in body["errors"][0]["message"]


async def test_import_csv_updates_existing_sku(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    await _create_category_tree(factory, bundle.tenant.id)
    token = await login_admin(client, bundle)

    csv_content = """sku,name,price_cents,category_path,barcode,is_weighted,unit
UPD-001,舊名稱,50,飲料,UPD-001,0,個
"""
    r1 = await client.post(
        "/products/import-csv",
        files={"file": ("products.csv", BytesIO(_csv_bytes(csv_content)), "text/csv")},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r1.status_code == 201
    assert r1.json()["created"] == 1

    csv_update = """sku,name,price_cents,category_path,barcode,is_weighted,unit
UPD-001,新名稱,60,飲料,UPD-001,0,個
"""
    r2 = await client.post(
        "/products/import-csv",
        files={"file": ("products.csv", BytesIO(_csv_bytes(csv_update)), "text/csv")},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r2.status_code == 201
    body = r2.json()
    assert body["created"] == 0
    assert body["updated"] == 1

    async with factory() as db:
        p = (
            await db.execute(
                select(Product).where(Product.tenant_id == bundle.tenant.id, Product.sku == "UPD-001")
            )
        ).scalar_one()
        assert p.name == "新名稱"
        assert p.price_cents == 60


async def test_import_csv_template(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_admin(client, bundle)

    r = await client.get(
        "/products/import-csv/template",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200, r.text
    assert "text/csv" in r.headers.get("content-type", "")
    raw = r.content
    assert raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig")
    assert "sku,name,price_cents,category_path" in text
    assert "飲料 / 手搖 / 奶茶" in text
