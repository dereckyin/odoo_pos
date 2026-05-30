"""Fix __legacy__ tenant contact_email for EmailStr consumers.

Revision ID: 20260530_0011
Revises: 20260530_0010
"""
from alembic import op

revision = "20260530_0011"
down_revision = "20260530_0010"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "UPDATE tenants SET contact_email = 'legacy@example.com' "
        "WHERE contact_email = 'legacy@local'"
    )


def downgrade() -> None:
    op.execute(
        "UPDATE tenants SET contact_email = 'legacy@local' "
        "WHERE code = '__legacy__' AND contact_email = 'legacy@example.com'"
    )
