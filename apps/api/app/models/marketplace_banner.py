from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey

BANNER_LINK_TYPES = ("none", "store", "cuisine", "external")


class MarketplaceBanner(Base, UUIDPrimaryKey, Timestamped):
    """Platform-wide promotional banner/campaign shown on the marketplace home."""

    __tablename__ = "marketplace_banners"

    title: Mapped[str] = mapped_column(String(128), nullable=False)
    subtitle: Mapped[str | None] = mapped_column(String(256), nullable=True)
    image_url: Mapped[str] = mapped_column(String(512), nullable=False)

    # Where tapping the banner goes: none|store|cuisine|external.
    link_type: Mapped[str] = mapped_column(String(16), default="none", server_default="none")
    # store slug / cuisine tag / external url, depending on link_type.
    link_target: Mapped[str | None] = mapped_column(String(512), nullable=True)

    sort_order: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")

    starts_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
