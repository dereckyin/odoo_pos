"""Consignment books: book_details, product_kind, supplier_kind, settlement columns.

Revision ID: 20260606_0012
Revises: 20260530_0011
"""
from __future__ import annotations

from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260606_0012"
down_revision: Union[str, None] = "20260530_0011"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "products",
        sa.Column("product_kind", sa.String(length=32), server_default="regular", nullable=False),
    )
    op.add_column(
        "suppliers",
        sa.Column("supplier_kind", sa.String(length=32), server_default="purchase", nullable=False),
    )
    op.create_table(
        "book_details",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("tenant_id", sa.String(length=36), nullable=False),
        sa.Column("product_id", sa.String(length=36), nullable=False),
        sa.Column("barcode", sa.String(length=64), nullable=False),
        sa.Column("barcode_kind", sa.String(length=16), nullable=False),
        sa.Column("supplier_id", sa.String(length=36), nullable=True),
        sa.Column("author", sa.String(length=256), nullable=True),
        sa.Column("publisher", sa.String(length=256), nullable=True),
        sa.Column("isbn", sa.String(length=32), nullable=True),
        sa.Column("list_price_cents", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["supplier_id"], ["suppliers.id"]),
        sa.ForeignKeyConstraint(["tenant_id"], ["tenants.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("tenant_id", "barcode", name="uq_book_tenant_barcode"),
        sa.UniqueConstraint("product_id", name="uq_book_product"),
    )
    op.create_index(op.f("ix_book_details_tenant_id"), "book_details", ["tenant_id"], unique=False)
    op.create_index(op.f("ix_book_details_product_id"), "book_details", ["product_id"], unique=False)
    op.create_index(op.f("ix_book_details_barcode"), "book_details", ["barcode"], unique=False)

    op.add_column(
        "order_lines",
        sa.Column("product_kind", sa.String(length=32), server_default="regular", nullable=False),
    )
    op.add_column(
        "order_lines",
        sa.Column("consignment_book_share_cents", sa.Integer(), server_default="0", nullable=False),
    )
    op.add_column(
        "order_lines",
        sa.Column("consignment_restaurant_share_cents", sa.Integer(), server_default="0", nullable=False),
    )


def downgrade() -> None:
    op.drop_column("order_lines", "consignment_restaurant_share_cents")
    op.drop_column("order_lines", "consignment_book_share_cents")
    op.drop_column("order_lines", "product_kind")
    op.drop_index(op.f("ix_book_details_barcode"), table_name="book_details")
    op.drop_index(op.f("ix_book_details_product_id"), table_name="book_details")
    op.drop_index(op.f("ix_book_details_tenant_id"), table_name="book_details")
    op.drop_table("book_details")
    op.drop_column("suppliers", "supplier_kind")
    op.drop_column("products", "product_kind")
