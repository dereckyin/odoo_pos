"""Masked member label on bookstore checkouts (shown as the order's member).

Revision ID: 20261013_0029
Revises: 20260930_0028
Create Date: 2026-10-13
"""
from alembic import op
import sqlalchemy as sa

revision = "20261013_0029"
down_revision = "20260930_0028"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("bookstore_checkouts", sa.Column("member_label", sa.String(40), nullable=True))


def downgrade() -> None:
    op.drop_column("bookstore_checkouts", "member_label")
