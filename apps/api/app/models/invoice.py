from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class Invoice(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "invoices"
    __table_args__ = (
        UniqueConstraint("tenant_id", "invoice_number", name="uq_invoice_tenant_number"),
    )

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id"), index=True)
    status: Mapped[str] = mapped_column(String(16), default="pending", index=True)
    invoice_number: Mapped[str | None] = mapped_column(String(32), nullable=True)
    invoice_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    total_cents: Mapped[int] = mapped_column(Integer)
    tax_cents: Mapped[int] = mapped_column(Integer)
    tax_type: Mapped[int] = mapped_column(Integer, default=1)

    carrier_type: Mapped[str | None] = mapped_column(String(32), nullable=True)
    carrier_code: Mapped[str | None] = mapped_column(String(64), nullable=True)
    tax_id: Mapped[str | None] = mapped_column(String(16), nullable=True)
    company_name: Mapped[str | None] = mapped_column(String(128), nullable=True)
    donation_code: Mapped[str | None] = mapped_column(String(16), nullable=True)

    gateway: Mapped[str | None] = mapped_column(String(32), nullable=True)
    gateway_ref: Mapped[str | None] = mapped_column(String(128), nullable=True)
    gateway_response: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    last_error: Mapped[str | None] = mapped_column(Text, nullable=True)
