from sqlalchemy import Boolean, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class MarketplaceCategory(Base, UUIDPrimaryKey, Timestamped):
    """Platform-wide feed category for marketplace home (not tenant-scoped)."""

    __tablename__ = "marketplace_categories"
    __table_args__ = (UniqueConstraint("slug", name="uq_marketplace_category_slug"),)

    slug: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(64), nullable=False)
    icon: Mapped[str | None] = mapped_column(String(16), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class MarketplaceCategoryAlias(Base, UUIDPrimaryKey, Timestamped):
    """Maps tenant category names (normalized) to platform feed categories."""

    __tablename__ = "marketplace_category_aliases"
    __table_args__ = (UniqueConstraint("alias_normalized", name="uq_marketplace_category_alias"),)

    alias: Mapped[str] = mapped_column(String(128), nullable=False)
    alias_normalized: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    marketplace_category_id: Mapped[str] = mapped_column(
        ForeignKey("marketplace_categories.id"), index=True, nullable=False
    )

    category: Mapped[MarketplaceCategory] = relationship(lazy="joined")
