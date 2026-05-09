from sqlalchemy import Float, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class Category(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "categories"
    __table_args__ = (UniqueConstraint("tenant_id", "name", name="uq_category_tenant_name"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(128), index=True)
    parent_id: Mapped[str | None] = mapped_column(ForeignKey("categories.id"), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    color: Mapped[str | None] = mapped_column(String(16), nullable=True)
    icon: Mapped[str | None] = mapped_column(String(32), nullable=True)


class Product(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "products"
    __table_args__ = (UniqueConstraint("tenant_id", "sku", name="uq_product_tenant_sku"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    sku: Mapped[str] = mapped_column(String(64), index=True)
    name: Mapped[str] = mapped_column(String(256), index=True)
    price_cents: Mapped[int] = mapped_column(Integer, default=0)
    cost_cents: Mapped[int | None] = mapped_column(Integer, nullable=True)
    category_id: Mapped[str | None] = mapped_column(ForeignKey("categories.id"), nullable=True, index=True)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    tax_rate: Mapped[float] = mapped_column(Float, default=0.05)
    is_weighted: Mapped[bool] = mapped_column(default=False)
    unit: Mapped[str] = mapped_column(String(16), default="個")
    is_active: Mapped[bool] = mapped_column(default=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    barcodes: Mapped[list["ProductBarcode"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )


class ProductBarcode(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "product_barcodes"
    __table_args__ = (UniqueConstraint("tenant_id", "barcode", name="uq_barcode_tenant_code"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"), index=True)
    barcode: Mapped[str] = mapped_column(String(64), index=True)

    product: Mapped[Product] = relationship(back_populates="barcodes")
