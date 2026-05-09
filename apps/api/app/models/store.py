from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class Store(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "stores"
    __table_args__ = (UniqueConstraint("tenant_id", "code", name="uq_store_tenant_code"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    code: Mapped[str] = mapped_column(String(32), index=True)
    name: Mapped[str] = mapped_column(String(128))
    tax_id: Mapped[str | None] = mapped_column(String(16), nullable=True)
    address: Mapped[str | None] = mapped_column(String(256), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)

    terminals: Mapped[list["Terminal"]] = relationship(back_populates="store", cascade="all, delete-orphan")


class Terminal(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "terminals"
    __table_args__ = (UniqueConstraint("store_id", "code", name="uq_terminal_store_code"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True)
    code: Mapped[str] = mapped_column(String(64), index=True)
    api_key_hash: Mapped[str] = mapped_column(String(128))
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    store: Mapped[Store] = relationship(back_populates="terminals")
