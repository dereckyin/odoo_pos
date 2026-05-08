"""Add dining_tables, guest_orders, guest_order_lines and orders.source_guest_order_id.

Revision ID: 20260508_0001
Revises: 20260506_0000
Create Date: 2026-05-08
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260508_0001"
down_revision: Union[str, None] = "20260506_0000"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "dining_tables",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("label", sa.String(32), nullable=False),
        sa.Column("public_token", sa.String(64), nullable=False, unique=True),
        sa.Column("seats", sa.Integer()),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("note", sa.String(256)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )
    op.create_index("ix_dining_tables_store_id", "dining_tables", ["store_id"])
    op.create_index("ix_dining_tables_public_token", "dining_tables", ["public_token"])

    op.create_table(
        "guest_orders",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("table_id", sa.String(36), sa.ForeignKey("dining_tables.id"), nullable=False),
        sa.Column("status", sa.String(16), nullable=False, server_default="submitted"),
        sa.Column("customer_note", sa.Text()),
        sa.Column("party_size", sa.Integer()),
        sa.Column("estimated_subtotal_cents", sa.Integer(), server_default="0"),
        sa.Column("accepted_at", sa.DateTime(timezone=True)),
        sa.Column("ready_at", sa.DateTime(timezone=True)),
        sa.Column("merged_at", sa.DateTime(timezone=True)),
        sa.Column("cancelled_at", sa.DateTime(timezone=True)),
        sa.Column("accepted_by_user_id", sa.String(36), sa.ForeignKey("users.id")),
        sa.Column("merged_order_id", sa.String(36), sa.ForeignKey("orders.id")),
        sa.Column("cancel_reason", sa.String(256)),
        sa.Column("extras", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_guest_orders_store_id", "guest_orders", ["store_id"])
    op.create_index("ix_guest_orders_table_id", "guest_orders", ["table_id"])
    op.create_index("ix_guest_orders_status", "guest_orders", ["status"])

    op.create_table(
        "guest_order_lines",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "order_id",
            sa.String(36),
            sa.ForeignKey("guest_orders.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("product_name", sa.String(256), nullable=False),
        sa.Column("sku", sa.String(64), nullable=False),
        sa.Column("qty", sa.Numeric(10, 3), nullable=False),
        sa.Column("unit_price_cents", sa.Integer(), nullable=False),
        sa.Column("line_total_cents", sa.Integer(), nullable=False),
        sa.Column("note", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_guest_order_lines_order_id", "guest_order_lines", ["order_id"])

    op.add_column(
        "orders",
        sa.Column("source_guest_order_id", sa.String(36), nullable=True),
    )
    op.create_index("ix_orders_source_guest_order_id", "orders", ["source_guest_order_id"])


def downgrade() -> None:
    op.drop_index("ix_orders_source_guest_order_id", table_name="orders")
    op.drop_column("orders", "source_guest_order_id")
    op.drop_table("guest_order_lines")
    op.drop_table("guest_orders")
    op.drop_table("dining_tables")
