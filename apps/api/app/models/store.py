from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class Store(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "stores"

    code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(128))
    tax_id: Mapped[str | None] = mapped_column(String(16), nullable=True)
    address: Mapped[str | None] = mapped_column(String(256), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)

    terminals: Mapped[list["Terminal"]] = relationship(back_populates="store", cascade="all, delete-orphan")


class Terminal(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "terminals"

    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True)
    code: Mapped[str] = mapped_column(String(64), index=True)
    api_key_hash: Mapped[str] = mapped_column(String(128))
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    store: Mapped[Store] = relationship(back_populates="terminals")
