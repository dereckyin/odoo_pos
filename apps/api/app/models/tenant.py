from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class Tenant(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    """A SaaS tenant (a paying customer / company). One tenant owns
    one-or-many ``stores``. Cross-tenant data MUST never leak; this is the
    primary scoping unit for the entire API."""

    __tablename__ = "tenants"

    code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(128))
    contact_email: Mapped[str] = mapped_column(String(128))
    contact_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    tax_id: Mapped[str | None] = mapped_column(String(16), nullable=True)
    status: Mapped[str] = mapped_column(
        String(16), default="active", index=True
    )  # active | suspended | trial | closed
    plan_code: Mapped[str | None] = mapped_column(String(32), nullable=True, index=True)
    trial_ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    settings: Mapped[dict] = mapped_column(JSON, default=dict)


class TenantApplication(Base, UUIDPrimaryKey, Timestamped):
    """Public store-signup application waiting for platform review."""

    __tablename__ = "tenant_applications"

    company_name: Mapped[str] = mapped_column(String(128))
    contact_name: Mapped[str] = mapped_column(String(64))
    contact_email: Mapped[str] = mapped_column(String(128), index=True)
    contact_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    tax_id: Mapped[str | None] = mapped_column(String(16), nullable=True, index=True)
    plan_code: Mapped[str | None] = mapped_column(String(32), nullable=True)
    proposed_subdomain: Mapped[str | None] = mapped_column(String(32), nullable=True, unique=True, index=True)

    address: Mapped[str | None] = mapped_column(String(256), nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)

    status: Mapped[str] = mapped_column(
        String(16), default="pending", index=True
    )  # pending | email_verified | approved | rejected | provisioned
    email_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reviewed_by_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    reject_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    provisioned_tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), nullable=True)

    submitter_ip: Mapped[str | None] = mapped_column(String(64), nullable=True)
    captcha_passed: Mapped[bool] = mapped_column(Boolean, default=False)


class EmailOtp(Base, UUIDPrimaryKey, Timestamped):
    """One-time codes for email verification (signup, password recovery)."""

    __tablename__ = "email_otps"

    purpose: Mapped[str] = mapped_column(String(32), index=True)  # signup | recovery
    email: Mapped[str] = mapped_column(String(128), index=True)
    code_hash: Mapped[str] = mapped_column(String(128))
    related_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    consumed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    attempts: Mapped[int] = mapped_column(Integer, default=0)


class RefreshToken(Base, UUIDPrimaryKey, Timestamped):
    """Server-side refresh token registry so logout / password change can
    revoke sessions. The token's JTI claim is stored as ``id``."""

    __tablename__ = "refresh_tokens"

    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), nullable=True, index=True)
    issued_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True, index=True)
    user_agent: Mapped[str | None] = mapped_column(String(256), nullable=True)
    ip: Mapped[str | None] = mapped_column(String(64), nullable=True)


class AuditLog(Base, UUIDPrimaryKey, Timestamped):
    """Append-only audit trail. Every write endpoint should emit one entry
    (typically via the ``audit`` decorator in ``core/audit.py``)."""

    __tablename__ = "audit_logs"

    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), nullable=True, index=True)
    user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    action: Mapped[str] = mapped_column(String(64), index=True)
    resource_type: Mapped[str] = mapped_column(String(64), index=True)
    resource_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    ip: Mapped[str | None] = mapped_column(String(64), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(String(256), nullable=True)
    before: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    after: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    extra: Mapped[dict | None] = mapped_column(JSON, nullable=True)


class TenantPaymentSetting(Base, UUIDPrimaryKey, Timestamped):
    """Per-tenant payment-gateway credentials. Sensitive fields stored as
    Fernet-encrypted strings; decrypt only when invoking the gateway driver."""

    __tablename__ = "tenant_payment_settings"

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), nullable=False, index=True)
    driver: Mapped[str] = mapped_column(String(32))  # ecpay | newebpay | linepay | cash
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    is_sandbox: Mapped[bool] = mapped_column(Boolean, default=True)
    merchant_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    hash_key_enc: Mapped[str | None] = mapped_column(Text, nullable=True)
    hash_iv_enc: Mapped[str | None] = mapped_column(Text, nullable=True)
    channel_id_enc: Mapped[str | None] = mapped_column(Text, nullable=True)
    channel_secret_enc: Mapped[str | None] = mapped_column(Text, nullable=True)
    extra: Mapped[dict | None] = mapped_column(JSON, nullable=True)


class TenantInvoiceSetting(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "tenant_invoice_settings"

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), nullable=False, index=True)
    driver: Mapped[str] = mapped_column(String(32))  # ecpay | ezpay
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    is_sandbox: Mapped[bool] = mapped_column(Boolean, default=True)
    merchant_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    hash_key_enc: Mapped[str | None] = mapped_column(Text, nullable=True)
    hash_iv_enc: Mapped[str | None] = mapped_column(Text, nullable=True)
    company_tax_id: Mapped[str | None] = mapped_column(String(16), nullable=True)
    extra: Mapped[dict | None] = mapped_column(JSON, nullable=True)


class SubscriptionPlan(Base, UUIDPrimaryKey, Timestamped):
    """Catalogue of what tenants can subscribe to. Limits are evaluated
    at write time by ``core/usage.py``."""

    __tablename__ = "subscription_plans"

    code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(64))
    price_cents: Mapped[int] = mapped_column(Integer, default=0)
    interval: Mapped[str] = mapped_column(String(16), default="month")  # month | year | trial
    max_stores: Mapped[int] = mapped_column(Integer, default=1)
    max_terminals: Mapped[int] = mapped_column(Integer, default=2)
    max_orders_per_month: Mapped[int] = mapped_column(Integer, default=2000)
    max_products: Mapped[int] = mapped_column(Integer, default=500)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)


class TenantSubscription(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "tenant_subscriptions"

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), nullable=False, index=True)
    plan_id: Mapped[str] = mapped_column(ForeignKey("subscription_plans.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(16), default="active")  # active | past_due | cancelled
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    current_period_end: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    external_ref: Mapped[str | None] = mapped_column(String(128), nullable=True)


class UsageCounter(Base, UUIDPrimaryKey, Timestamped):
    """Rolling per-month counters. Incremented by hooks; queried by the
    plan-limit checker."""

    __tablename__ = "usage_counters"

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), nullable=False, index=True)
    metric: Mapped[str] = mapped_column(String(32), index=True)  # orders | api_calls | storage
    period: Mapped[str] = mapped_column(String(7), index=True)  # YYYY-MM
    value: Mapped[int] = mapped_column(Integer, default=0)
