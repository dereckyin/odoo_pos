"""Product/category flags: hide from public QR menu vs POS browse grid.

Revision ID: 20260514_0004
Revises: 20260514_0003
Create Date: 2026-05-14
"""
from __future__ import annotations

from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260514_0004"
down_revision: Union[str, None] = "20260514_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "categories",
        sa.Column(
            "hide_from_public_ordering",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
    op.add_column(
        "categories",
        sa.Column(
            "hide_from_pos_browse",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
    op.add_column(
        "products",
        sa.Column(
            "hide_from_public_ordering",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
    op.add_column(
        "products",
        sa.Column(
            "hide_from_pos_browse",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )


def downgrade() -> None:
    op.drop_column("products", "hide_from_pos_browse")
    op.drop_column("products", "hide_from_public_ordering")
    op.drop_column("categories", "hide_from_pos_browse")
    op.drop_column("categories", "hide_from_public_ordering")
