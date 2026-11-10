"""Bookstore checkout external_mas_no for refund lookup.

Revision ID: 20261110_0031
Revises: 20261109_0030
Create Date: 2026-11-10
"""
from alembic import op
import sqlalchemy as sa

revision = "20261110_0031"
down_revision = "20261109_0030"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "bookstore_checkouts",
        sa.Column("external_mas_no", sa.String(length=16), nullable=True),
    )
    op.create_index(
        "ix_bookstore_checkouts_external_mas_no",
        "bookstore_checkouts",
        ["external_mas_no"],
    )
    op.create_index(
        "ix_bookstore_checkouts_invoice_number",
        "bookstore_checkouts",
        ["invoice_number"],
    )


def downgrade() -> None:
    op.drop_index("ix_bookstore_checkouts_invoice_number", table_name="bookstore_checkouts")
    op.drop_index("ix_bookstore_checkouts_external_mas_no", table_name="bookstore_checkouts")
    op.drop_column("bookstore_checkouts", "external_mas_no")
