"""Promotion CRUD endpoints smoke test."""

from app.core import db as db_mod

from .helpers import build_tenant, login_pos


async def test_promotion_lifecycle(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_pos(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.post(
        "/promotions",
        headers=headers,
        json={
            "name": "全店九折",
            "strategy": "percentageOff",
            "config": {"percent": 10},
            "priority": 100,
            "is_active": True,
        },
    )
    assert r.status_code == 201, r.text
    pid = r.json()["id"]
    assert r.json()["tenant_id"] == bundle.tenant.id

    r = await client.get("/promotions", headers=headers)
    assert r.status_code == 200
    assert any(p["id"] == pid for p in r.json())

    r = await client.patch(f"/promotions/{pid}", headers=headers, json={"priority": 200})
    assert r.status_code == 200
    assert r.json()["priority"] == 200

    r = await client.delete(f"/promotions/{pid}", headers=headers)
    assert r.status_code == 204

    r = await client.get("/promotions", headers=headers)
    assert all(p["id"] != pid for p in r.json())
