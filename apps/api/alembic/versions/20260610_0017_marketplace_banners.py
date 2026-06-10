"""20260610_0017 — marketplace promotional banners.

Adds a platform-wide marketplace_banners table for home-page banners/campaigns
managed by platform super-admins.
"""
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260610_0017"
down_revision: Union[str, None] = "20260610_0016"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "marketplace_banners",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("title", sa.String(128), nullable=False),
        sa.Column("subtitle", sa.String(256), nullable=True),
        sa.Column("image_url", sa.String(512), nullable=False),
        sa.Column("link_type", sa.String(16), nullable=False, server_default="none"),
        sa.Column("link_target", sa.String(512), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="1"),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
    )


def downgrade() -> None:
    op.drop_table("marketplace_banners")
