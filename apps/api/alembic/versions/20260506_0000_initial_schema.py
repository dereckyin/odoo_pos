"""Initial schema.

Revision ID: 20260506_0000
Revises:
Create Date: 2026-05-06
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260506_0000"
down_revision: Union[str, None] = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "stores",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("code", sa.String(32), nullable=False, unique=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("tax_id", sa.String(16)),
        sa.Column("address", sa.String(256)),
        sa.Column("phone", sa.String(32)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "terminals",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("code", sa.String(64), nullable=False),
        sa.Column("api_key_hash", sa.String(128), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )
    op.create_index("ix_terminals_store_id", "terminals", ["store_id"])
    op.create_index("ix_terminals_code", "terminals", ["code"])

    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("username", sa.String(64), nullable=False, unique=True),
        sa.Column("password_hash", sa.String(128), nullable=False),
        sa.Column("display_name", sa.String(128), nullable=False),
        sa.Column("role", sa.String(32), nullable=False, server_default="cashier"),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id")),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )

    op.create_table(
        "categories",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("parent_id", sa.String(36), sa.ForeignKey("categories.id")),
        sa.Column("sort_order", sa.Integer(), server_default="0"),
        sa.Column("color", sa.String(16)),
        sa.Column("icon", sa.String(32)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )
    op.create_index("ix_categories_name", "categories", ["name"])

    op.create_table(
        "products",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("sku", sa.String(64), nullable=False, unique=True),
        sa.Column("name", sa.String(256), nullable=False),
        sa.Column("price_cents", sa.Integer(), server_default="0"),
        sa.Column("cost_cents", sa.Integer()),
        sa.Column("category_id", sa.String(36), sa.ForeignKey("categories.id")),
        sa.Column("image_url", sa.Text()),
        sa.Column("tax_rate", sa.Float(), server_default="0.05"),
        sa.Column("is_weighted", sa.Boolean(), server_default=sa.text("false")),
        sa.Column("unit", sa.String(16), server_default="個"),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true")),
        sa.Column("description", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )
    op.create_index("ix_products_name", "products", ["name"])
    op.create_index("ix_products_category_id", "products", ["category_id"])

    op.create_table(
        "product_barcodes",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("barcode", sa.String(64), nullable=False, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_product_barcodes_product_id", "product_barcodes", ["product_id"])

    op.create_table(
        "member_levels",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(64), nullable=False),
        sa.Column("discount_rate", sa.Float(), server_default="1.0"),
        sa.Column("min_spend", sa.Integer(), server_default="0"),
        sa.Column("min_points", sa.Integer(), server_default="0"),
        sa.Column("color", sa.String(16)),
        sa.Column("sort_order", sa.Integer(), server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )

    op.create_table(
        "members",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("phone", sa.String(32), nullable=False, unique=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("email", sa.String(128)),
        sa.Column("birthday", sa.Date()),
        sa.Column("points", sa.Integer(), server_default="0"),
        sa.Column("total_spent_cents", sa.Integer(), server_default="0"),
        sa.Column("level_id", sa.String(36), sa.ForeignKey("member_levels.id")),
        sa.Column("qr_code", sa.String(64), unique=True),
        sa.Column("joined_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_visit_at", sa.DateTime(timezone=True)),
        sa.Column("note", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )

    op.create_table(
        "coupons",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("code", sa.String(32), nullable=False, unique=True),
        sa.Column("type", sa.String(16), nullable=False),
        sa.Column("value", sa.Float(), nullable=False),
        sa.Column("member_id", sa.String(36), sa.ForeignKey("members.id")),
        sa.Column("min_spend_cents", sa.Integer(), server_default="0"),
        sa.Column("expires_at", sa.DateTime(timezone=True)),
        sa.Column("used_at", sa.DateTime(timezone=True)),
        sa.Column("used_in_order_id", sa.String(36)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )

    op.create_table(
        "point_transactions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("member_id", sa.String(36), sa.ForeignKey("members.id"), nullable=False),
        sa.Column("delta", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(128), nullable=False),
        sa.Column("order_id", sa.String(36)),
        sa.Column("expires_at", sa.DateTime(timezone=True)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "orders",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("terminal_id", sa.String(36), sa.ForeignKey("terminals.id"), nullable=False),
        sa.Column("cashier_id", sa.String(36), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("member_id", sa.String(36), sa.ForeignKey("members.id")),
        sa.Column("status", sa.String(16), server_default="paid"),
        sa.Column("subtotal_cents", sa.Integer(), server_default="0"),
        sa.Column("discount_cents", sa.Integer(), server_default="0"),
        sa.Column("tax_cents", sa.Integer(), server_default="0"),
        sa.Column("total_cents", sa.Integer(), server_default="0"),
        sa.Column("refunded_cents", sa.Integer(), server_default="0"),
        sa.Column("invoice_number", sa.String(32)),
        sa.Column("invoice_carrier", sa.String(64)),
        sa.Column("note", sa.Text()),
        sa.Column("client_created_at", sa.DateTime(timezone=True)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_orders_member_id", "orders", ["member_id"])
    op.create_index("ix_orders_terminal_id", "orders", ["terminal_id"])

    op.create_table(
        "order_lines",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("order_id", sa.String(36), sa.ForeignKey("orders.id", ondelete="CASCADE"), nullable=False),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("product_name", sa.String(256), nullable=False),
        sa.Column("sku", sa.String(64), nullable=False),
        sa.Column("qty", sa.Numeric(10, 3), nullable=False),
        sa.Column("unit_price_cents", sa.Integer(), nullable=False),
        sa.Column("line_discount_cents", sa.Integer(), server_default="0"),
        sa.Column("line_total_cents", sa.Integer(), nullable=False),
        sa.Column("tax_rate", sa.Float(), server_default="0.05"),
        sa.Column("note", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_order_lines_order_id", "order_lines", ["order_id"])

    op.create_table(
        "payments",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("order_id", sa.String(36), sa.ForeignKey("orders.id", ondelete="CASCADE"), nullable=False),
        sa.Column("method", sa.String(32), nullable=False),
        sa.Column("amount_cents", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(16), server_default="captured"),
        sa.Column("gateway_ref", sa.String(128)),
        sa.Column("gateway_response", sa.JSON()),
        sa.Column("tendered_cents", sa.Integer()),
        sa.Column("change_due_cents", sa.Integer()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_payments_order_id", "payments", ["order_id"])

    op.create_table(
        "refunds",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("order_id", sa.String(36), sa.ForeignKey("orders.id"), nullable=False),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("method", sa.String(32), nullable=False),
        sa.Column("total_amount_cents", sa.Integer(), nullable=False),
        sa.Column("reason", sa.Text()),
        sa.Column("gateway_ref", sa.String(128)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_refunds_order_id", "refunds", ["order_id"])

    op.create_table(
        "refund_lines",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("refund_id", sa.String(36), sa.ForeignKey("refunds.id", ondelete="CASCADE"), nullable=False),
        sa.Column("order_line_id", sa.String(36), sa.ForeignKey("order_lines.id"), nullable=False),
        sa.Column("qty", sa.Numeric(10, 3), nullable=False),
        sa.Column("amount_cents", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "inventory_levels",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("on_hand", sa.Numeric(12, 3), server_default="0"),
        sa.Column("safety_stock", sa.Numeric(12, 3), server_default="0"),
        sa.Column("reserved", sa.Numeric(12, 3), server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("store_id", "product_id", name="uq_inv_store_product"),
    )

    op.create_table(
        "inventory_movements",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("qty_delta", sa.Numeric(12, 3), nullable=False),
        sa.Column("reason", sa.String(32), nullable=False),
        sa.Column("ref_type", sa.String(32)),
        sa.Column("ref_id", sa.String(36)),
        sa.Column("terminal_id", sa.String(36), sa.ForeignKey("terminals.id")),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id")),
        sa.Column("note", sa.Text()),
        sa.Column("client_created_at", sa.DateTime(timezone=True)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_movements_store_product", "inventory_movements", ["store_id", "product_id"])

    op.create_table(
        "transfer_orders",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("from_store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("to_store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("status", sa.String(16), server_default="draft"),
        sa.Column("dispatched_at", sa.DateTime(timezone=True)),
        sa.Column("received_at", sa.DateTime(timezone=True)),
        sa.Column("note", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "transfer_lines",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("transfer_id", sa.String(36), sa.ForeignKey("transfer_orders.id", ondelete="CASCADE"), nullable=False),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("qty", sa.Numeric(12, 3), nullable=False),
        sa.Column("received_qty", sa.Numeric(12, 3)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "stocktakes",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True)),
        sa.Column("note", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "stocktake_lines",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("stocktake_id", sa.String(36), sa.ForeignKey("stocktakes.id", ondelete="CASCADE"), nullable=False),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("expected_qty", sa.Numeric(12, 3), nullable=False),
        sa.Column("actual_qty", sa.Numeric(12, 3), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "promotions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("strategy", sa.String(32), nullable=False),
        sa.Column("config", sa.JSON(), nullable=False),
        sa.Column("priority", sa.Integer(), server_default="0"),
        sa.Column("starts_at", sa.DateTime(timezone=True)),
        sa.Column("ends_at", sa.DateTime(timezone=True)),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true")),
        sa.Column("stackable", sa.Boolean(), server_default=sa.text("false")),
        sa.Column("applicable_product_ids", sa.JSON(), nullable=False),
        sa.Column("applicable_category_ids", sa.JSON(), nullable=False),
        sa.Column("member_level_ids", sa.JSON(), nullable=False),
        sa.Column("description", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )

    op.create_table(
        "invoices",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("order_id", sa.String(36), sa.ForeignKey("orders.id"), nullable=False),
        sa.Column("status", sa.String(16), server_default="pending"),
        sa.Column("invoice_number", sa.String(32), unique=True),
        sa.Column("invoice_date", sa.DateTime(timezone=True)),
        sa.Column("total_cents", sa.Integer(), nullable=False),
        sa.Column("tax_cents", sa.Integer(), nullable=False),
        sa.Column("tax_type", sa.Integer(), server_default="1"),
        sa.Column("carrier_type", sa.String(32)),
        sa.Column("carrier_code", sa.String(64)),
        sa.Column("tax_id", sa.String(16)),
        sa.Column("company_name", sa.String(128)),
        sa.Column("donation_code", sa.String(16)),
        sa.Column("gateway", sa.String(32)),
        sa.Column("gateway_ref", sa.String(128)),
        sa.Column("gateway_response", sa.JSON()),
        sa.Column("last_error", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "idempotency_keys",
        sa.Column("key", sa.String(64), primary_key=True),
        sa.Column("method", sa.String(8), nullable=False),
        sa.Column("path", sa.String(256), nullable=False),
        sa.Column("status_code", sa.Integer(), nullable=False),
        sa.Column("response", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )


def downgrade() -> None:
    for tbl in (
        "idempotency_keys",
        "invoices",
        "promotions",
        "stocktake_lines",
        "stocktakes",
        "transfer_lines",
        "transfer_orders",
        "inventory_movements",
        "inventory_levels",
        "refund_lines",
        "refunds",
        "payments",
        "order_lines",
        "orders",
        "point_transactions",
        "coupons",
        "members",
        "member_levels",
        "product_barcodes",
        "products",
        "categories",
        "users",
        "terminals",
        "stores",
    ):
        op.drop_table(tbl)
