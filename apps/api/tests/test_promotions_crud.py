"""Promotion CRUD endpoints smoke test."""

from app.core import db as db_mod
from app.core.security import hash_password
from app.models import Store, Terminal, User


async def _login_admin(client) -> str:
    factory = db_mod.get_session_factory()
    async with factory() as db:
        store = Store(code="S001", name="Demo")
        db.add(store)
        await db.flush()
        db.add(Terminal(store_id=store.id, code="T01", api_key_hash=hash_password("k")))
        db.add(
            User(
                username="admin",
                password_hash=hash_password("admin123"),
                display_name="Admin",
                role="admin",
                store_id=store.id,
            )
        )
        await db.commit()
    r = await client.post(
        "/auth/login",
        json={"username": "admin", "password": "admin123", "terminal_code": "T01"},
    )
    return r.json()["access_token"]


async def test_promotion_lifecycle(app, client):
    token = await _login_admin(client)
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
