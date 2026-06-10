"""Cross-store member growth features: favorites, referrals, stored-value wallet.

These hang off the platform-level ``AllianceMember`` (the unified marketplace
identity) rather than tenant-local ``Member`` so the experience is shared
across all marketplace stores.
"""
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class MemberFavoriteStore(Base, UUIDPrimaryKey, Timestamped):
    """A marketplace member's saved/favourite store listing."""

    __tablename__ = "member_favorite_stores"
    __table_args__ = (
        UniqueConstraint(
            "alliance_member_id", "listing_id", name="uq_member_favorite_store"
        ),
    )

    alliance_member_id: Mapped[str] = mapped_column(
        ForeignKey("alliance_members.id"), index=True, nullable=False
    )
    listing_id: Mapped[str] = mapped_column(
        ForeignKey("marketplace_listings.id"), index=True, nullable=False
    )


class MemberReferral(Base, UUIDPrimaryKey, Timestamped):
    """Referral relationship: referrer invites referee via a code."""

    __tablename__ = "member_referrals"
    __table_args__ = (
        UniqueConstraint("referee_member_id", name="uq_member_referral_referee"),
    )

    alliance_id: Mapped[str] = mapped_column(
        ForeignKey("alliance_networks.id"), index=True, nullable=False
    )
    referrer_member_id: Mapped[str] = mapped_column(
        ForeignKey("alliance_members.id"), index=True, nullable=False
    )
    referee_member_id: Mapped[str] = mapped_column(
        ForeignKey("alliance_members.id"), index=True, nullable=False
    )
    code: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    reward_points: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(16), default="rewarded")  # rewarded | pending


class MemberWallet(Base, UUIDPrimaryKey, Timestamped):
    """Cross-store stored-value wallet for a marketplace member."""

    __tablename__ = "member_wallets"
    __table_args__ = (
        UniqueConstraint("alliance_member_id", name="uq_member_wallet_member"),
    )

    alliance_member_id: Mapped[str] = mapped_column(
        ForeignKey("alliance_members.id"), index=True, nullable=False
    )
    balance_cents: Mapped[int] = mapped_column(Integer, default=0, server_default="0")


class WalletTransaction(Base, UUIDPrimaryKey, Timestamped):
    """Append-only stored-value movements."""

    __tablename__ = "wallet_transactions"

    wallet_id: Mapped[str] = mapped_column(
        ForeignKey("member_wallets.id"), index=True, nullable=False
    )
    delta_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    reason: Mapped[str] = mapped_column(String(64), nullable=False)  # topup | spend | refund | bonus
    order_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
