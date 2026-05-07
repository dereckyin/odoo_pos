from datetime import datetime

from sqlalchemy import DateTime, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class Promotion(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "promotions"

    name: Mapped[str] = mapped_column(String(128))
    strategy: Mapped[str] = mapped_column(String(32), index=True)
    config: Mapped[dict] = mapped_column(JSON, default=dict)
    priority: Mapped[int] = mapped_column(Integer, default=0)
    starts_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True, index=True)
    stackable: Mapped[bool] = mapped_column(default=False)
    applicable_product_ids: Mapped[list] = mapped_column(JSON, default=list)
    applicable_category_ids: Mapped[list] = mapped_column(JSON, default=list)
    member_level_ids: Mapped[list] = mapped_column(JSON, default=list)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
