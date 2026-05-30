"""20260530_0009 — marketplace listings + guest order channel/fulfillment fields."""

from typing import Union

import sqlalchemy as sa
from alembic import op

revision: str = "20260530_0009"
down_revision: Union[str, None] = "20260530_0008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "marketplace_listings",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False),
        sa.Column("store_id", sa.String(36), sa.ForeignKey("stores.id"), nullable=False, unique=True),
        sa.Column("slug", sa.String(64), nullable=False),
        sa.Column("status", sa.String(16), nullable=False, server_default="draft"),
        sa.Column("display_name", sa.String(128), nullable=False),
        sa.Column("tagline", sa.String(256)),
        sa.Column("logo_url", sa.String(512)),
        sa.Column("banner_url", sa.String(512)),
        sa.Column("cuisine_tags", sa.JSON()),
        sa.Column("min_order_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("delivery_fee_cents", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("delivery_radius_km", sa.Float()),
        sa.Column("supports_pickup", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("supports_delivery", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("supports_dine_in", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("payment_counter", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("payment_online", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("business_hours", sa.JSON()),
        sa.Column("approved_at", sa.DateTime(timezone=True)),
        sa.Column("approved_by_user_id", sa.String(36), sa.ForeignKey("users.id")),
        sa.Column("submitted_at", sa.DateTime(timezone=True)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_marketplace_listings_tenant_id", "marketplace_listings", ["tenant_id"])
    op.create_index("ix_marketplace_listings_store_id", "marketplace_listings", ["store_id"])
    op.create_index("ix_marketplace_listings_slug", "marketplace_listings", ["slug"], unique=True)
    op.create_index("ix_marketplace_listings_status", "marketplace_listings", ["status"])

    op.add_column(
        "dining_tables",
        sa.Column("is_virtual", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )

    op.alter_column("guest_orders", "table_id", existing_type=sa.String(36), nullable=True)
    op.add_column(
        "guest_orders",
        sa.Column("channel", sa.String(16), nullable=False, server_default="table_qr"),
    )
    op.add_column("guest_orders", sa.Column("fulfillment_type", sa.String(16)))
    op.add_column("guest_orders", sa.Column("customer_name", sa.String(64)))
    op.add_column("guest_orders", sa.Column("customer_phone", sa.String(32)))
    op.add_column("guest_orders", sa.Column("delivery_address", sa.String(512)))
    op.add_column("guest_orders", sa.Column("delivery_lat", sa.Float()))
    op.add_column("guest_orders", sa.Column("delivery_lng", sa.Float()))
    op.add_column("guest_orders", sa.Column("delivery_note", sa.String(256)))
    op.add_column("guest_orders", sa.Column("delivery_status", sa.String(16)))
    op.add_column("guest_orders", sa.Column("payment_method", sa.String(16)))
    op.add_column("guest_orders", sa.Column("payment_status", sa.String(16)))
    op.add_column("guest_orders", sa.Column("online_payment_ref", sa.String(128)))
    op.create_index("ix_guest_orders_channel", "guest_orders", ["channel"])


def downgrade() -> None:
    op.drop_index("ix_guest_orders_channel", table_name="guest_orders")
    op.drop_column("guest_orders", "online_payment_ref")
    op.drop_column("guest_orders", "payment_status")
    op.drop_column("guest_orders", "payment_method")
    op.drop_column("guest_orders", "delivery_status")
    op.drop_column("guest_orders", "delivery_note")
    op.drop_column("guest_orders", "delivery_lng")
    op.drop_column("guest_orders", "delivery_lat")
    op.drop_column("guest_orders", "delivery_address")
    op.drop_column("guest_orders", "customer_phone")
    op.drop_column("guest_orders", "customer_name")
    op.drop_column("guest_orders", "fulfillment_type")
    op.drop_column("guest_orders", "channel")
    op.alter_column("guest_orders", "table_id", existing_type=sa.String(36), nullable=False)
    op.drop_column("dining_tables", "is_virtual")
    op.drop_table("marketplace_listings")
