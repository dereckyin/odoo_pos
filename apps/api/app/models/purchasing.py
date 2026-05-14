from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class Supplier(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "suppliers"
    __table_args__ = (UniqueConstraint("tenant_id", "code", name="uq_supplier_tenant_code"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    code: Mapped[str] = mapped_column(String(32), index=True)
    name: Mapped[str] = mapped_column(String(128))
    contact_name: Mapped[str | None] = mapped_column(String(128), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    purchase_orders: Mapped[list["PurchaseOrder"]] = relationship(back_populates="supplier")


class PurchaseOrder(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "purchase_orders"

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True)
    supplier_id: Mapped[str] = mapped_column(ForeignKey("suppliers.id"), index=True)
    status: Mapped[str] = mapped_column(String(16), default="draft", index=True)
    reference: Mapped[str | None] = mapped_column(String(64), nullable=True)
    ordered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    supplier: Mapped["Supplier"] = relationship(back_populates="purchase_orders")
    lines: Mapped[list["PurchaseOrderLine"]] = relationship(
        back_populates="purchase_order", cascade="all, delete-orphan"
    )


class PurchaseOrderLine(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "purchase_order_lines"

    purchase_order_id: Mapped[str] = mapped_column(
        ForeignKey("purchase_orders.id", ondelete="CASCADE"), index=True
    )
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"), index=True)
    qty_ordered: Mapped[float] = mapped_column(Numeric(12, 3))
    qty_received: Mapped[float] = mapped_column(Numeric(12, 3), default=0)

    purchase_order: Mapped["PurchaseOrder"] = relationship(back_populates="lines")
