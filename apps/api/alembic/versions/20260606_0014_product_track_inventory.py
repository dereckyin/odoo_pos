"""Add products.track_inventory for optional stock tracking.

Revision ID: 20260606_0014
Revises: 20260606_0013
"""

from alembic import op
import sqlalchemy as sa

revision = "20260606_0014"
down_revision = "20260606_0013"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "products",
        sa.Column("track_inventory", sa.Boolean(), server_default=sa.text("true"), nullable=False),
    )


def downgrade() -> None:
    op.drop_column("products", "track_inventory")
