"""End-to-end tests for the QR table-side ordering feature."""
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import async_sessionmaker

from app.core import db as db_mod
from app.core.security import hash_password
from app.models import Product, Store, Terminal, User


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
        kitchen = User(
            username="kitchen1",
            password_hash=hash_password("kitchen"),
            display_name="廚房 1",
            role="kitchen",
            store_id=store.id,
        )
        db.add(kitchen)
        product1 = Product(sku="SKU-1", name="拿鐵", price_cents=80, is_active=True)
        product2 = Product(sku="SKU-2", name="鬆餅", price_cents=120, is_active=True)
        db.add(product1)
        db.add(product2)
        await db.commit()
        return store, terminal, admin, kitchen, product1, product2


async def _login(client, username, password, terminal_code="T01"):
    r = await client.post(
        "/auth/login",
        json={"username": username, "password": password, "terminal_code": terminal_code},
    )
    assert r.status_code == 200, r.text
    return r.json()["access_token"]


async def test_table_crud_and_rotate_token(app, client):
    factory = db_mod.get_session_factory()
    store, _t, _admin, _kitchen, _p1, _p2 = await _seed(factory)
    token = await _login(client, "admin", "admin123")
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.post(
        "/admin/tables",
        json={"store_id": store.id, "label": "A1", "seats": 4},
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

    # Listing returns the rotated token
    r = await client.get(f"/admin/tables?store_id={store.id}", headers=headers)
    assert r.status_code == 200
    rows = r.json()
    assert len(rows) == 1 and rows[0]["public_token"] == new_token

    # Duplicate label rejected
    r = await client.post(
        "/admin/tables",
        json={"store_id": store.id, "label": "A1"},
        headers=headers,
    )
    assert r.status_code == 409


async def test_public_endpoint_requires_active_token(app, client):
    factory = db_mod.get_session_factory()
    store, _t, _admin, _k, p1, _p2 = await _seed(factory)
    token = await _login(client, "admin", "admin123")
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.post(
        "/admin/tables",
        json={"store_id": store.id, "label": "A1"},
        headers=headers,
    )
    table = r.json()
    pt = table["public_token"]

    # Public menu accessible
    r = await client.get(f"/public/menu/{pt}")
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["meta"]["table_label"] == "A1"
    assert any(p["id"] == p1.id for p in body["products"])

    # Bogus token 404
    r = await client.get("/public/menu/not-a-real-token")
    assert r.status_code == 404


async def test_full_qr_ordering_flow_to_paid_order_merges(app, client):
    factory = db_mod.get_session_factory()
    store, terminal, admin, kitchen, p1, p2 = await _seed(factory)
    admin_token = await _login(client, "admin", "admin123")
    kitchen_token = await _login(client, "kitchen1", "kitchen")
    admin_h = {"Authorization": f"Bearer {admin_token}"}
    kitchen_h = {"Authorization": f"Bearer {kitchen_token}"}

    # 1. Admin creates a table and gets the public token.
    r = await client.post(
        "/admin/tables",
        json={"store_id": store.id, "label": "B7"},
        headers=admin_h,
    )
    assert r.status_code == 201
    pt = r.json()["public_token"]

    # 2. Customer Vue submits an order via the public endpoint.
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

    # Customer can poll the public status endpoint for the same token.
    r = await client.get(f"/public/orders/{pt}/{gid}")
    assert r.status_code == 200

    # 3. KDS lists submitted orders.
    r = await client.get("/guest-orders?status_in=submitted", headers=kitchen_h)
    assert r.status_code == 200
    assert any(o["id"] == gid for o in r.json())

    # 4. KDS accepts -> kitchen ticket would be printed by Flutter.
    r = await client.post(f"/guest-orders/{gid}/accept", headers=kitchen_h)
    assert r.status_code == 200
    assert r.json()["status"] == "accepted"

    # Cannot accept twice.
    r = await client.post(f"/guest-orders/{gid}/accept", headers=kitchen_h)
    assert r.status_code == 409

    # 5. KDS marks ready.
    r = await client.post(f"/guest-orders/{gid}/ready", headers=kitchen_h)
    assert r.status_code == 200
    assert r.json()["status"] == "ready"

    # 6. Cashier (admin) uploads the paid order, stamping
    #    source_guest_order_id. The backend auto-flips the guest_order to
    #    "merged" — see plan: "僅櫃台付".
    payload = {
        "id": "paid-order-1",
        "store_id": store.id,
        "terminal_id": terminal.id,
        "cashier_id": admin.id,
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

    # Guest order is now merged.
    r = await client.get(f"/guest-orders/{gid}", headers=admin_h)
    assert r.status_code == 200
    g = r.json()
    assert g["status"] == "merged"
    assert g["merged_order_id"] == "paid-order-1"


async def test_cancel_blocks_further_transitions(app, client):
    factory = db_mod.get_session_factory()
    store, _t, _admin, _kitchen, p1, _p2 = await _seed(factory)
    admin_token = await _login(client, "admin", "admin123")
    h = {"Authorization": f"Bearer {admin_token}"}

    r = await client.post(
        "/admin/tables",
        json={"store_id": store.id, "label": "C1"},
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

    # accept on a cancelled guest order should now fail
    r = await client.post(f"/guest-orders/{gid}/accept", headers=h)
    assert r.status_code == 409
