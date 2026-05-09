"""End-to-end tests for the QR table-side ordering feature."""
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import async_sessionmaker

from app.core import db as db_mod
from app.core.security import hash_password, hash_secret
from app.models import Product, User

from .helpers import build_tenant, login_pos


async def _seed(factory: async_sessionmaker):
    bundle = await build_tenant(factory)
    async with factory() as db:
        kitchen = User(
            tenant_id=bundle.tenant.id,
            username="kitchen1",
            password_hash=hash_password("kitchen"),
            display_name="廚房 1",
            role="kitchen",
            store_id=bundle.store.id,
            is_active=True,
        )
        db.add(kitchen)
        product1 = Product(
            tenant_id=bundle.tenant.id, sku="SKU-1", name="拿鐵", price_cents=80, is_active=True,
        )
        product2 = Product(
            tenant_id=bundle.tenant.id, sku="SKU-2", name="鬆餅", price_cents=120, is_active=True,
        )
        db.add(product1)
        db.add(product2)
        await db.commit()
        await db.refresh(product1)
        await db.refresh(product2)
        return bundle, product1, product2


async def test_table_crud_and_rotate_token(app, client):
    factory = db_mod.get_session_factory()
    bundle, _p1, _p2 = await _seed(factory)
    token = await login_pos(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.post(
        "/admin/tables",
        json={"store_id": bundle.store.id, "label": "A1", "seats": 4},
        headers=headers,
    )
    assert r.status_code == 201, r.text
    table = r.json()
    original_token = table["public_token"]
    assert original_token

    r = await client.post(f"/admin/tables/{table['id']}/rotate-token", headers=headers)
    assert r.status_code == 200
    new_token = r.json()["public_token"]
    assert new_token and new_token != original_token

    r = await client.get(f"/admin/tables?store_id={bundle.store.id}", headers=headers)
    assert r.status_code == 200
    rows = r.json()
    assert len(rows) == 1 and rows[0]["public_token"] == new_token

    r = await client.post(
        "/admin/tables",
        json={"store_id": bundle.store.id, "label": "A1"},
        headers=headers,
    )
    assert r.status_code == 409


async def test_public_endpoint_requires_active_token(app, client):
    factory = db_mod.get_session_factory()
    bundle, p1, _p2 = await _seed(factory)
    token = await login_pos(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.post(
        "/admin/tables",
        json={"store_id": bundle.store.id, "label": "A1"},
        headers=headers,
    )
    table = r.json()
    pt = table["public_token"]

    r = await client.get(f"/public/menu/{pt}")
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["meta"]["table_label"] == "A1"
    assert any(p["id"] == p1.id for p in body["products"])

    r = await client.get("/public/menu/not-a-real-token")
    assert r.status_code == 404


async def test_full_qr_ordering_flow_to_paid_order_merges(app, client):
    factory = db_mod.get_session_factory()
    bundle, p1, p2 = await _seed(factory)
    admin_token = await login_pos(client, bundle)
    kitchen_token = await login_pos(client, bundle, username="kitchen1", password="kitchen")
    admin_h = {"Authorization": f"Bearer {admin_token}"}
    kitchen_h = {"Authorization": f"Bearer {kitchen_token}"}

    r = await client.post(
        "/admin/tables",
        json={"store_id": bundle.store.id, "label": "B7"},
        headers=admin_h,
    )
    assert r.status_code == 201
    pt = r.json()["public_token"]

    r = await client.post(
        f"/public/orders/{pt}",
        json={
            "customer_note": "少冰",
            "party_size": 2,
            "lines": [
                {"product_id": p1.id, "qty": 2, "note": None},
                {"product_id": p2.id, "qty": 1, "note": "切片"},
            ],
        },
    )
    assert r.status_code == 201, r.text
    guest_order = r.json()
    assert guest_order["status"] == "submitted"
    assert guest_order["estimated_subtotal_cents"] == 80 * 2 + 120 * 1
    assert len(guest_order["lines"]) == 2
    gid = guest_order["id"]

    r = await client.get(f"/public/orders/{pt}/{gid}")
    assert r.status_code == 200

    r = await client.get("/guest-orders?status_in=submitted", headers=kitchen_h)
    assert r.status_code == 200
    assert any(o["id"] == gid for o in r.json())

    r = await client.post(f"/guest-orders/{gid}/accept", headers=kitchen_h)
    assert r.status_code == 200
    assert r.json()["status"] == "accepted"

    r = await client.post(f"/guest-orders/{gid}/accept", headers=kitchen_h)
    assert r.status_code == 409

    r = await client.post(f"/guest-orders/{gid}/ready", headers=kitchen_h)
    assert r.status_code == 200
    assert r.json()["status"] == "ready"

    payload = {
        "id": "paid-order-1",
        "store_id": bundle.store.id,
        "terminal_id": bundle.terminal.id,
        "cashier_id": bundle.admin.id,
        "subtotal_cents": 280,
        "discount_cents": 0,
        "tax_cents": 14,
        "total_cents": 294,
        "client_created_at": datetime.now(timezone.utc).isoformat(),
        "source_guest_order_id": gid,
        "lines": [
            {
                "id": "ln-1",
                "product_id": p1.id,
                "product_name": p1.name,
                "sku": p1.sku,
                "qty": 2,
                "unit_price_cents": 80,
                "line_total_cents": 160,
            },
            {
                "id": "ln-2",
                "product_id": p2.id,
                "product_name": p2.name,
                "sku": p2.sku,
                "qty": 1,
                "unit_price_cents": 120,
                "line_total_cents": 120,
            },
        ],
        "payments": [
            {"id": "pay-1", "method": "cash", "amount_cents": 294},
        ],
    }
    r = await client.post("/orders", json=payload, headers=admin_h)
    assert r.status_code == 201, r.text
    paid = r.json()
    assert paid["source_guest_order_id"] == gid

    r = await client.get(f"/guest-orders/{gid}", headers=admin_h)
    assert r.status_code == 200
    g = r.json()
    assert g["status"] == "merged"
    assert g["merged_order_id"] == "paid-order-1"


async def test_cancel_blocks_further_transitions(app, client):
    factory = db_mod.get_session_factory()
    bundle, p1, _p2 = await _seed(factory)
    admin_token = await login_pos(client, bundle)
    h = {"Authorization": f"Bearer {admin_token}"}

    r = await client.post(
        "/admin/tables",
        json={"store_id": bundle.store.id, "label": "C1"},
        headers=h,
    )
    pt = r.json()["public_token"]

    r = await client.post(
        f"/public/orders/{pt}",
        json={"lines": [{"product_id": p1.id, "qty": 1}]},
    )
    gid = r.json()["id"]

    r = await client.post(f"/guest-orders/{gid}/cancel", json={"reason": "test"}, headers=h)
    assert r.status_code == 200
    assert r.json()["status"] == "cancelled"

    r = await client.post(f"/guest-orders/{gid}/accept", headers=h)
    assert r.status_code == 409


async def test_public_menu_is_tenant_scoped_to_table(app, client):
    """Critical regression: the QR's table must only see its own tenant's
    products, never the global catalog."""
    factory = db_mod.get_session_factory()
    a_bundle, a_p, _ = await _seed(factory)
    b_bundle = await build_tenant(
        factory, tenant_code="b-qr",
        store_code="B-S", terminal_code="B-T",
        admin_username="bA", cashier_username="bC",
    )
    async with factory() as db:
        b_only_product = Product(
            tenant_id=b_bundle.tenant.id, sku="ONLY-B", name="Only B",
            price_cents=999, is_active=True,
        )
        db.add(b_only_product)
        await db.commit()
        await db.refresh(b_only_product)

    a_token = await login_pos(client, a_bundle)
    r = await client.post(
        "/admin/tables",
        json={"store_id": a_bundle.store.id, "label": "T1"},
        headers={"Authorization": f"Bearer {a_token}"},
    )
    assert r.status_code == 201
    pt = r.json()["public_token"]

    r = await client.get(f"/public/menu/{pt}")
    assert r.status_code == 200
    skus = {p["sku"] for p in r.json()["products"]}
    assert "ONLY-B" not in skus
    assert "SKU-1" in skus
