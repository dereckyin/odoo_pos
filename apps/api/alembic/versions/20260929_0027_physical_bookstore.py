"""Physical bookstore stores and TAAZE app scan-and-go checkouts.

Revision ID: 20260929_0027
Revises: 20260729_0026
Create Date: 2026-09-29
"""
from alembic import op
import sqlalchemy as sa

revision = "20260929_0027"
down_revision = "20260729_0026"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "stores",
        sa.Column("store_kind", sa.String(16), nullable=False, server_default="restaurant"),
    )
    op.add_column("stores", sa.Column("bookstore_json", sa.JSON(), nullable=True))

    op.create_table(
        "bookstore_checkouts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("customer_ref", sa.String(64), nullable=False),
        sa.Column("client_request_id", sa.String(64), nullable=False),
        sa.Column("status", sa.String(16), nullable=False, server_default="pending"),
        sa.Column("reservation_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("subtotal_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("tax_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("invoice_carrier_type", sa.String(32), nullable=True),
        sa.Column("invoice_carrier_code", sa.String(64), nullable=True),
        sa.Column("invoice_tax_id", sa.String(16), nullable=True),
        sa.Column("invoice_donation_code", sa.String(16), nullable=True),
        sa.Column("invoice_status", sa.String(16), nullable=False, server_default="none"),
        sa.Column("invoice_number", sa.String(32), nullable=True),
        sa.Column("payment_gateway", sa.String(32), nullable=True),
        sa.Column("payment_trade_no", sa.String(32), nullable=True),
        sa.Column("payment_attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("gateway_ref", sa.String(128), nullable=True),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("paid_after_expiry", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("order_id", sa.String(36), sa.ForeignKey("orders.id"), nullable=True),
        sa.Column("exit_nonce", sa.String(32), nullable=True),
        sa.Column("exit_code", sa.String(8), nullable=True),
        sa.Column("exit_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("exit_verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("exit_verified_by", sa.String(36), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("refunded_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("refunded_by", sa.String(36), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint(
            "tenant_id", "customer_ref", "client_request_id", name="uq_bookstore_checkout_request"
        ),
        sa.UniqueConstraint("payment_trade_no", name="uq_bookstore_checkout_trade_no"),
    )
    op.create_index("ix_bookstore_checkouts_tenant_id", "bookstore_checkouts", ["tenant_id"])
    op.create_index("ix_bookstore_checkouts_store_id", "bookstore_checkouts", ["store_id"])
    op.create_index("ix_bookstore_checkouts_customer_ref", "bookstore_checkouts", ["customer_ref"])
    op.create_index("ix_bookstore_checkouts_status", "bookstore_checkouts", ["status"])
    op.create_index("ix_bookstore_checkouts_order_id", "bookstore_checkouts", ["order_id"])
    op.create_index("ix_bookstore_checkouts_exit_code", "bookstore_checkouts", ["exit_code"])

    op.create_table(
        "bookstore_checkout_lines",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "checkout_id",
            sa.String(36),
            sa.ForeignKey("bookstore_checkouts.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("product_id", sa.String(36), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("product_name", sa.String(256), nullable=False),
        sa.Column("sku", sa.String(64), nullable=False),
        sa.Column("isbn", sa.String(32), nullable=True),
        sa.Column("qty", sa.Integer(), nullable=False),
        sa.Column("unit_price_cents", sa.Integer(), nullable=False),
        sa.Column("line_total_cents", sa.Integer(), nullable=False),
        sa.Column("tax_rate", sa.Float(), nullable=False, server_default="0.05"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(
        "ix_bookstore_checkout_lines_checkout_id", "bookstore_checkout_lines", ["checkout_id"]
    )
    op.create_index(
        "ix_bookstore_checkout_lines_product_id", "bookstore_checkout_lines", ["product_id"]
    )


def downgrade() -> None:
    op.drop_table("bookstore_checkout_lines")
    op.drop_table("bookstore_checkouts")
    op.drop_column("stores", "bookstore_json")
    op.drop_column("stores", "store_kind")
