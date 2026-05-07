from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from .config import get_settings


class Base(DeclarativeBase):
    """Shared SQLAlchemy declarative base."""


_engine = None
_session_factory: async_sessionmaker[AsyncSession] | None = None


def _build_factory() -> async_sessionmaker[AsyncSession]:
    global _engine, _session_factory
    settings = get_settings()
    _engine = create_async_engine(settings.DATABASE_URL, pool_pre_ping=True, future=True)
    _session_factory = async_sessionmaker(_engine, expire_on_commit=False, class_=AsyncSession)
    return _session_factory


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    return _session_factory or _build_factory()


async def get_db() -> AsyncIterator[AsyncSession]:
    factory = get_session_factory()
    async with factory() as session:
        yield session
