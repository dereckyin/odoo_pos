from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, JSON, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class Order(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "orders"

    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True)
    terminal_id: Mapped[str] = mapped_column(ForeignKey("terminals.id"), index=True)
    cashier_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    member_id: Mapped[str | None] = mapped_column(ForeignKey("members.id"), nullable=True, index=True)

    status: Mapped[str] = mapped_column(String(16), default="paid", index=True)
    subtotal_cents: Mapped[int] = mapped_column(Integer, default=0)
    discount_cents: Mapped[int] = mapped_column(Integer, default=0)
    tax_cents: Mapped[int] = mapped_column(Integer, default=0)
    total_cents: Mapped[int] = mapped_column(Integer, default=0)
    refunded_cents: Mapped[int] = mapped_column(Integer, default=0)

    invoice_number: Mapped[str | None] = mapped_column(String(32), nullable=True, index=True)
    invoice_carrier: Mapped[str | None] = mapped_column(String(64), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    # When the order originates from a QR-scanned guest_order (table-side
    # ordering), this column carries that guest_order id for reconciliation.
    source_guest_order_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)

    client_created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    lines: Mapped[list["OrderLine"]] = relationship(back_populates="order", cascade="all, delete-orphan")
    payments: Mapped[list["Payment"]] = relationship(back_populates="order", cascade="all, delete-orphan")


class OrderLine(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "order_lines"

    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"), index=True)
    product_name: Mapped[str] = mapped_column(String(256))
    sku: Mapped[str] = mapped_column(String(64))
    qty: Mapped[float] = mapped_column(Numeric(10, 3))
    unit_price_cents: Mapped[int] = mapped_column(Integer)
    line_discount_cents: Mapped[int] = mapped_column(Integer, default=0)
    line_total_cents: Mapped[int] = mapped_column(Integer)
    tax_rate: Mapped[float] = mapped_column(Float, default=0.05)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    order: Mapped[Order] = relationship(back_populates="lines")


class Payment(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "payments"

    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    method: Mapped[str] = mapped_column(String(32))
    amount_cents: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(16), default="captured")
    gateway_ref: Mapped[str | None] = mapped_column(String(128), nullable=True)
    gateway_response: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    tendered_cents: Mapped[int | None] = mapped_column(Integer, nullable=True)
    change_due_cents: Mapped[int | None] = mapped_column(Integer, nullable=True)

    order: Mapped[Order] = relationship(back_populates="payments")


class Refund(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "refunds"

    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"))
    method: Mapped[str] = mapped_column(String(32))
    total_amount_cents: Mapped[int] = mapped_column(Integer)
    reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    gateway_ref: Mapped[str | None] = mapped_column(String(128), nullable=True)

    lines: Mapped[list["RefundLine"]] = relationship(back_populates="refund", cascade="all, delete-orphan")


class RefundLine(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "refund_lines"

    refund_id: Mapped[str] = mapped_column(ForeignKey("refunds.id", ondelete="CASCADE"), index=True)
    order_line_id: Mapped[str] = mapped_column(ForeignKey("order_lines.id"))
    qty: Mapped[float] = mapped_column(Numeric(10, 3))
    amount_cents: Mapped[int] = mapped_column(Integer)

    refund: Mapped[Refund] = relationship(back_populates="lines")
