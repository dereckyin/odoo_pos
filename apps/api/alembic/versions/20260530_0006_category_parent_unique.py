"""Category hierarchy: unique key per parent + allow same name under different branches.

Revision ID: 20260530_0006
Revises: 20260530_0005
Create Date: 2026-05-30
"""
from __future__ import annotations

from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260530_0006"
down_revision: Union[str, None] = "20260530_0005"
branch_labels = None
depends_on = None


def _drop_unique_if_exists(table: str, name: str) -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing = {c["name"] for c in inspector.get_unique_constraints(table)}
    if name in existing:
        op.drop_constraint(name, table, type_="unique")


def upgrade() -> None:
    for legacy in (
        "uq_category_tenant_name",
        "categories_tenant_id_name_key",
        "uq_categories_tenant_id_name",
    ):
        _drop_unique_if_exists("categories", legacy)

    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing = {c["name"] for c in inspector.get_unique_constraints("categories")}
    if "uq_category_tenant_parent_name" not in existing:
        op.create_unique_constraint(
            "uq_category_tenant_parent_name",
            "categories",
            ["tenant_id", "parent_id", "name"],
        )


def downgrade() -> None:
    _drop_unique_if_exists("categories", "uq_category_tenant_parent_name")
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing = {c["name"] for c in inspector.get_unique_constraints("categories")}
    if "uq_category_tenant_name" not in existing:
        op.create_unique_constraint(
            "uq_category_tenant_name", "categories", ["tenant_id", "name"]
        )
