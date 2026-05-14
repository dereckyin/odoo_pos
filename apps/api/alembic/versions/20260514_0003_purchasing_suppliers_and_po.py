"""Suppliers + purchase orders + lines (procurement MVP).

Revision ID: 20260514_0003
Revises: 20260509_0002
Create Date: 2026-05-14
"""
from __future__ import annotations

from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260514_0003"
down_revision: Union[str, None] = "20260509_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "suppliers",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("tenant_id", sa.String(length=36), nullable=False),
        sa.Column("code", sa.String(length=32), nullable=False),
        sa.Column("name", sa.String(length=128), nullable=False),
        sa.Column("contact_name", sa.String(length=128), nullable=True),
        sa.Column("phone", sa.String(length=32), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["tenant_id"], ["tenants.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("tenant_id", "code", name="uq_supplier_tenant_code"),
    )
    op.create_index(op.f("ix_suppliers_tenant_id"), "suppliers", ["tenant_id"], unique=False)
    op.create_index(op.f("ix_suppliers_code"), "suppliers", ["code"], unique=False)

    op.create_table(
        "purchase_orders",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("tenant_id", sa.String(length=36), nullable=False),
        sa.Column("store_id", sa.String(length=36), nullable=False),
        sa.Column("supplier_id", sa.String(length=36), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("reference", sa.String(length=64), nullable=True),
        sa.Column("ordered_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["store_id"], ["stores.id"]),
        sa.ForeignKeyConstraint(["supplier_id"], ["suppliers.id"]),
        sa.ForeignKeyConstraint(["tenant_id"], ["tenants.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_purchase_orders_tenant_id"), "purchase_orders", ["tenant_id"], unique=False)
    op.create_index(op.f("ix_purchase_orders_store_id"), "purchase_orders", ["store_id"], unique=False)
    op.create_index(op.f("ix_purchase_orders_supplier_id"), "purchase_orders", ["supplier_id"], unique=False)
    op.create_index(op.f("ix_purchase_orders_status"), "purchase_orders", ["status"], unique=False)

    op.create_table(
        "purchase_order_lines",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("purchase_order_id", sa.String(length=36), nullable=False),
        sa.Column("product_id", sa.String(length=36), nullable=False),
        sa.Column("qty_ordered", sa.Numeric(12, 3), nullable=False),
        sa.Column("qty_received", sa.Numeric(12, 3), nullable=False),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"]),
        sa.ForeignKeyConstraint(["purchase_order_id"], ["purchase_orders.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_purchase_order_lines_purchase_order_id"),
        "purchase_order_lines",
        ["purchase_order_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_purchase_order_lines_product_id"), "purchase_order_lines", ["product_id"], unique=False
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_purchase_order_lines_product_id"), table_name="purchase_order_lines")
    op.drop_index(op.f("ix_purchase_order_lines_purchase_order_id"), table_name="purchase_order_lines")
    op.drop_table("purchase_order_lines")
    op.drop_index(op.f("ix_purchase_orders_status"), table_name="purchase_orders")
    op.drop_index(op.f("ix_purchase_orders_supplier_id"), table_name="purchase_orders")
    op.drop_index(op.f("ix_purchase_orders_store_id"), table_name="purchase_orders")
    op.drop_index(op.f("ix_purchase_orders_tenant_id"), table_name="purchase_orders")
    op.drop_table("purchase_orders")
    op.drop_index(op.f("ix_suppliers_code"), table_name="suppliers")
    op.drop_index(op.f("ix_suppliers_tenant_id"), table_name="suppliers")
    op.drop_table("suppliers")
