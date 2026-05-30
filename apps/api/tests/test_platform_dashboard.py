"""Platform super-admin dashboard stats."""
from app.core import db as db_mod
from app.core.security import hash_password
from app.models import User

from .helpers import build_tenant, login_admin


async def _seed_platform_super(factory):
    async with factory() as db:
        db.add(
            User(
                username="platform_ops",
                password_hash=hash_password("ops-pass"),
                display_name="Platform Ops",
                role="platform_super",
                is_active=True,
            )
        )
        await db.commit()


async def _login_platform(client):
    r = await client.post(
        "/auth/admin-login",
        json={"username": "platform_ops", "password": "ops-pass"},
    )
    assert r.status_code == 200, r.text
    return r.json()["access_token"]


async def test_platform_dashboard_stats(app, client):
    factory = db_mod.get_session_factory()
    await _seed_platform_super(factory)
    token = await _login_platform(client)
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.get("/platform/dashboard", headers=headers)
    assert r.status_code == 200, r.text
    data = r.json()
    assert "pending_applications" in data
    assert "pending_marketplace_listings" in data
    assert "active_tenants" in data


async def test_platform_dashboard_forbidden_for_tenant(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_admin(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.get("/platform/dashboard", headers=headers)
    assert r.status_code == 403
