import asyncio
import os
import pathlib

os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("JWT_SECRET", "test-secret")
# Disable network-backed limiter; use in-memory backend in tests.
os.environ.setdefault("RATE_LIMIT_ENABLED", "false")
os.environ.setdefault("ENV", "dev")

import sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))

import pytest
import pytest_asyncio
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core import db as db_mod
from app.core.db import Base
from app.main import create_app
from app.services.marketplace_category_seed import ensure_marketplace_feed_categories


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture
async def app():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    factory = async_sessionmaker(engine, expire_on_commit=False)
    async with factory() as db:
        await ensure_marketplace_feed_categories(db)
    db_mod._engine = engine
    db_mod._session_factory = factory

    app = create_app()
    async with LifespanManager(app):
        yield app
    await engine.dispose()


@pytest_asyncio.fixture
async def client(app):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
