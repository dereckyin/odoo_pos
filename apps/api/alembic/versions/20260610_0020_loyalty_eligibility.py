"""20260610_0020 — per-product loyalty eligibility flags.

Adds member_discount / points_earn / points_redeem eligibility to categories
(non-null, default true, inherited) and products (nullable override, null =
inherit from the category chain).
"""
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260610_0020"
down_revision: Union[str, None] = "20260610_0019"
branch_labels = None
depends_on = None

_CATEGORY_COLS = (
    "member_discount_eligible",
    "points_earn_eligible",
    "points_redeem_eligible",
)


def upgrade() -> None:
    for col in _CATEGORY_COLS:
        op.add_column(
            "categories",
            sa.Column(col, sa.Boolean(), nullable=False, server_default=sa.true()),
        )
        op.add_column(
            "products",
            sa.Column(col, sa.Boolean(), nullable=True),
        )


def downgrade() -> None:
    for col in _CATEGORY_COLS:
        op.drop_column("products", col)
        op.drop_column("categories", col)
