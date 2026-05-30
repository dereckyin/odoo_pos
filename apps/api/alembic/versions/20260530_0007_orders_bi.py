"""20260530_0007 — order_no, order_sequences, store geolocation, order indexes."""

from __future__ import annotations

from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260530_0007"
down_revision: Union[str, None] = "20260530_0006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("order_no", sa.String(32), nullable=True))
    op.create_index("ix_orders_order_no", "orders", ["order_no"])
    op.create_unique_constraint("uq_order_tenant_order_no", "orders", ["tenant_id", "order_no"])

    op.create_table(
        "order_sequences",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False, index=True),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False, index=True),
        sa.Column("business_date", sa.Date(), nullable=False),
        sa.Column("last_seq", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("store_id", "business_date", name="uq_order_seq_store_date"),
    )

    op.add_column("stores", sa.Column("latitude", sa.Float(), nullable=True))
    op.add_column("stores", sa.Column("longitude", sa.Float(), nullable=True))
    op.add_column("stores", sa.Column("geocoded_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("stores", sa.Column("geocode_label", sa.String(256), nullable=True))

    op.create_index(
        "ix_orders_tenant_store_biz_ts",
        "orders",
        ["tenant_id", "store_id", "client_created_at"],
    )

    # Backfill order_no for existing rows (UTC date + store code from join)
    conn = op.get_bind()
    conn.execute(
        sa.text("""
            WITH ranked AS (
                SELECT o.id,
                       s.code AS store_code,
                       to_char(
                           COALESCE(o.client_created_at, o.created_at) AT TIME ZONE 'UTC',
                           'YYYYMMDD'
                       ) AS biz_day,
                       ROW_NUMBER() OVER (
                           PARTITION BY o.store_id,
                               to_char(COALESCE(o.client_created_at, o.created_at) AT TIME ZONE 'UTC', 'YYYYMMDD')
                           ORDER BY COALESCE(o.client_created_at, o.created_at), o.id
                       ) AS seq
                FROM orders o
                JOIN stores s ON s.id = o.store_id
            )
            UPDATE orders
            SET order_no = ranked.store_code || '-' || ranked.biz_day || '-' || LPAD(ranked.seq::text, 4, '0')
            FROM ranked
            WHERE orders.id = ranked.id
        """)
    )

    # Seed order_sequences from backfilled data (PostgreSQL)
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        conn.execute(
            sa.text("""
                INSERT INTO order_sequences (id, tenant_id, store_id, business_date, last_seq, created_at, updated_at)
                SELECT
                    gen_random_uuid()::text,
                    o.tenant_id,
                    o.store_id,
                    (COALESCE(o.client_created_at, o.created_at) AT TIME ZONE 'UTC')::date,
                    MAX(CAST(SPLIT_PART(o.order_no, '-', 3) AS INTEGER)),
                    NOW(),
                    NOW()
                FROM orders o
                WHERE o.order_no IS NOT NULL
                GROUP BY o.tenant_id, o.store_id, (COALESCE(o.client_created_at, o.created_at) AT TIME ZONE 'UTC')::date
            """)
        )


def downgrade() -> None:
    op.drop_index("ix_orders_tenant_store_biz_ts", "orders")
    op.drop_column("stores", "geocode_label")
    op.drop_column("stores", "geocoded_at")
    op.drop_column("stores", "longitude")
    op.drop_column("stores", "latitude")
    op.drop_table("order_sequences")
    op.drop_constraint("uq_order_tenant_order_no", "orders", type_="unique")
    op.drop_index("ix_orders_order_no", "orders")
    op.drop_column("orders", "order_no")
