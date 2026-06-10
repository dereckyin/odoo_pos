"""20260610_0016 — marketplace listing price_level tier.

Adds a Foodpanda-style price tier (1=$, 2=$$, 3=$$$) to marketplace_listings
for discovery filtering. Existing rows default to 2 ($$).
"""
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260610_0016"
down_revision: Union[str, None] = "20260610_0015"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "marketplace_listings",
        sa.Column("price_level", sa.Integer(), nullable=False, server_default="2"),
    )


def downgrade() -> None:
    op.drop_column("marketplace_listings", "price_level")
