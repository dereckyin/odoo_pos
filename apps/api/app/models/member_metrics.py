from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class MemberMetricsDaily(Base, UUIDPrimaryKey, Timestamped):
    """Pre-aggregated member activity for RFM / cohort queries."""

    __tablename__ = "member_metrics_daily"
    __table_args__ = (
        UniqueConstraint("tenant_id", "member_id", "metric_date", name="uq_member_metrics_day"),
    )

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    member_id: Mapped[str] = mapped_column(ForeignKey("members.id"), index=True, nullable=False)
    metric_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    order_count: Mapped[int] = mapped_column(Integer, default=0)
    revenue_cents: Mapped[int] = mapped_column(Integer, default=0)
    last_order_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
