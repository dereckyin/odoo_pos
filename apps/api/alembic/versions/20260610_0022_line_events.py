"""20260610_0022 — LINE binding + events/tickets.

- Adds alliance_members.line_user_id (LINE OA LIFF binding).
- Adds events + event_registrations tables for event registration / ticketing.
"""
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260610_0022"
down_revision: Union[str, None] = "20260610_0021"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "alliance_members",
        sa.Column("line_user_id", sa.String(64), nullable=True),
    )
    op.create_index(
        "ix_alliance_members_line_user_id",
        "alliance_members",
        ["line_user_id"],
    )

    op.create_table(
        "events",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "tenant_id",
            sa.String(36),
            sa.ForeignKey("tenants.id"),
            nullable=False,
        ),
        sa.Column("title", sa.String(160), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("location", sa.String(256), nullable=True),
        sa.Column("image_url", sa.String(512), nullable=True),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("capacity", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("price_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_published", sa.Boolean(), nullable=False, server_default="0"),
        sa.Column(
            "list_on_marketplace", sa.Boolean(), nullable=False, server_default="0"
        ),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
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
    op.create_index("ix_events_tenant_id", "events", ["tenant_id"])

    op.create_table(
        "event_registrations",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "tenant_id",
            sa.String(36),
            sa.ForeignKey("tenants.id"),
            nullable=False,
        ),
        sa.Column(
            "event_id",
            sa.String(36),
            sa.ForeignKey("events.id"),
            nullable=False,
        ),
        sa.Column(
            "member_id",
            sa.String(36),
            sa.ForeignKey("members.id"),
            nullable=True,
            index=True,
        ),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("phone", sa.String(32), nullable=True),
        sa.Column("qty", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("amount_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("ticket_code", sa.String(32), nullable=False),
        sa.Column(
            "status", sa.String(16), nullable=False, server_default="registered"
        ),
        sa.Column("checked_in_at", sa.DateTime(timezone=True), nullable=True),
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
        sa.UniqueConstraint("event_id", "ticket_code", name="uq_event_ticket_code"),
    )
    op.create_index(
        "ix_event_registrations_tenant_id", "event_registrations", ["tenant_id"]
    )
    op.create_index(
        "ix_event_registrations_event_id", "event_registrations", ["event_id"]
    )
    op.create_index(
        "ix_event_registrations_ticket_code",
        "event_registrations",
        ["ticket_code"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_event_registrations_ticket_code", table_name="event_registrations"
    )
    op.drop_index(
        "ix_event_registrations_event_id", table_name="event_registrations"
    )
    op.drop_index(
        "ix_event_registrations_tenant_id", table_name="event_registrations"
    )
    op.drop_table("event_registrations")
    op.drop_index("ix_events_tenant_id", table_name="events")
    op.drop_table("events")
    op.drop_index(
        "ix_alliance_members_line_user_id", table_name="alliance_members"
    )
    op.drop_column("alliance_members", "line_user_id")
