from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, JSON, String, Text, UniqueConstraint
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

    # Uber Eats style discovery metadata.
    prep_time_min: Mapped[int] = mapped_column(Integer, default=15, server_default="15")
    rating_avg: Mapped[float] = mapped_column(Float, default=0.0, server_default="0")
    rating_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    # Price tier: 1=$, 2=$$, 3=$$$ (Foodpanda-style discovery filter).
    price_level: Mapped[int] = mapped_column(Integer, default=2, server_default="2")

    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    approved_by_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    store = relationship("Store", lazy="joined")


class MarketplaceReview(Base, UUIDPrimaryKey, Timestamped):
    """Customer rating + review for a completed marketplace order."""

    __tablename__ = "marketplace_reviews"
    __table_args__ = (
        UniqueConstraint("guest_order_id", name="uq_marketplace_review_order"),
    )

    listing_id: Mapped[str] = mapped_column(
        ForeignKey("marketplace_listings.id"), index=True, nullable=False
    )
    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True, nullable=False)
    guest_order_id: Mapped[str] = mapped_column(
        ForeignKey("guest_orders.id"), index=True, nullable=False
    )
    alliance_member_id: Mapped[str | None] = mapped_column(
        ForeignKey("alliance_members.id"), index=True, nullable=True
    )
    rating: Mapped[int] = mapped_column(Integer, nullable=False)  # 1..5
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    author_name: Mapped[str | None] = mapped_column(String(64), nullable=True)
