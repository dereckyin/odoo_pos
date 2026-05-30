"""20260530_0008 — loyalty rules, member BI, alliance, webhooks, plan features."""

from __future__ import annotations

import json
from typing import Union
from uuid import uuid4

import sqlalchemy as sa
from alembic import op

revision: str = "20260530_0008"
down_revision: Union[str, None] = "20260530_0007"
branch_labels = None
depends_on = None

PLAN_FEATURES = {
    "starter": {
        "max_members": 500,
        "max_levels": 3,
        "max_loyalty_rules": 1,
        "point_redeem": False,
        "auto_level": False,
        "member_bi": "basic",
        "member_bi_rfm": False,
        "alliance": False,
        "webhooks": False,
        "member_api": False,
    },
    "growth": {
        "max_members": 5000,
        "max_levels": 10,
        "max_loyalty_rules": 5,
        "point_redeem": True,
        "auto_level": True,
        "member_bi": "standard",
        "member_bi_rfm": False,
        "alliance": False,
        "webhooks": False,
        "member_api": False,
    },
    "pro": {
        "max_members": 0,
        "max_levels": 0,
        "max_loyalty_rules": 0,
        "point_redeem": True,
        "auto_level": True,
        "member_bi": "full",
        "member_bi_rfm": True,
        "alliance": False,
        "webhooks": True,
        "member_api": True,
    },
    "enterprise": {
        "max_members": 0,
        "max_levels": 0,
        "max_loyalty_rules": 0,
        "point_redeem": True,
        "auto_level": True,
        "member_bi": "full",
        "member_bi_rfm": True,
        "alliance": True,
        "webhooks": True,
        "member_api": True,
    },
}


def upgrade() -> None:
    op.add_column("orders", sa.Column("points_redeemed", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("orders", sa.Column("coupon_code", sa.String(32), nullable=True))
    op.add_column("guest_orders", sa.Column("member_id", sa.String(36), sa.ForeignKey("members.id"), nullable=True))

    op.add_column(
        "subscription_plans",
        sa.Column("features", sa.JSON(), nullable=False, server_default="{}"),
    )

    op.create_table(
        "loyalty_rules",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False, index=True),
        sa.Column("name", sa.String(64), nullable=False),
        sa.Column("rule_type", sa.String(16), nullable=False, server_default="earn"),
        sa.Column("spend_cents", sa.Integer(), nullable=False, server_default="100"),
        sa.Column("points_awarded", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("category_ids", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("level_multiplier", sa.Float(), nullable=False, server_default="1.0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("valid_from", sa.DateTime(timezone=True), nullable=True),
        sa.Column("valid_to", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("tenant_id", "name", name="uq_loyalty_rule_tenant_name"),
    )

    op.create_table(
        "member_metrics_daily",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False, index=True),
        sa.Column("member_id", sa.String(36), sa.ForeignKey("members.id"), nullable=False, index=True),
        sa.Column("metric_date", sa.Date(), nullable=False, index=True),
        sa.Column("order_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("revenue_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_order_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("tenant_id", "member_id", "metric_date", name="uq_member_metrics_day"),
    )

    op.create_table(
        "alliance_networks",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("code", sa.String(32), nullable=False, unique=True, index=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("status", sa.String(16), nullable=False, server_default="active"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        "alliance_members",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("alliance_id", sa.String(36), sa.ForeignKey("alliance_networks.id"), nullable=False, index=True),
        sa.Column("phone", sa.String(32), nullable=False, index=True),
        sa.Column("name", sa.String(128), nullable=True),
        sa.Column("email", sa.String(128), nullable=True),
        sa.Column("points", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("alliance_id", "phone", name="uq_alliance_member_phone"),
    )

    op.create_table(
        "alliance_tenants",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("alliance_id", sa.String(36), sa.ForeignKey("alliance_networks.id"), nullable=False, index=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False, index=True),
        sa.Column("data_scope", sa.String(32), nullable=False, server_default="points"),
        sa.Column("status", sa.String(16), nullable=False, server_default="active"),
        sa.Column("joined_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("alliance_id", "tenant_id", name="uq_alliance_tenant"),
    )

    op.create_table(
        "tenant_member_links",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("alliance_id", sa.String(36), sa.ForeignKey("alliance_networks.id"), nullable=False, index=True),
        sa.Column("alliance_member_id", sa.String(36), sa.ForeignKey("alliance_members.id"), nullable=False, index=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False, index=True),
        sa.Column("member_id", sa.String(36), sa.ForeignKey("members.id"), nullable=False, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("tenant_id", "member_id", name="uq_tenant_member_link"),
    )

    op.create_table(
        "alliance_point_ledger",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("alliance_id", sa.String(36), sa.ForeignKey("alliance_networks.id"), nullable=False, index=True),
        sa.Column("alliance_member_id", sa.String(36), sa.ForeignKey("alliance_members.id"), nullable=False, index=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=True, index=True),
        sa.Column("delta", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(128), nullable=False),
        sa.Column("order_id", sa.String(36), nullable=True, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "webhook_subscriptions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False, index=True),
        sa.Column("url", sa.String(512), nullable=False),
        sa.Column("secret", sa.String(128), nullable=True),
        sa.Column("events", sa.JSON(), nullable=False, server_default="[]"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "webhook_deliveries",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("subscription_id", sa.String(36), sa.ForeignKey("webhook_subscriptions.id"), nullable=False, index=True),
        sa.Column("event", sa.String(64), nullable=False, index=True),
        sa.Column("payload", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("status", sa.String(16), nullable=False, server_default="pending"),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("delivered_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    conn = op.get_bind()
    for code, feats in PLAN_FEATURES.items():
        conn.execute(
            sa.text(
                "UPDATE subscription_plans SET features = CAST(:feats AS JSON) WHERE code = :code"
            ).bindparams(feats=json.dumps(feats), code=code)
        )

    conn.execute(
        sa.text(
            "INSERT INTO subscription_plans "
            "(id, code, name, price_cents, interval, max_stores, max_terminals, "
            "max_orders_per_month, max_products, features) "
            "VALUES (:id, 'enterprise', 'Enterprise', 999000, 'month', 50, 100, 500000, 100000, "
            "CAST(:feats AS JSON))"
        ).bindparams(id=str(uuid4()), feats=json.dumps(PLAN_FEATURES["enterprise"]))
    )


def downgrade() -> None:
    op.drop_table("webhook_deliveries")
    op.drop_table("webhook_subscriptions")
    op.drop_table("alliance_point_ledger")
    op.drop_table("tenant_member_links")
    op.drop_table("alliance_tenants")
    op.drop_table("alliance_members")
    op.drop_table("alliance_networks")
    op.drop_table("member_metrics_daily")
    op.drop_table("loyalty_rules")
    op.drop_column("subscription_plans", "features")
    op.drop_column("orders", "coupon_code")
    op.drop_column("orders", "points_redeemed")
    op.drop_column("guest_orders", "member_id")
    conn = op.get_bind()
    conn.execute(sa.text("DELETE FROM subscription_plans WHERE code = 'enterprise'"))
