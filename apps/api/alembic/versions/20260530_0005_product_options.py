"""Product option groups, choices, product bindings, order line options_json.

Revision ID: 20260530_0005
Revises: 20260514_0004
Create Date: 2026-05-30
"""
from __future__ import annotations

from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260530_0005"
down_revision: Union[str, None] = "20260514_0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "option_groups",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False, index=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("selection_type", sa.String(16), nullable=False, server_default="single"),
        sa.Column("is_required", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("min_selections", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("max_selections", sa.Integer(), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("tenant_id", "name", name="uq_option_group_tenant_name"),
    )

    op.create_table(
        "option_choices",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("option_group_id", sa.String(36), sa.ForeignKey("option_groups.id"), nullable=False, index=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("price_delta_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_default", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        "product_option_groups",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False, index=True),
        sa.Column("option_group_id", sa.String(36), sa.ForeignKey("option_groups.id"), nullable=False, index=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_required", sa.Boolean(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.UniqueConstraint("product_id", "option_group_id", name="uq_product_option_group"),
    )

    op.create_table(
        "product_option_choice_overrides",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False, index=True),
        sa.Column("option_choice_id", sa.String(36), sa.ForeignKey("option_choices.id"), nullable=False, index=True),
        sa.Column("price_delta_cents", sa.Integer(), nullable=True),
        sa.Column("is_hidden", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.UniqueConstraint("product_id", "option_choice_id", name="uq_product_option_choice_override"),
    )

    op.add_column("order_lines", sa.Column("options_json", sa.JSON(), nullable=True))
    op.add_column("guest_order_lines", sa.Column("options_json", sa.JSON(), nullable=True))


def downgrade() -> None:
    op.drop_column("guest_order_lines", "options_json")
    op.drop_column("order_lines", "options_json")
    op.drop_table("product_option_choice_overrides")
    op.drop_table("product_option_groups")
    op.drop_table("option_choices")
    op.drop_table("option_groups")
