"""20260610_0019 — member number + marketing consent.

Adds member_no (per-tenant unique running serial), marketing_opt_in and
marketing_opt_in_at to members. Existing members are backfilled with a
sequential member_no per tenant, and qr_code is populated from member_no when
empty so the value can drive a member QR code.
"""
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260610_0019"
down_revision: Union[str, None] = "20260610_0018"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("members", sa.Column("member_no", sa.String(32), nullable=True))
    op.add_column(
        "members",
        sa.Column(
            "marketing_opt_in",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )
    op.add_column(
        "members",
        sa.Column("marketing_opt_in_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_members_member_no", "members", ["member_no"])
    op.create_unique_constraint(
        "uq_member_tenant_no", "members", ["tenant_id", "member_no"]
    )

    # Backfill member_no per tenant (ordered by joined_at) and qr_code when empty.
    conn = op.get_bind()
    tenant_rows = conn.execute(
        sa.text("SELECT DISTINCT tenant_id FROM members")
    ).fetchall()
    for (tenant_id,) in tenant_rows:
        members = conn.execute(
            sa.text(
                "SELECT id, qr_code FROM members "
                "WHERE tenant_id = :t ORDER BY joined_at ASC, id ASC"
            ),
            {"t": tenant_id},
        ).fetchall()
        serial = 0
        for mid, qr_code in members:
            serial += 1
            member_no = f"M{serial:06d}"
            if qr_code:
                conn.execute(
                    sa.text("UPDATE members SET member_no = :n WHERE id = :id"),
                    {"n": member_no, "id": mid},
                )
            else:
                conn.execute(
                    sa.text(
                        "UPDATE members SET member_no = :n, qr_code = :n WHERE id = :id"
                    ),
                    {"n": member_no, "id": mid},
                )


def downgrade() -> None:
    op.drop_constraint("uq_member_tenant_no", "members", type_="unique")
    op.drop_index("ix_members_member_no", table_name="members")
    op.drop_column("members", "marketing_opt_in_at")
    op.drop_column("members", "marketing_opt_in")
    op.drop_column("members", "member_no")
