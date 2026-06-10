from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class AllianceNetwork(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    """Cross-brand loyalty federation managed by platform."""

    __tablename__ = "alliance_networks"

    name: Mapped[str] = mapped_column(String(128))
    code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(16), default="active")  # active | paused


class AllianceMember(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    """Global member identity within an alliance (phone-based)."""

    __tablename__ = "alliance_members"
    __table_args__ = (
        UniqueConstraint("alliance_id", "phone", name="uq_alliance_member_phone"),
    )

    alliance_id: Mapped[str] = mapped_column(ForeignKey("alliance_networks.id"), index=True, nullable=False)
    phone: Mapped[str] = mapped_column(String(32), index=True)
    name: Mapped[str | None] = mapped_column(String(128), nullable=True)
    email: Mapped[str | None] = mapped_column(String(128), nullable=True)
    points: Mapped[int] = mapped_column(Integer, default=0)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # Personal referral code, lazily generated on first member-center load.
    referral_code: Mapped[str | None] = mapped_column(String(16), index=True, nullable=True)
    birthday: Mapped[str | None] = mapped_column(String(10), nullable=True)  # YYYY-MM-DD
    birthday_reward_year: Mapped[int | None] = mapped_column(Integer, nullable=True)


class AllianceTenant(Base, UUIDPrimaryKey, Timestamped):
    """Tenant membership in an alliance."""

    __tablename__ = "alliance_tenants"
    __table_args__ = (
        UniqueConstraint("alliance_id", "tenant_id", name="uq_alliance_tenant"),
    )

    alliance_id: Mapped[str] = mapped_column(ForeignKey("alliance_networks.id"), index=True, nullable=False)
    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    data_scope: Mapped[str] = mapped_column(String(32), default="points")  # profile_only | points | orders_anonymized
    status: Mapped[str] = mapped_column(String(16), default="active")  # pending | active | left
    joined_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class TenantMemberLink(Base, UUIDPrimaryKey, Timestamped):
    """Links tenant-local Member to global AllianceMember."""

    __tablename__ = "tenant_member_links"
    __table_args__ = (
        UniqueConstraint("tenant_id", "member_id", name="uq_tenant_member_link"),
    )

    alliance_id: Mapped[str] = mapped_column(ForeignKey("alliance_networks.id"), index=True, nullable=False)
    alliance_member_id: Mapped[str] = mapped_column(ForeignKey("alliance_members.id"), index=True, nullable=False)
    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    member_id: Mapped[str] = mapped_column(ForeignKey("members.id"), index=True, nullable=False)


class AlliancePointLedger(Base, UUIDPrimaryKey, Timestamped):
    """Append-only alliance-level point movements."""

    __tablename__ = "alliance_point_ledger"

    alliance_id: Mapped[str] = mapped_column(ForeignKey("alliance_networks.id"), index=True, nullable=False)
    alliance_member_id: Mapped[str] = mapped_column(ForeignKey("alliance_members.id"), index=True, nullable=False)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), nullable=True, index=True)
    delta: Mapped[int] = mapped_column(Integer)
    reason: Mapped[str] = mapped_column(String(128))
    order_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
