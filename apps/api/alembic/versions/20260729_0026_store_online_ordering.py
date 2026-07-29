"""Store online_ordering_json for unified shopping channel.

Revision ID: 20260729_0026
Revises: 20260703_0025
Create Date: 2026-07-29
"""
from alembic import op
import sqlalchemy as sa

revision = "20260729_0026"
down_revision = "20260703_0025"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "stores",
        sa.Column("online_ordering_json", sa.JSON(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("stores", "online_ordering_json")
