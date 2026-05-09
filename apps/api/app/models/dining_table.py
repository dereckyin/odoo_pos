from sqlalchemy import Boolean, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class DiningTable(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    """A physical table in a store. Holds the public token used by the
    customer-facing QR code page (``/order?t=<public_token>``).
    """

    __tablename__ = "dining_tables"
    __table_args__ = (UniqueConstraint("public_token", name="uq_dining_table_token"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), nullable=False, index=True)
    label: Mapped[str] = mapped_column(String(32), nullable=False)
    public_token: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    seats: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    note: Mapped[str | None] = mapped_column(String(256), nullable=True)

    store = relationship("Store", lazy="joined")
