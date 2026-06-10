"""20260610_0021 — member SMS broadcast log.

Adds the member_broadcasts table that records each marketing SMS broadcast
(message, audience/sent/failed counts) for marketing-opted-in members.
"""
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260610_0021"
down_revision: Union[str, None] = "20260610_0020"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "member_broadcasts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "tenant_id",
            sa.String(36),
            sa.ForeignKey("tenants.id"),
            nullable=False,
        ),
        sa.Column("channel", sa.String(16), nullable=False, server_default="sms"),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("audience_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("sent_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("failed_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_by", sa.String(36), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index(
        "ix_member_broadcasts_tenant_id", "member_broadcasts", ["tenant_id"]
    )


def downgrade() -> None:
    op.drop_index("ix_member_broadcasts_tenant_id", table_name="member_broadcasts")
    op.drop_table("member_broadcasts")
