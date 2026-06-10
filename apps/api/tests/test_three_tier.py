"""Three-tier permission features: employee-ID+PIN login, manager PIN override,
shift settlement, and refund/void approval workflow."""
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.core import db as db_mod
from app.core.security import hash_secret
from app.models import Order, Product, Tenant, User

from .helpers import build_tenant, login_admin, login_pos


async def _set_pin(factory, user_id: str, *, employee_id: str, pin: str):
    async with factory() as db:
        user = await db.get(User, user_id)
        user.employee_id = employee_id
        user.pin_hash = hash_secret(pin)
        await db.commit()


async def _add_manager(factory, *, tenant_id: str, store_id: str,
                       employee_id: str, pin: str) -> str:
    async with factory() as db:
        mgr = User(
            tenant_id=tenant_id,
            username="manager",
            password_hash=hash_secret("mgr123"),
            display_name="Store Manager",
            role="store_manager",
            store_id=store_id,
            is_active=True,
            employee_id=employee_id,
            pin_hash=hash_secret(pin),
        )
        db.add(mgr)
        await db.commit()
        await db.refresh(mgr)
        return mgr.id


async def _enable_refund_approval(factory, tenant_id: str):
    async with factory() as db:
        tenant = await db.get(Tenant, tenant_id)
        tenant.settings = {**(tenant.settings or {}), "require_refund_approval": True}
        await db.commit()


async def _seed_product(factory, tenant_id: str, sku: str = "SKU-1") -> Product:
    async with factory() as db:
        p = Product(tenant_id=tenant_id, sku=sku, name="可樂", price_cents=100)
        db.add(p)
        await db.commit()
        await db.refresh(p)
        return p


def _order_payload(bundle, product, oid="order-1"):
    return {
        "id": oid,
        "store_id": bundle.store.id,
        "terminal_id": bundle.terminal.id,
        "status": "paid",
        "subtotal_cents": 200,
        "discount_cents": 0,
        "tax_cents": 0,
        "total_cents": 200,
        "client_created_at": datetime.now(timezone.utc).isoformat(),
        "lines": [
            {
                "id": f"{oid}-l1",
                "product_id": product.id,
                "product_name": product.name,
                "sku": product.sku,
                "qty": 2,
                "unit_price_cents": 100,
                "line_total_cents": 200,
            }
        ],
        "payments": [
            {"id": f"{oid}-p1", "method": "cash", "amount_cents": 200},
        ],
    }


async def test_pin_login_and_manager_override(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    await _set_pin(factory, bundle.cashier.id, employee_id="1001", pin="1234")
    await _add_manager(factory, tenant_id=bundle.tenant.id, store_id=bundle.store.id,
                       employee_id="9001", pin="4321")

    # Employee-ID + PIN fast login on the registered terminal.
    r = await client.post("/auth/pin-login", json={
        "tenant_code": bundle.tenant.code,
        "store_code": bundle.store.code,
        "terminal_code": bundle.terminal.code,
        "terminal_api_key": bundle.terminal_api_key,
        "employee_id": "1001",
        "pin": "1234",
    })
    assert r.status_code == 200, r.text
    cashier_token = r.json()["access_token"]
    assert r.json()["role"] == "cashier"

    # Wrong PIN is rejected.
    bad = await client.post("/auth/pin-login", json={
        "tenant_code": bundle.tenant.code,
        "store_code": bundle.store.code,
        "terminal_code": bundle.terminal.code,
        "terminal_api_key": bundle.terminal_api_key,
        "employee_id": "1001",
        "pin": "0000",
    })
    assert bad.status_code == 401

    headers = {"Authorization": f"Bearer {cashier_token}"}
    # Manager PIN approves an override.
    ok = await client.post("/auth/pin-verify",
                           json={"employee_id": "9001", "pin": "4321", "action": "refund"},
                           headers=headers)
    assert ok.status_code == 200, ok.text
    assert ok.json()["approved"] is True
    assert ok.json()["approver_role"] == "store_manager"

    # A cashier's own PIN lacks override authority.
    nope = await client.post("/auth/pin-verify",
                             json={"employee_id": "1001", "pin": "1234"},
                             headers=headers)
    assert nope.status_code == 403


async def test_shift_open_close_settlement(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    product = await _seed_product(factory, bundle.tenant.id)
    token = await login_pos(client, bundle)  # admin, store-bound
    headers = {"Authorization": f"Bearer {token}"}

    opened = await client.post("/shifts/open",
                               json={"opening_cash_cents": 5000}, headers=headers)
    assert opened.status_code == 201, opened.text

    cur = await client.get("/shifts/current", headers=headers)
    assert cur.status_code == 200 and cur.json() is not None

    up = await client.post("/orders", json=_order_payload(bundle, product), headers=headers)
    assert up.status_code == 201, up.text

    closed = await client.post("/shifts/close",
                               json={"counted_cash_cents": 5200}, headers=headers)
    assert closed.status_code == 200, closed.text
    body = closed.json()
    # expected = opening 5000 + cash sales 200
    assert body["expected_cash_cents"] == 5200
    assert body["diff_cents"] == 0
    assert body["status"] == "closed"


async def test_refund_requires_approval_when_enabled(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    product = await _seed_product(factory, bundle.tenant.id)
    await _enable_refund_approval(factory, bundle.tenant.id)

    # Cashier session (store-bound, role cashier).
    await _set_pin(factory, bundle.cashier.id, employee_id="1001", pin="1234")
    cashier_token = (await client.post("/auth/pin-login", json={
        "tenant_code": bundle.tenant.code,
        "store_code": bundle.store.code,
        "terminal_code": bundle.terminal.code,
        "terminal_api_key": bundle.terminal_api_key,
        "employee_id": "1001",
        "pin": "1234",
    })).json()["access_token"]
    cashier_headers = {"Authorization": f"Bearer {cashier_token}"}

    up = await client.post("/orders", json=_order_payload(bundle, product),
                           headers=cashier_headers)
    assert up.status_code == 201, up.text

    refund = await client.post(
        "/orders/order-1/refund",
        json={"id": "refund-1", "method": "cash", "lines": []},
        headers=cashier_headers,
    )
    assert refund.status_code == 201, refund.text
    assert refund.json()["status"] == "pending"

    # Manager/admin sees and approves it.
    admin_token = await login_admin(client, bundle)
    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    pending = await client.get("/approvals/refunds?status=pending", headers=admin_headers)
    assert pending.status_code == 200, pending.text
    assert any(x["id"] == "refund-1" for x in pending.json())

    approve = await client.post("/approvals/refunds/refund-1/approve", headers=admin_headers)
    assert approve.status_code == 204, approve.text

    async with factory() as db:
        order = await db.get(Order, "order-1")
        assert order.refunded_cents == 200
        assert order.status == "refunded"


async def test_void_by_store_admin_is_auto_approved(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    product = await _seed_product(factory, bundle.tenant.id)
    token = await login_pos(client, bundle)  # admin
    headers = {"Authorization": f"Bearer {token}"}

    up = await client.post("/orders", json=_order_payload(bundle, product), headers=headers)
    assert up.status_code == 201, up.text

    void = await client.post("/approvals/voids",
                             json={"order_id": "order-1", "reason": "test"}, headers=headers)
    assert void.status_code == 201, void.text
    assert void.json()["void_status"] == "approved"
    assert void.json()["status"] == "voided"

    async with factory() as db:
        order = await db.get(Order, "order-1")
        assert order.status == "voided"
        # stock restored: started at 0, sale -2, void +2 => back to 0
        from app.models import InventoryLevel
        lvl = (await db.execute(
            select(InventoryLevel).where(
                InventoryLevel.store_id == bundle.store.id,
                InventoryLevel.product_id == product.id,
            )
        )).scalar_one_or_none()
        assert lvl is not None and float(lvl.on_hand) == 0.0
