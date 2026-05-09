from app.core import db as db_mod

from .helpers import build_tenant, login_pos


async def test_login_and_create_category(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)

    token = await login_pos(client, bundle)

    r = await client.post(
        "/categories",
        json={"name": "飲料"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["name"] == "飲料"
    assert body["tenant_id"] == bundle.tenant.id


async def test_login_wrong_password(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)

    r = await client.post(
        "/auth/login",
        json={
            "tenant_code": bundle.tenant.code,
            "store_code": bundle.store.code,
            "terminal_code": bundle.terminal.code,
            "terminal_api_key": bundle.terminal_api_key,
            "username": "admin",
            "password": "bad",
        },
    )
    assert r.status_code == 401


async def test_login_wrong_terminal_api_key(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)

    r = await client.post(
        "/auth/login",
        json={
            "tenant_code": bundle.tenant.code,
            "store_code": bundle.store.code,
            "terminal_code": bundle.terminal.code,
            "terminal_api_key": "totally-wrong-key",
            "username": "admin",
            "password": "admin123",
        },
    )
    assert r.status_code == 401


async def test_terminal_register_requires_admin(app, client):
    """The previously-anonymous terminal-register endpoint now requires
    a store-admin (or higher) JWT."""
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)

    # Anonymous: rejected.
    r = await client.post(
        "/auth/terminals/register",
        json={"store_code": bundle.store.code, "terminal_code": "T02"},
    )
    assert r.status_code == 401

    # Cashier (no admin role): rejected.
    cashier_token = await login_pos(client, bundle, username="cashier", password="cashier123")
    r = await client.post(
        "/auth/terminals/register",
        json={"store_code": bundle.store.code, "terminal_code": "T02"},
        headers={"Authorization": f"Bearer {cashier_token}"},
    )
    assert r.status_code == 403

    # Admin: works and returns a fresh api_key.
    admin_token = await login_pos(client, bundle)
    r = await client.post(
        "/auth/terminals/register",
        json={"store_code": bundle.store.code, "terminal_code": "T02"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["api_key"]
    assert body["store_id"] == bundle.store.id
