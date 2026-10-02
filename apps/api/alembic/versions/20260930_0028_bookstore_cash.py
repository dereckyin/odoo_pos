"""Cash-at-counter payment (with store-configurable discount) for bookstore checkouts.

Revision ID: 20260930_0028
Revises: 20260929_0027
Create Date: 2026-09-30
"""
from alembic import op
import sqlalchemy as sa

revision = "20260930_0028"
down_revision = "20260929_0027"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("bookstore_checkouts", sa.Column("payment_method", sa.String(16), nullable=True))
    op.add_column(
        "bookstore_checkouts",
        sa.Column("discount_cents", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column("bookstore_checkouts", sa.Column("cash_code", sa.String(8), nullable=True))
    op.add_column(
        "bookstore_checkouts",
        sa.Column("cash_confirmed_by", sa.String(36), sa.ForeignKey("users.id"), nullable=True),
    )
    op.create_index("ix_bookstore_checkouts_cash_code", "bookstore_checkouts", ["cash_code"])


def downgrade() -> None:
    op.drop_index("ix_bookstore_checkouts_cash_code", table_name="bookstore_checkouts")
    op.drop_column("bookstore_checkouts", "cash_confirmed_by")
    op.drop_column("bookstore_checkouts", "cash_code")
    op.drop_column("bookstore_checkouts", "discount_cents")
    op.drop_column("bookstore_checkouts", "payment_method")
