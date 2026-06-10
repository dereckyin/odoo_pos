from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, JSON, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class OrderSequence(Base, UUIDPrimaryKey, Timestamped):
    """Daily per-store sequence for human-readable order numbers."""

    __tablename__ = "order_sequences"
    __table_args__ = (
        UniqueConstraint("store_id", "business_date", name="uq_order_seq_store_date"),
    )

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True, nullable=False)
    business_date: Mapped[date] = mapped_column(Date, nullable=False)
    last_seq: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class Order(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "orders"
    __table_args__ = (
        UniqueConstraint("tenant_id", "order_no", name="uq_order_tenant_order_no"),
    )

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True)
    order_no: Mapped[str | None] = mapped_column(String(32), index=True, nullable=True)
    terminal_id: Mapped[str] = mapped_column(ForeignKey("terminals.id"), index=True)
    cashier_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    member_id: Mapped[str | None] = mapped_column(ForeignKey("members.id"), nullable=True, index=True)

    status: Mapped[str] = mapped_column(String(16), default="paid", index=True)
    subtotal_cents: Mapped[int] = mapped_column(Integer, default=0)
    discount_cents: Mapped[int] = mapped_column(Integer, default=0)
    tax_cents: Mapped[int] = mapped_column(Integer, default=0)
    total_cents: Mapped[int] = mapped_column(Integer, default=0)
    refunded_cents: Mapped[int] = mapped_column(Integer, default=0)
    points_redeemed: Mapped[int] = mapped_column(Integer, default=0)
    coupon_code: Mapped[str | None] = mapped_column(String(32), nullable=True)

    invoice_number: Mapped[str | None] = mapped_column(String(32), nullable=True, index=True)
    invoice_carrier: Mapped[str | None] = mapped_column(String(64), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    source_guest_order_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)

    # Shift settlement: the POS shift this order was rung up in (nullable for legacy).
    shift_id: Mapped[str | None] = mapped_column(ForeignKey("pos_shifts.id"), nullable=True, index=True)

    # Void approval workflow (distinct from refund). When a cashier requests a
    # void it lands as "pending"; a manager approves/rejects.
    void_status: Mapped[str | None] = mapped_column(String(16), nullable=True, index=True)
    void_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    voided_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    voided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

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
    options_json: Mapped[list | None] = mapped_column(JSON, nullable=True)
    product_kind: Mapped[str] = mapped_column(String(32), default="regular")
    consignment_book_share_cents: Mapped[int] = mapped_column(Integer, default=0)
    consignment_restaurant_share_cents: Mapped[int] = mapped_column(Integer, default=0)

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

    # Approval workflow. "approved" keeps the legacy behaviour (immediately
    # effective); "pending" waits for a manager when the tenant requires review.
    status: Mapped[str] = mapped_column(String(16), default="approved", index=True)
    approver_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reject_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    lines: Mapped[list["RefundLine"]] = relationship(back_populates="refund", cascade="all, delete-orphan")


class RefundLine(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "refund_lines"

    refund_id: Mapped[str] = mapped_column(ForeignKey("refunds.id", ondelete="CASCADE"), index=True)
    order_line_id: Mapped[str] = mapped_column(ForeignKey("order_lines.id"))
    qty: Mapped[float] = mapped_column(Numeric(10, 3))
    amount_cents: Mapped[int] = mapped_column(Integer)

    refund: Mapped[Refund] = relationship(back_populates="lines")
