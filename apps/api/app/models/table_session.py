from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class TableSession(Base, UUIDPrimaryKey, Timestamped):
    """Short-lived ordering token issued when staff seats a party.

    Printed QR codes embed ``session_token`` instead of the table's static
    ``public_token`` so photographed codes cannot be reused after checkout.
    """

    __tablename__ = "table_sessions"
    __table_args__ = (UniqueConstraint("session_token", name="uq_table_session_token"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True, nullable=False)
    table_id: Mapped[str] = mapped_column(ForeignKey("dining_tables.id"), index=True, nullable=False)
    session_token: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(16), default="open", index=True)
    opened_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    closed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    table = relationship("DiningTable", lazy="joined")
