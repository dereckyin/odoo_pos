from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class MemberLevel(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "member_levels"

    name: Mapped[str] = mapped_column(String(64))
    discount_rate: Mapped[float] = mapped_column(Float, default=1.0)
    min_spend: Mapped[int] = mapped_column(Integer, default=0)
    min_points: Mapped[int] = mapped_column(Integer, default=0)
    color: Mapped[str | None] = mapped_column(String(16), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)


class Member(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "members"

    phone: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(128))
    email: Mapped[str | None] = mapped_column(String(128), nullable=True, index=True)
    birthday: Mapped[date | None] = mapped_column(Date, nullable=True)
    points: Mapped[int] = mapped_column(Integer, default=0)
    total_spent_cents: Mapped[int] = mapped_column(Integer, default=0)
    level_id: Mapped[str | None] = mapped_column(ForeignKey("member_levels.id"), nullable=True)
    qr_code: Mapped[str | None] = mapped_column(String(64), nullable=True, unique=True)
    joined_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    last_visit_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    level: Mapped["MemberLevel | None"] = relationship()


class Coupon(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "coupons"

    code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    type: Mapped[str] = mapped_column(String(16))  # percentage | amount | freeItem
    value: Mapped[float] = mapped_column(Float)
    member_id: Mapped[str | None] = mapped_column(ForeignKey("members.id"), nullable=True, index=True)
    min_spend_cents: Mapped[int] = mapped_column(Integer, default=0)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    used_in_order_id: Mapped[str | None] = mapped_column(String(36), nullable=True)


class PointTransaction(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "point_transactions"

    member_id: Mapped[str] = mapped_column(ForeignKey("members.id"), index=True)
    delta: Mapped[int] = mapped_column(Integer)
    reason: Mapped[str] = mapped_column(String(128))
    order_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
