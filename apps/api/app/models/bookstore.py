"""In-store scan-and-go checkouts placed from the TAAZE (讀冊) mobile app.

A checkout holds a short-lived stock reservation until the payment gateway
confirms it; only then is a regular ``Order`` created so POS reports, shifts
and invoices treat it like any other sale.
"""
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class BookstoreCheckout(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "bookstore_checkouts"
    __table_args__ = (
        UniqueConstraint(
            "tenant_id", "customer_ref", "client_request_id", name="uq_bookstore_checkout_request"
        ),
        UniqueConstraint("payment_trade_no", name="uq_bookstore_checkout_trade_no"),
    )

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True, nullable=False)
    customer_ref: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    client_request_id: Mapped[str] = mapped_column(String(64), nullable=False)

    # pending | paid | expired | cancelled | refunded
    status: Mapped[str] = mapped_column(String(16), default="pending", index=True)
    reservation_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    subtotal_cents: Mapped[int] = mapped_column(Integer, default=0)
    tax_cents: Mapped[int] = mapped_column(Integer, default=0)
    total_cents: Mapped[int] = mapped_column(Integer, default=0)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    invoice_carrier_type: Mapped[str | None] = mapped_column(String(32), nullable=True)
    invoice_carrier_code: Mapped[str | None] = mapped_column(String(64), nullable=True)
    invoice_tax_id: Mapped[str | None] = mapped_column(String(16), nullable=True)
    invoice_donation_code: Mapped[str | None] = mapped_column(String(16), nullable=True)
    # none | issued | failed | skipped
    invoice_status: Mapped[str] = mapped_column(String(16), default="none")
    invoice_number: Mapped[str | None] = mapped_column(String(32), nullable=True)

    # cash | online; chosen by the customer, locked once cash is selected
    payment_method: Mapped[str | None] = mapped_column(String(16), nullable=True)
    # total_cents = subtotal_cents - discount_cents
    discount_cents: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    cash_code: Mapped[str | None] = mapped_column(String(8), nullable=True, index=True)
    cash_confirmed_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)

    payment_gateway: Mapped[str | None] = mapped_column(String(32), nullable=True)
    # First 18 chars of every gateway MerchantTradeNo for this checkout; the
    # last 2 are the attempt counter (gateways reject reused trade numbers).
    payment_trade_no: Mapped[str | None] = mapped_column(String(32), nullable=True)
    payment_attempts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    gateway_ref: Mapped[str | None] = mapped_column(String(128), nullable=True)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    paid_after_expiry: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    order_id: Mapped[str | None] = mapped_column(ForeignKey("orders.id"), nullable=True, index=True)

    exit_nonce: Mapped[str | None] = mapped_column(String(32), nullable=True)
    exit_code: Mapped[str | None] = mapped_column(String(8), nullable=True, index=True)
    exit_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    exit_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    exit_verified_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)

    refunded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    refunded_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)

    lines: Mapped[list["BookstoreCheckoutLine"]] = relationship(
        back_populates="checkout", cascade="all, delete-orphan", order_by="BookstoreCheckoutLine.created_at"
    )


class BookstoreCheckoutLine(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "bookstore_checkout_lines"

    checkout_id: Mapped[str] = mapped_column(
        ForeignKey("bookstore_checkouts.id", ondelete="CASCADE"), index=True
    )
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"), index=True)
    product_name: Mapped[str] = mapped_column(String(256))
    sku: Mapped[str] = mapped_column(String(64))
    isbn: Mapped[str | None] = mapped_column(String(32), nullable=True)
    qty: Mapped[int] = mapped_column(Integer)
    unit_price_cents: Mapped[int] = mapped_column(Integer)
    line_total_cents: Mapped[int] = mapped_column(Integer)
    tax_rate: Mapped[float] = mapped_column(default=0.05)

    checkout: Mapped[BookstoreCheckout] = relationship(back_populates="lines")
