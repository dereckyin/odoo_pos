"""Phase 3 regression tests:
- audit_logs are written for tenant write operations and readable by admins
- refresh tokens can be rotated, revoked on logout, and revoked on password change.
"""
from app.core import db as db_mod

from .helpers import build_tenant, login_admin, login_pos


async def test_admin_login_writes_audit_log(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)

    token = await login_admin(client, bundle)
    r = await client.get(
        "/tenant/audit-logs",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200, r.text
    rows = r.json()
    actions = {row["action"] for row in rows}
    # admin_login is emitted by /auth/admin-login (see auth.py).
    assert "admin_login" in actions
    # Every audit row must be scoped to this tenant.
    for row in rows:
        assert row["tenant_id"] == bundle.tenant.id


async def test_audit_logs_isolated_per_tenant(app, client):
    factory = db_mod.get_session_factory()
    a = await build_tenant(factory, tenant_code="alpha", store_code="ALPHA",
                           admin_username="alpha_admin", cashier_username="alpha_cashier")
    b = await build_tenant(factory, tenant_code="beta", store_code="BETA",
                           admin_username="beta_admin", cashier_username="beta_cashier")

    a_token = await login_admin(client, a, username="alpha_admin")
    b_token = await login_admin(client, b, username="beta_admin")

    a_rows = (await client.get("/tenant/audit-logs",
                               headers={"Authorization": f"Bearer {a_token}"})).json()
    b_rows = (await client.get("/tenant/audit-logs",
                               headers={"Authorization": f"Bearer {b_token}"})).json()
    # Tenant A admins must NOT see tenant B audit rows and vice versa.
    a_users = {row["user_id"] for row in a_rows}
    b_users = {row["user_id"] for row in b_rows}
    assert b.admin.id not in a_users
    assert a.admin.id not in b_users


async def test_refresh_token_revoked_after_logout(app, client):
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
            "password": "admin123",
        },
    )
    assert r.status_code == 200
    session = r.json()
    access = session["access_token"]
    refresh = session["refresh_token"]

    # Refresh works once.
    r = await client.post("/auth/refresh", json={"refresh_token": refresh})
    assert r.status_code == 200
    new_refresh = r.json()["refresh_token"]

    # The previous refresh token is now revoked (rotation).
    r = await client.post("/auth/refresh", json={"refresh_token": refresh})
    assert r.status_code == 401

    # Logout revokes the still-active refresh token.
    r = await client.post(
        "/auth/logout",
        json={"refresh_token": new_refresh},
        headers={"Authorization": f"Bearer {access}"},
    )
    assert r.status_code == 204
    r = await client.post("/auth/refresh", json={"refresh_token": new_refresh})
    assert r.status_code == 401


async def test_password_change_revokes_all_refresh_tokens(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)

    token = await login_pos(client, bundle)
    r = await client.post(
        "/auth/login",
        json={
            "tenant_code": bundle.tenant.code,
            "store_code": bundle.store.code,
            "terminal_code": bundle.terminal.code,
            "terminal_api_key": bundle.terminal_api_key,
            "username": "admin",
            "password": "admin123",
        },
    )
    refresh = r.json()["refresh_token"]

    r = await client.post(
        "/auth/change-password",
        json={"old_password": "admin123", "new_password": "newpass456"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 204

    # All previously-issued refresh tokens are now revoked.
    r = await client.post("/auth/refresh", json={"refresh_token": refresh})
    assert r.status_code == 401
