from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


GUEST_ORDER_STATUSES = ("submitted", "accepted", "ready", "merged", "cancelled")


class GuestOrder(Base, UUIDPrimaryKey, Timestamped):
    """Customer-facing table-side order placed via the QR code page.

    Lifecycle (see plan):
        submitted -> accepted -> ready -> merged
                                      \\-> cancelled
    Inventory is NOT touched here. Stock and revenue are deducted when the
    cashier merges this into a paid ``Order`` at the counter.
    """

    __tablename__ = "guest_orders"

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), nullable=False, index=True)
    table_id: Mapped[str | None] = mapped_column(
        ForeignKey("dining_tables.id"), nullable=True, index=True
    )
    channel: Mapped[str] = mapped_column(String(16), default="table_qr", nullable=False, index=True)
    fulfillment_type: Mapped[str | None] = mapped_column(String(16), nullable=True)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="submitted", index=True)

    customer_name: Mapped[str | None] = mapped_column(String(64), nullable=True)
    customer_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    delivery_address: Mapped[str | None] = mapped_column(String(512), nullable=True)
    delivery_lat: Mapped[float | None] = mapped_column(nullable=True)
    delivery_lng: Mapped[float | None] = mapped_column(nullable=True)
    delivery_note: Mapped[str | None] = mapped_column(String(256), nullable=True)
    delivery_status: Mapped[str | None] = mapped_column(String(16), nullable=True)

    payment_method: Mapped[str | None] = mapped_column(String(16), nullable=True)
    payment_status: Mapped[str | None] = mapped_column(String(16), nullable=True)
    online_payment_ref: Mapped[str | None] = mapped_column(String(128), nullable=True)

    customer_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    party_size: Mapped[int | None] = mapped_column(Integer, nullable=True)
    member_id: Mapped[str | None] = mapped_column(ForeignKey("members.id"), nullable=True, index=True)

    estimated_subtotal_cents: Mapped[int] = mapped_column(Integer, default=0)

    accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ready_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    merged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    accepted_by_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    merged_order_id: Mapped[str | None] = mapped_column(ForeignKey("orders.id"), nullable=True)
    cancel_reason: Mapped[str | None] = mapped_column(String(256), nullable=True)

    extras: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    lines: Mapped[list["GuestOrderLine"]] = relationship(
        back_populates="order", cascade="all, delete-orphan", order_by="GuestOrderLine.created_at"
    )
    table = relationship("DiningTable", lazy="joined")


class GuestOrderLine(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "guest_order_lines"

    order_id: Mapped[str] = mapped_column(
        ForeignKey("guest_orders.id", ondelete="CASCADE"), nullable=False, index=True
    )
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"), nullable=False, index=True)
    product_name: Mapped[str] = mapped_column(String(256), nullable=False)
    sku: Mapped[str] = mapped_column(String(64), nullable=False)
    qty: Mapped[float] = mapped_column(Numeric(10, 3), nullable=False)
    unit_price_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    line_total_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    options_json: Mapped[list | None] = mapped_column(JSON, nullable=True)

    order: Mapped[GuestOrder] = relationship(back_populates="lines")
