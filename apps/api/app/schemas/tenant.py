from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from ._base import ORMModel


class TenantRead(ORMModel):
    id: str
    code: str
    name: str
    # Plain str: legacy rows (e.g. legacy@local) must not 500 the list endpoint.
    contact_email: str
    contact_phone: str | None
    tax_id: str | None
    status: str
    plan_code: str | None
    trial_ends_at: datetime | None
    created_at: datetime


class TenantUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=128)
    contact_email: EmailStr | None = None
    contact_phone: str | None = Field(default=None, max_length=32)
    tax_id: str | None = Field(default=None, max_length=16)
    status: str | None = Field(default=None, pattern="^(active|suspended|trial|closed)$")
    plan_code: str | None = Field(default=None, max_length=32)


class PlatformDashboardStats(BaseModel):
    pending_applications: int = 0
    pending_marketplace_listings: int = 0
    active_tenants: int = 0
    suspended_tenants: int = 0
    marketplace_orders_today: int = 0
    marketplace_revenue_today_cents: int = 0


class SubscriptionPlanRead(ORMModel):
    id: str
    code: str
    name: str
    price_cents: int
    interval: str
    max_stores: int
    max_terminals: int
    max_orders_per_month: int
    max_products: int
    is_active: bool
    description: str | None
    features: dict = {}


class TenantSubscriptionRead(ORMModel):
    id: str
    tenant_id: str
    plan_id: str
    status: str
    started_at: datetime
    current_period_end: datetime | None
    cancelled_at: datetime | None


class UsageCounterRead(ORMModel):
    metric: str
    period: str
    value: int


class TenantPaymentSettingRead(ORMModel):
    id: str
    tenant_id: str
    driver: str
    is_enabled: bool
    is_sandbox: bool
    merchant_id: str | None


class TenantPaymentSettingUpsert(BaseModel):
    driver: str = Field(pattern=r"^(ecpay|newebpay|linepay|cash)$")
    is_enabled: bool = True
    is_sandbox: bool = True
    merchant_id: str | None = Field(default=None, max_length=64)
    hash_key: str | None = Field(default=None, max_length=128)
    hash_iv: str | None = Field(default=None, max_length=128)
    channel_id: str | None = Field(default=None, max_length=128)
    channel_secret: str | None = Field(default=None, max_length=256)


class TenantInvoiceSettingRead(ORMModel):
    id: str
    tenant_id: str
    driver: str
    is_enabled: bool
    is_sandbox: bool
    merchant_id: str | None
    company_tax_id: str | None


class TenantInvoiceSettingUpsert(BaseModel):
    driver: str = Field(pattern=r"^(ecpay|ezpay)$")
    is_enabled: bool = True
    is_sandbox: bool = True
    merchant_id: str | None = Field(default=None, max_length=64)
    hash_key: str | None = Field(default=None, max_length=128)
    hash_iv: str | None = Field(default=None, max_length=128)
    company_tax_id: str | None = Field(default=None, max_length=16)


class AuditLogRead(ORMModel):
    id: str
    tenant_id: str | None
    user_id: str | None
    action: str
    resource_type: str
    resource_id: str | None
    ip: str | None
    created_at: datetime
    extra: dict | None


class TenantGeneralSettingsRead(BaseModel):
    timezone: str = "Asia/Taipei"
    require_refund_approval: bool = False


class TenantGeneralSettingsUpdate(BaseModel):
    timezone: str | None = Field(default=None, max_length=64)
    require_refund_approval: bool | None = None


class TenantModulesRead(BaseModel):
    online_ordering: bool = False
    marketplace: bool = False
    business_intelligence: bool = False
    consignment_books: bool = True
    line: bool = False
    events: bool = False


class TenantModulesUpdate(BaseModel):
    online_ordering: bool | None = None
    marketplace: bool | None = None
    business_intelligence: bool | None = None
    consignment_books: bool | None = None
    line: bool | None = None
    events: bool | None = None
