"""20260610_0023 — three-tier permission support.

- users: employee_id + pin_hash (+ pin lockout) for ID+PIN fast login;
  totp_secret + totp_enabled for layer-1 two-factor auth.
- refunds: approval workflow (status / approver_id / decided_at / reject_reason).
- orders: void approval workflow + shift_id back-reference.
- pos_shifts: cashier shift open/close settlement table.
"""
from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260610_0023"
down_revision: Union[str, None] = "20260610_0022"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # --- pos_shifts (create first; orders.shift_id FKs into it) ---
    op.create_table(
        "pos_shifts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False),
        sa.Column("terminal_id", sa.String(36), sa.ForeignKey("terminals.id"), nullable=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("status", sa.String(16), nullable=False, server_default="open"),
        sa.Column("opened_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("closed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("opening_cash_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("counted_cash_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("expected_cash_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("diff_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("totals_json", sa.JSON(), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_pos_shifts_tenant_id", "pos_shifts", ["tenant_id"])
    op.create_index("ix_pos_shifts_store_id", "pos_shifts", ["store_id"])
    op.create_index("ix_pos_shifts_terminal_id", "pos_shifts", ["terminal_id"])
    op.create_index("ix_pos_shifts_user_id", "pos_shifts", ["user_id"])
    op.create_index("ix_pos_shifts_status", "pos_shifts", ["status"])

    # --- users: PIN + TOTP ---
    op.add_column("users", sa.Column("employee_id", sa.String(32), nullable=True))
    op.add_column("users", sa.Column("pin_hash", sa.String(128), nullable=True))
    op.add_column("users", sa.Column("pin_failed_count", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("users", sa.Column("pin_locked_until", sa.DateTime(timezone=True), nullable=True))
    op.add_column("users", sa.Column("totp_secret", sa.String(64), nullable=True))
    op.add_column("users", sa.Column("totp_enabled", sa.Boolean(), nullable=False, server_default="0"))
    op.create_index("ix_users_employee_id", "users", ["employee_id"])
    op.create_unique_constraint("uq_user_tenant_employee", "users", ["tenant_id", "employee_id"])

    # --- refunds: approval workflow ---
    op.add_column("refunds", sa.Column("status", sa.String(16), nullable=False, server_default="approved"))
    op.add_column("refunds", sa.Column("approver_id", sa.String(36), sa.ForeignKey("users.id"), nullable=True))
    op.add_column("refunds", sa.Column("decided_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("refunds", sa.Column("reject_reason", sa.Text(), nullable=True))
    op.create_index("ix_refunds_status", "refunds", ["status"])

    # --- orders: void workflow + shift back-ref ---
    op.add_column("orders", sa.Column("shift_id", sa.String(36), sa.ForeignKey("pos_shifts.id"), nullable=True))
    op.add_column("orders", sa.Column("void_status", sa.String(16), nullable=True))
    op.add_column("orders", sa.Column("void_reason", sa.Text(), nullable=True))
    op.add_column("orders", sa.Column("voided_by", sa.String(36), sa.ForeignKey("users.id"), nullable=True))
    op.add_column("orders", sa.Column("voided_at", sa.DateTime(timezone=True), nullable=True))
    op.create_index("ix_orders_shift_id", "orders", ["shift_id"])
    op.create_index("ix_orders_void_status", "orders", ["void_status"])


def downgrade() -> None:
    op.drop_index("ix_orders_void_status", table_name="orders")
    op.drop_index("ix_orders_shift_id", table_name="orders")
    op.drop_column("orders", "voided_at")
    op.drop_column("orders", "voided_by")
    op.drop_column("orders", "void_reason")
    op.drop_column("orders", "void_status")
    op.drop_column("orders", "shift_id")

    op.drop_index("ix_refunds_status", table_name="refunds")
    op.drop_column("refunds", "reject_reason")
    op.drop_column("refunds", "decided_at")
    op.drop_column("refunds", "approver_id")
    op.drop_column("refunds", "status")

    op.drop_constraint("uq_user_tenant_employee", "users", type_="unique")
    op.drop_index("ix_users_employee_id", table_name="users")
    op.drop_column("users", "totp_enabled")
    op.drop_column("users", "totp_secret")
    op.drop_column("users", "pin_locked_until")
    op.drop_column("users", "pin_failed_count")
    op.drop_column("users", "pin_hash")
    op.drop_column("users", "employee_id")

    op.drop_index("ix_pos_shifts_status", table_name="pos_shifts")
    op.drop_index("ix_pos_shifts_user_id", table_name="pos_shifts")
    op.drop_index("ix_pos_shifts_terminal_id", table_name="pos_shifts")
    op.drop_index("ix_pos_shifts_store_id", table_name="pos_shifts")
    op.drop_index("ix_pos_shifts_tenant_id", table_name="pos_shifts")
    op.drop_table("pos_shifts")
