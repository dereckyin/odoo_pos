"""Multi-tenant SaaS schema.

Adds the ``tenants`` table, propagates ``tenant_id`` to every business
table, introduces composite uniqueness on tenant-scoped natural keys, and
brings in SaaS-layer tables (applications, OTPs, refresh tokens, audit log,
per-tenant payment / invoice settings, subscription plans + meters).

Backfill strategy: any rows already in the database get attached to a
synthetic ``__legacy__`` tenant so existing dev fixtures keep working.

Revision ID: 20260509_0002
Revises: 20260508_0001
Create Date: 2026-05-09
"""
from __future__ import annotations

from typing import Sequence, Union
from uuid import uuid4

import sqlalchemy as sa
from alembic import op

revision: str = "20260509_0002"
down_revision: Union[str, None] = "20260508_0001"
branch_labels = None
depends_on = None


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

LEGACY_TENANT_ID = "00000000-0000-4000-8000-000000000001"

# Tables that gain a ``tenant_id`` column. The list is ordered so that
# parent tables (referenced by FKs) come before children.
TENANT_SCOPED_TABLES: tuple[tuple[str, bool], ...] = (
    # (table, nullable?). nullable=True is used only for ``users`` so the
    # platform super-admin can stay unattached.
    ("stores", False),
    ("terminals", False),
    ("users", True),
    ("categories", False),
    ("products", False),
    ("product_barcodes", False),
    ("member_levels", False),
    ("members", False),
    ("coupons", False),
    ("point_transactions", False),
    ("orders", False),
    ("inventory_levels", False),
    ("inventory_movements", False),
    ("transfer_orders", False),
    ("stocktakes", False),
    ("promotions", False),
    ("invoices", False),
    ("dining_tables", False),
    ("guest_orders", False),
)


def _drop_unique(table: str, column: str) -> None:
    """Best-effort drop of the auto-generated single-column unique we
    inherited from the initial schema. Different backends name them
    differently, so we cycle through plausible names."""
    candidates = [f"{table}_{column}_key", f"uq_{table}_{column}", f"{table}_{column}_uq"]
    bind = op.get_bind()
    dialect = bind.dialect.name
    for name in candidates:
        try:
            if dialect == "sqlite":
                # SQLite cannot drop unique constraints in-place; the column
                # must be redefined. We rely on batch_alter_table below to
                # rebuild the table.
                continue
            op.drop_constraint(name, table, type_="unique")
            return
        except Exception:  # noqa: BLE001
            continue


def _add_tenant_column(table: str, *, nullable: bool) -> None:
    op.add_column(
        table,
        sa.Column("tenant_id", sa.String(36), nullable=True),
    )
    op.execute(
        sa.text(f"UPDATE {table} SET tenant_id = :tid").bindparams(tid=LEGACY_TENANT_ID)
    )
    if not nullable:
        with op.batch_alter_table(table) as batch:
            batch.alter_column("tenant_id", nullable=False)
    op.create_index(f"ix_{table}_tenant_id", table, ["tenant_id"])
    op.create_foreign_key(
        f"fk_{table}_tenant_id", table, "tenants", ["tenant_id"], ["id"]
    )


def upgrade() -> None:
    # ------------------------------------------------------------------ tenants
    op.create_table(
        "tenants",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("code", sa.String(32), nullable=False, unique=True),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("contact_email", sa.String(128), nullable=False),
        sa.Column("contact_phone", sa.String(32)),
        sa.Column("tax_id", sa.String(16)),
        sa.Column("status", sa.String(16), server_default="active"),
        sa.Column("plan_code", sa.String(32)),
        sa.Column("trial_ends_at", sa.DateTime(timezone=True)),
        sa.Column("settings", sa.JSON(), nullable=False, server_default="{}"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)),
    )

    # Synthetic legacy tenant so backfill keeps existing data accessible.
    op.execute(
        sa.text(
            "INSERT INTO tenants (id, code, name, contact_email, status, settings) "
            "VALUES (:id, '__legacy__', 'Legacy data', 'legacy@local', 'active', '{}')"
        ).bindparams(id=LEGACY_TENANT_ID)
    )

    # ------------------------------------------- propagate tenant_id everywhere
    for table, nullable in TENANT_SCOPED_TABLES:
        _add_tenant_column(table, nullable=nullable)

    # ------------------------------------------- composite uniques + cleanup
    # users(tenant, username)
    _drop_unique("users", "username")
    op.create_unique_constraint(
        "uq_user_tenant_username", "users", ["tenant_id", "username"]
    )
    op.add_column("users", sa.Column("email", sa.String(128)))
    op.add_column("users", sa.Column("must_change_password", sa.Boolean(), server_default=sa.text("false"), nullable=False))
    op.add_column("users", sa.Column("last_login_at", sa.DateTime(timezone=True)))
    op.add_column("users", sa.Column("failed_login_count", sa.Integer(), server_default="0", nullable=False))
    op.add_column("users", sa.Column("locked_until", sa.DateTime(timezone=True)))

    # stores(tenant, code)
    _drop_unique("stores", "code")
    op.create_unique_constraint(
        "uq_store_tenant_code", "stores", ["tenant_id", "code"]
    )

    # terminals(store, code)
    op.create_unique_constraint(
        "uq_terminal_store_code", "terminals", ["store_id", "code"]
    )

    # products(tenant, sku)
    _drop_unique("products", "sku")
    op.create_unique_constraint(
        "uq_product_tenant_sku", "products", ["tenant_id", "sku"]
    )

    # product_barcodes(tenant, barcode)
    _drop_unique("product_barcodes", "barcode")
    op.create_unique_constraint(
        "uq_barcode_tenant_code", "product_barcodes", ["tenant_id", "barcode"]
    )

    # member_levels(tenant, name)
    op.create_unique_constraint(
        "uq_member_level_tenant_name", "member_levels", ["tenant_id", "name"]
    )

    # members(tenant, phone) + (tenant, qr_code)
    _drop_unique("members", "phone")
    _drop_unique("members", "qr_code")
    op.create_unique_constraint(
        "uq_member_tenant_phone", "members", ["tenant_id", "phone"]
    )
    op.create_unique_constraint(
        "uq_member_tenant_qr", "members", ["tenant_id", "qr_code"]
    )

    # coupons(tenant, code)
    _drop_unique("coupons", "code")
    op.create_unique_constraint(
        "uq_coupon_tenant_code", "coupons", ["tenant_id", "code"]
    )

    # invoices(tenant, invoice_number)
    _drop_unique("invoices", "invoice_number")
    op.create_unique_constraint(
        "uq_invoice_tenant_number", "invoices", ["tenant_id", "invoice_number"]
    )

    # ----------------------------------------------------- SaaS layer tables
    op.create_table(
        "tenant_applications",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("company_name", sa.String(128), nullable=False),
        sa.Column("contact_name", sa.String(64), nullable=False),
        sa.Column("contact_email", sa.String(128), nullable=False),
        sa.Column("contact_phone", sa.String(32)),
        sa.Column("tax_id", sa.String(16)),
        sa.Column("plan_code", sa.String(32)),
        sa.Column("proposed_subdomain", sa.String(32), unique=True),
        sa.Column("address", sa.String(256)),
        sa.Column("note", sa.Text()),
        sa.Column("status", sa.String(16), nullable=False, server_default="pending"),
        sa.Column("email_verified_at", sa.DateTime(timezone=True)),
        sa.Column("reviewed_by_user_id", sa.String(36), sa.ForeignKey("users.id")),
        sa.Column("reviewed_at", sa.DateTime(timezone=True)),
        sa.Column("reject_reason", sa.Text()),
        sa.Column("provisioned_tenant_id", sa.String(36), sa.ForeignKey("tenants.id")),
        sa.Column("submitter_ip", sa.String(64)),
        sa.Column("captcha_passed", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_tenant_applications_email", "tenant_applications", ["contact_email"])
    op.create_index("ix_tenant_applications_status", "tenant_applications", ["status"])

    op.create_table(
        "email_otps",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("purpose", sa.String(32), nullable=False),
        sa.Column("email", sa.String(128), nullable=False),
        sa.Column("code_hash", sa.String(128), nullable=False),
        sa.Column("related_id", sa.String(36)),
        sa.Column("consumed_at", sa.DateTime(timezone=True)),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("attempts", sa.Integer(), server_default="0", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_email_otps_email", "email_otps", ["email"])
    op.create_index("ix_email_otps_purpose", "email_otps", ["purpose"])

    op.create_table(
        "refresh_tokens",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id")),
        sa.Column("issued_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True)),
        sa.Column("user_agent", sa.String(256)),
        sa.Column("ip", sa.String(64)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_refresh_tokens_user_id", "refresh_tokens", ["user_id"])
    op.create_index("ix_refresh_tokens_expires_at", "refresh_tokens", ["expires_at"])

    op.create_table(
        "audit_logs",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id")),
        sa.Column("user_id", sa.String(36), sa.ForeignKey("users.id")),
        sa.Column("action", sa.String(64), nullable=False),
        sa.Column("resource_type", sa.String(64), nullable=False),
        sa.Column("resource_id", sa.String(64)),
        sa.Column("ip", sa.String(64)),
        sa.Column("user_agent", sa.String(256)),
        sa.Column("before", sa.JSON()),
        sa.Column("after", sa.JSON()),
        sa.Column("extra", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_audit_logs_tenant_id", "audit_logs", ["tenant_id"])
    op.create_index("ix_audit_logs_action", "audit_logs", ["action"])
    op.create_index("ix_audit_logs_resource_type", "audit_logs", ["resource_type"])

    op.create_table(
        "tenant_payment_settings",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False),
        sa.Column("driver", sa.String(32), nullable=False),
        sa.Column("is_enabled", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("is_sandbox", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("merchant_id", sa.String(64)),
        sa.Column("hash_key_enc", sa.Text()),
        sa.Column("hash_iv_enc", sa.Text()),
        sa.Column("channel_id_enc", sa.Text()),
        sa.Column("channel_secret_enc", sa.Text()),
        sa.Column("extra", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_tenant_payment_settings_tenant_id", "tenant_payment_settings", ["tenant_id"])

    op.create_table(
        "tenant_invoice_settings",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False),
        sa.Column("driver", sa.String(32), nullable=False),
        sa.Column("is_enabled", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("is_sandbox", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("merchant_id", sa.String(64)),
        sa.Column("hash_key_enc", sa.Text()),
        sa.Column("hash_iv_enc", sa.Text()),
        sa.Column("company_tax_id", sa.String(16)),
        sa.Column("extra", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_tenant_invoice_settings_tenant_id", "tenant_invoice_settings", ["tenant_id"])

    op.create_table(
        "subscription_plans",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("code", sa.String(32), nullable=False, unique=True),
        sa.Column("name", sa.String(64), nullable=False),
        sa.Column("price_cents", sa.Integer(), server_default="0", nullable=False),
        sa.Column("interval", sa.String(16), server_default="month", nullable=False),
        sa.Column("max_stores", sa.Integer(), server_default="1", nullable=False),
        sa.Column("max_terminals", sa.Integer(), server_default="2", nullable=False),
        sa.Column("max_orders_per_month", sa.Integer(), server_default="2000", nullable=False),
        sa.Column("max_products", sa.Integer(), server_default="500", nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("description", sa.Text()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        "tenant_subscriptions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False),
        sa.Column("plan_id", sa.String(36), sa.ForeignKey("subscription_plans.id"), nullable=False),
        sa.Column("status", sa.String(16), server_default="active", nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("current_period_end", sa.DateTime(timezone=True)),
        sa.Column("cancelled_at", sa.DateTime(timezone=True)),
        sa.Column("external_ref", sa.String(128)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_tenant_subscriptions_tenant_id", "tenant_subscriptions", ["tenant_id"])

    op.create_table(
        "usage_counters",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("tenant_id", sa.String(36), sa.ForeignKey("tenants.id"), nullable=False),
        sa.Column("metric", sa.String(32), nullable=False),
        sa.Column("period", sa.String(7), nullable=False),
        sa.Column("value", sa.Integer(), server_default="0", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("tenant_id", "metric", "period", name="uq_usage_counter_period"),
    )
    op.create_index("ix_usage_counters_tenant_id", "usage_counters", ["tenant_id"])

    # Seed a couple of starter plans so platform admins have defaults.
    plans = [
        ("starter", "Starter", 0, "month", 1, 2, 1000, 200),
        ("growth", "Growth", 99000, "month", 3, 8, 10000, 2000),
        ("pro", "Pro", 299000, "month", 10, 30, 100000, 20000),
    ]
    for code, name, price, interval, st, term, ord_, prod in plans:
        op.execute(
            sa.text(
                "INSERT INTO subscription_plans (id, code, name, price_cents, interval, "
                "max_stores, max_terminals, max_orders_per_month, max_products) "
                "VALUES (:id, :code, :name, :price, :interval, :st, :term, :ord, :prod)"
            ).bindparams(
                id=str(uuid4()),
                code=code,
                name=name,
                price=price,
                interval=interval,
                st=st,
                term=term,
                ord=ord_,
                prod=prod,
            )
        )


def downgrade() -> None:
    for tbl in (
        "usage_counters",
        "tenant_subscriptions",
        "subscription_plans",
        "tenant_invoice_settings",
        "tenant_payment_settings",
        "audit_logs",
        "refresh_tokens",
        "email_otps",
        "tenant_applications",
    ):
        op.drop_table(tbl)

    for table, _ in reversed(TENANT_SCOPED_TABLES):
        try:
            op.drop_constraint(f"fk_{table}_tenant_id", table, type_="foreignkey")
        except Exception:  # noqa: BLE001
            pass
        try:
            op.drop_index(f"ix_{table}_tenant_id", table_name=table)
        except Exception:  # noqa: BLE001
            pass
        try:
            op.drop_column(table, "tenant_id")
        except Exception:  # noqa: BLE001
            pass

    op.drop_table("tenants")
