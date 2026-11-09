"""Bookstore wallet redeem split + zero tax on bookstore orders.

Revision ID: 20261109_0030
Revises: 20261013_0029
Create Date: 2026-11-09
"""
from alembic import op
import sqlalchemy as sa

revision = "20261109_0030"
down_revision = "20261013_0029"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "bookstore_checkouts",
        sa.Column("redeem_bonus_cents", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "bookstore_checkouts",
        sa.Column("redeem_acc_cents", sa.Integer(), nullable=False, server_default="0"),
    )
    # 實體書店對齊免稅發票：既有訂單稅額改 0
    op.execute(
        """
        UPDATE bookstore_checkouts SET tax_cents = 0 WHERE tax_cents <> 0
        """
    )
    op.execute(
        """
        UPDATE orders
           SET tax_cents = 0
         WHERE id IN (
             SELECT order_id FROM bookstore_checkouts WHERE order_id IS NOT NULL
         )
           AND tax_cents <> 0
        """
    )
    # Backfill known wallet split for the 2026-11-09 pilot sale (bonus 4 + acc 3).
    op.execute(
        """
        UPDATE bookstore_checkouts
           SET redeem_bonus_cents = 4,
               redeem_acc_cents = 3
         WHERE id = 'dc3a7365-2706-47bb-b443-5e31c9667c82'
           AND discount_cents = 7
           AND redeem_bonus_cents = 0
           AND redeem_acc_cents = 0
        """
    )


def downgrade() -> None:
    op.drop_column("bookstore_checkouts", "redeem_acc_cents")
    op.drop_column("bookstore_checkouts", "redeem_bonus_cents")
