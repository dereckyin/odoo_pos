"""20260610_0015 — marketplace Uber Eats experience + unified member.

Adds:
- marketplace_listings discovery metadata (prep_time_min, rating_avg, rating_count)
- marketplace_reviews table
- guest_orders multi-store grouping + online loyalty columns
- alliance_members referral/birthday columns (unified marketplace member)
- member_favorite_stores, member_referrals, member_wallets, wallet_transactions
"""
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260610_0015"
down_revision: Union[str, None] = "20260606_0014"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # --- marketplace_listings discovery metadata ---
    op.add_column(
        "marketplace_listings",
        sa.Column("prep_time_min", sa.Integer(), nullable=False, server_default="15"),
    )
    op.add_column(
        "marketplace_listings",
        sa.Column("rating_avg", sa.Float(), nullable=False, server_default="0"),
    )
    op.add_column(
        "marketplace_listings",
        sa.Column("rating_count", sa.Integer(), nullable=False, server_default="0"),
    )

    # --- guest_orders multi-store grouping + online loyalty ---
    op.add_column("guest_orders", sa.Column("order_group_id", sa.String(36), nullable=True))
    op.create_index("ix_guest_orders_order_group_id", "guest_orders", ["order_group_id"])
    op.add_column(
        "guest_orders",
        sa.Column("points_redeemed", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column("guest_orders", sa.Column("coupon_code", sa.String(64), nullable=True))
    op.add_column(
        "guest_orders",
        sa.Column("discount_cents", sa.Integer(), nullable=False, server_default="0"),
    )

    # --- alliance_members referral/birthday ---
    op.add_column("alliance_members", sa.Column("referral_code", sa.String(16), nullable=True))
    op.create_index("ix_alliance_members_referral_code", "alliance_members", ["referral_code"])
    op.add_column("alliance_members", sa.Column("birthday", sa.String(10), nullable=True))
    op.add_column("alliance_members", sa.Column("birthday_reward_year", sa.Integer(), nullable=True))

    # --- marketplace_reviews ---
    op.create_table(
        "marketplace_reviews",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("listing_id", sa.String(36), sa.ForeignKey("marketplace_listings.id"), nullable=False),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("guest_order_id", sa.String(36), sa.ForeignKey("guest_orders.id"), nullable=False),
        sa.Column("alliance_member_id", sa.String(36), sa.ForeignKey("alliance_members.id"), nullable=True),
        sa.Column("rating", sa.Integer(), nullable=False),
        sa.Column("comment", sa.Text(), nullable=True),
        sa.Column("author_name", sa.String(64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("guest_order_id", name="uq_marketplace_review_order"),
    )
    op.create_index("ix_marketplace_reviews_listing_id", "marketplace_reviews", ["listing_id"])
    op.create_index("ix_marketplace_reviews_tenant_id", "marketplace_reviews", ["tenant_id"])
    op.create_index("ix_marketplace_reviews_store_id", "marketplace_reviews", ["store_id"])

    # --- member_favorite_stores ---
    op.create_table(
        "member_favorite_stores",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("alliance_member_id", sa.String(36), sa.ForeignKey("alliance_members.id"), nullable=False),
        sa.Column("listing_id", sa.String(36), sa.ForeignKey("marketplace_listings.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("alliance_member_id", "listing_id", name="uq_member_favorite_store"),
    )
    op.create_index("ix_member_favorite_stores_member", "member_favorite_stores", ["alliance_member_id"])
    op.create_index("ix_member_favorite_stores_listing", "member_favorite_stores", ["listing_id"])

    # --- member_referrals ---
    op.create_table(
        "member_referrals",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("alliance_id", sa.String(36), sa.ForeignKey("alliance_networks.id"), nullable=False),
        sa.Column("referrer_member_id", sa.String(36), sa.ForeignKey("alliance_members.id"), nullable=False),
        sa.Column("referee_member_id", sa.String(36), sa.ForeignKey("alliance_members.id"), nullable=False),
        sa.Column("code", sa.String(32), nullable=False),
        sa.Column("reward_points", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("status", sa.String(16), nullable=False, server_default="rewarded"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("referee_member_id", name="uq_member_referral_referee"),
    )
    op.create_index("ix_member_referrals_referrer", "member_referrals", ["referrer_member_id"])
    op.create_index("ix_member_referrals_code", "member_referrals", ["code"])

    # --- member_wallets + wallet_transactions ---
    op.create_table(
        "member_wallets",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("alliance_member_id", sa.String(36), sa.ForeignKey("alliance_members.id"), nullable=False),
        sa.Column("balance_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("alliance_member_id", name="uq_member_wallet_member"),
    )
    op.create_index("ix_member_wallets_member", "member_wallets", ["alliance_member_id"])
    op.create_table(
        "wallet_transactions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("wallet_id", sa.String(36), sa.ForeignKey("member_wallets.id"), nullable=False),
        sa.Column("delta_cents", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(64), nullable=False),
        sa.Column("order_id", sa.String(36), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_wallet_transactions_wallet", "wallet_transactions", ["wallet_id"])
    op.create_index("ix_wallet_transactions_order", "wallet_transactions", ["order_id"])


def downgrade() -> None:
    op.drop_index("ix_wallet_transactions_order", table_name="wallet_transactions")
    op.drop_index("ix_wallet_transactions_wallet", table_name="wallet_transactions")
    op.drop_table("wallet_transactions")
    op.drop_index("ix_member_wallets_member", table_name="member_wallets")
    op.drop_table("member_wallets")

    op.drop_index("ix_member_referrals_code", table_name="member_referrals")
    op.drop_index("ix_member_referrals_referrer", table_name="member_referrals")
    op.drop_table("member_referrals")

    op.drop_index("ix_member_favorite_stores_listing", table_name="member_favorite_stores")
    op.drop_index("ix_member_favorite_stores_member", table_name="member_favorite_stores")
    op.drop_table("member_favorite_stores")

    op.drop_index("ix_marketplace_reviews_store_id", table_name="marketplace_reviews")
    op.drop_index("ix_marketplace_reviews_tenant_id", table_name="marketplace_reviews")
    op.drop_index("ix_marketplace_reviews_listing_id", table_name="marketplace_reviews")
    op.drop_table("marketplace_reviews")

    op.drop_column("alliance_members", "birthday_reward_year")
    op.drop_column("alliance_members", "birthday")
    op.drop_index("ix_alliance_members_referral_code", table_name="alliance_members")
    op.drop_column("alliance_members", "referral_code")

    op.drop_column("guest_orders", "discount_cents")
    op.drop_column("guest_orders", "coupon_code")
    op.drop_column("guest_orders", "points_redeemed")
    op.drop_index("ix_guest_orders_order_group_id", table_name="guest_orders")
    op.drop_column("guest_orders", "order_group_id")

    op.drop_column("marketplace_listings", "rating_count")
    op.drop_column("marketplace_listings", "rating_avg")
    op.drop_column("marketplace_listings", "prep_time_min")
