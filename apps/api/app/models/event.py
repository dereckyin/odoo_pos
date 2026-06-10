from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey

REGISTRATION_STATUSES = ("registered", "cancelled", "checked_in")


class Event(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    """A tenant event that members can register for (optionally ticketed)."""

    __tablename__ = "events"

    tenant_id: Mapped[str] = mapped_column(
        ForeignKey("tenants.id"), index=True, nullable=False
    )
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    location: Mapped[str | None] = mapped_column(String(256), nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(512), nullable=True)

    starts_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    ends_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # 0 = unlimited capacity.
    capacity: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    price_cents: Mapped[int] = mapped_column(Integer, default=0, server_default="0")

    is_published: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="0"
    )
    list_on_marketplace: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="0"
    )


class EventRegistration(Base, UUIDPrimaryKey, Timestamped):
    """A member's registration / ticket for an event."""

    __tablename__ = "event_registrations"
    __table_args__ = (
        UniqueConstraint("event_id", "ticket_code", name="uq_event_ticket_code"),
    )

    tenant_id: Mapped[str] = mapped_column(
        ForeignKey("tenants.id"), index=True, nullable=False
    )
    event_id: Mapped[str] = mapped_column(
        ForeignKey("events.id"), index=True, nullable=False
    )
    member_id: Mapped[str | None] = mapped_column(
        ForeignKey("members.id"), index=True, nullable=True
    )
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    qty: Mapped[int] = mapped_column(Integer, default=1, server_default="1")
    amount_cents: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    ticket_code: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    status: Mapped[str] = mapped_column(
        String(16), default="registered", server_default="registered"
    )
    checked_in_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
