"""Printing features: print_label, table_sessions, invoice proof fields, store QR policy.

Revision ID: 20260703_0024
Revises: 20260610_0023
Create Date: 2026-07-03
"""
from alembic import op
import sqlalchemy as sa

revision = "20260703_0024"
down_revision = "20260610_0023"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "products",
        sa.Column("print_label", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.add_column(
        "stores",
        sa.Column("allow_static_table_qr", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column("invoices", sa.Column("random_code", sa.String(8), nullable=True))
    op.add_column("invoices", sa.Column("barcode", sa.String(32), nullable=True))
    op.add_column("invoices", sa.Column("qr_left", sa.Text(), nullable=True))
    op.add_column("invoices", sa.Column("qr_right", sa.Text(), nullable=True))

    op.create_table(
        "table_sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("table_id", sa.String(36), sa.ForeignKey("dining_tables.id"), nullable=False),
        sa.Column("session_token", sa.String(64), nullable=False),
        sa.Column("status", sa.String(16), nullable=False, server_default="open"),
        sa.Column("opened_by", sa.String(36), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("closed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.UniqueConstraint("session_token", name="uq_table_session_token"),
    )
    op.create_index("ix_table_sessions_session_token", "table_sessions", ["session_token"])
    op.create_index("ix_table_sessions_table_id", "table_sessions", ["table_id"])
    op.create_index("ix_table_sessions_status", "table_sessions", ["status"])


def downgrade() -> None:
    op.drop_index("ix_table_sessions_status", table_name="table_sessions")
    op.drop_index("ix_table_sessions_table_id", table_name="table_sessions")
    op.drop_index("ix_table_sessions_session_token", table_name="table_sessions")
    op.drop_table("table_sessions")
    op.drop_column("invoices", "qr_right")
    op.drop_column("invoices", "qr_left")
    op.drop_column("invoices", "barcode")
    op.drop_column("invoices", "random_code")
    op.drop_column("stores", "allow_static_table_qr")
    op.drop_column("products", "print_label")
