from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class BookDetail(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "book_details"

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id", ondelete="CASCADE"), unique=True, index=True)
    barcode: Mapped[str] = mapped_column(String(64), index=True)
    barcode_kind: Mapped[str] = mapped_column(String(16))
    supplier_id: Mapped[str | None] = mapped_column(ForeignKey("suppliers.id"), nullable=True, index=True)
    author: Mapped[str | None] = mapped_column(String(256), nullable=True)
    publisher: Mapped[str | None] = mapped_column(String(256), nullable=True)
    isbn: Mapped[str | None] = mapped_column(String(32), nullable=True)
    list_price_cents: Mapped[int | None] = mapped_column(Integer, nullable=True)
    sale_disc: Mapped[int | None] = mapped_column(Integer, nullable=True)

    product: Mapped["Product"] = relationship(back_populates="book_detail")  # noqa: F821
