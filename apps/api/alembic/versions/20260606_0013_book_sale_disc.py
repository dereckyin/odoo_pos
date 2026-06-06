"""Add sale_disc to book_details (TAAZE saleDisc).

Revision ID: 20260606_0013
Revises: 20260606_0012
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "20260606_0013"
down_revision = "20260606_0012"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("book_details", sa.Column("sale_disc", sa.Integer(), nullable=True))


def downgrade() -> None:
    op.drop_column("book_details", "sale_disc")
