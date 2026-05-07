from app.core.security import hash_password
from app.models import Store, Terminal, User
from sqlalchemy.ext.asyncio import async_sessionmaker
from app.core import db as db_mod


async def _seed_store_user(factory: async_sessionmaker):
    async with factory() as db:
        store = Store(code="S001", name="Demo")
        db.add(store)
        await db.flush()
        terminal = Terminal(
            store_id=store.id, code="T01", api_key_hash=hash_password("k"),
        )
        db.add(terminal)
        admin = User(
            username="admin",
            password_hash=hash_password("admin123"),
            display_name="Admin",
            role="admin",
            store_id=store.id,
        )
        db.add(admin)
        await db.commit()
        return store, terminal, admin


async def test_login_and_create_category(app, client):
    factory = db_mod.get_session_factory()
    store, terminal, admin = await _seed_store_user(factory)

    r = await client.post(
        "/auth/login",
        json={"username": "admin", "password": "admin123", "terminal_code": "T01"},
    )
    assert r.status_code == 200, r.text
    token = r.json()["access_token"]

    r = await client.post(
        "/categories",
        json={"name": "飲料"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 201, r.text
    assert r.json()["name"] == "飲料"


async def test_login_wrong_password(app, client):
    factory = db_mod.get_session_factory()
    await _seed_store_user(factory)

    r = await client.post(
        "/auth/login",
        json={"username": "admin", "password": "bad", "terminal_code": "T01"},
    )
    assert r.status_code == 401
