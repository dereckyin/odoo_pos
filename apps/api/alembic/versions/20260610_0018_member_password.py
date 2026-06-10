"""20260610_0018 — marketplace member password.

Adds password_hash and terms_accepted_at to alliance_members so the unified
marketplace member can register / log in with a traditional account+password
(alongside the existing OTP flow).
"""
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260610_0018"
down_revision: Union[str, None] = "20260610_0017"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "alliance_members",
        sa.Column("password_hash", sa.String(255), nullable=True),
    )
    op.add_column(
        "alliance_members",
        sa.Column("terms_accepted_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("alliance_members", "terms_accepted_at")
    op.drop_column("alliance_members", "password_hash")
