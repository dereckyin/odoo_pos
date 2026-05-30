from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, JSON, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey

MARKETPLACE_STATUSES = ("draft", "pending", "approved", "suspended")


class MarketplaceListing(Base, UUIDPrimaryKey, Timestamped):
    """Per-store marketplace profile (opt-in). One listing per store."""

    __tablename__ = "marketplace_listings"
    __table_args__ = (UniqueConstraint("slug", name="uq_marketplace_listing_slug"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(
        ForeignKey("stores.id"), unique=True, index=True, nullable=False
    )
    slug: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    status: Mapped[str] = mapped_column(String(16), default="draft", index=True)

    display_name: Mapped[str] = mapped_column(String(128), nullable=False)
    tagline: Mapped[str | None] = mapped_column(String(256), nullable=True)
    logo_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    banner_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    cuisine_tags: Mapped[list | None] = mapped_column(JSON, nullable=True)

    min_order_cents: Mapped[int] = mapped_column(Integer, default=0)
    delivery_fee_cents: Mapped[int] = mapped_column(Integer, default=0)
    delivery_radius_km: Mapped[float | None] = mapped_column(nullable=True)

    supports_pickup: Mapped[bool] = mapped_column(Boolean, default=True)
    supports_delivery: Mapped[bool] = mapped_column(Boolean, default=False)
    supports_dine_in: Mapped[bool] = mapped_column(Boolean, default=False)
    payment_counter: Mapped[bool] = mapped_column(Boolean, default=True)
    payment_online: Mapped[bool] = mapped_column(Boolean, default=False)

    business_hours: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    approved_by_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    store = relationship("Store", lazy="joined")
