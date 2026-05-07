from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class InventoryLevel(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "inventory_levels"
    __table_args__ = (UniqueConstraint("store_id", "product_id", name="uq_inv_store_product"),)

    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True)
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"), index=True)
    on_hand: Mapped[float] = mapped_column(Numeric(12, 3), default=0)
    safety_stock: Mapped[float] = mapped_column(Numeric(12, 3), default=0)
    reserved: Mapped[float] = mapped_column(Numeric(12, 3), default=0)


class InventoryMovement(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "inventory_movements"

    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True)
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"), index=True)
    qty_delta: Mapped[float] = mapped_column(Numeric(12, 3))
    reason: Mapped[str] = mapped_column(String(32), index=True)
    ref_type: Mapped[str | None] = mapped_column(String(32), nullable=True)
    ref_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    terminal_id: Mapped[str | None] = mapped_column(ForeignKey("terminals.id"), nullable=True)
    user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    client_created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class TransferOrder(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "transfer_orders"

    from_store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"))
    to_store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"))
    status: Mapped[str] = mapped_column(String(16), default="draft")
    dispatched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    received_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    lines: Mapped[list["TransferLine"]] = relationship(back_populates="transfer", cascade="all, delete-orphan")


class TransferLine(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "transfer_lines"

    transfer_id: Mapped[str] = mapped_column(ForeignKey("transfer_orders.id", ondelete="CASCADE"))
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"))
    qty: Mapped[float] = mapped_column(Numeric(12, 3))
    received_qty: Mapped[float | None] = mapped_column(Numeric(12, 3), nullable=True)

    transfer: Mapped[TransferOrder] = relationship(back_populates="lines")


class Stocktake(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "stocktakes"

    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    lines: Mapped[list["StocktakeLine"]] = relationship(back_populates="stocktake", cascade="all, delete-orphan")


class StocktakeLine(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "stocktake_lines"

    stocktake_id: Mapped[str] = mapped_column(ForeignKey("stocktakes.id", ondelete="CASCADE"))
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"))
    expected_qty: Mapped[float] = mapped_column(Numeric(12, 3))
    actual_qty: Mapped[float] = mapped_column(Numeric(12, 3))

    stocktake: Mapped[Stocktake] = relationship(back_populates="lines")
