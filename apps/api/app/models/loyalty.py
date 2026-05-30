from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, JSON, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class LoyaltyRule(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    """Configurable earn/redeem rules per tenant."""

    __tablename__ = "loyalty_rules"
    __table_args__ = (UniqueConstraint("tenant_id", "name", name="uq_loyalty_rule_tenant_name"),)

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(64))
    rule_type: Mapped[str] = mapped_column(String(16), default="earn")  # earn
    spend_cents: Mapped[int] = mapped_column(Integer, default=100)
    points_awarded: Mapped[int] = mapped_column(Integer, default=1)
    category_ids: Mapped[list] = mapped_column(JSON, default=list)
    level_multiplier: Mapped[float] = mapped_column(Float, default=1.0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    valid_from: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    valid_to: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
