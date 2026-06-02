"""Per-tenant configuration endpoints used by the tenant owner / admin to
hold their own payment and invoice gateway credentials.

Plain-text secrets are accepted on input, encrypted on the way to the
database (Fernet), and never returned to clients (only ``has_secret`` flags
are exposed). Decryption happens in the gateway driver layer right before
calling the upstream API.
"""
from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from ...core.audit import audit
from ...core.crypto import encrypt
from ...core.deps import (
    DbSession,
    TenantAdminDep,
)
from ...core.usage import get_active_plan, get_usage
from ...services.tenant_modules import get_tenant_modules
from ...models import (
    AuditLog,
    Tenant,
    TenantInvoiceSetting,
    TenantPaymentSetting,
    TenantSubscription,
)
from ...schemas.tenant import (
    AuditLogRead,
    SubscriptionPlanRead,
    TenantGeneralSettingsRead,
    TenantGeneralSettingsUpdate,
    TenantModulesRead,
    TenantInvoiceSettingRead,
    TenantInvoiceSettingUpsert,
    TenantPaymentSettingRead,
    TenantPaymentSettingUpsert,
    TenantSubscriptionRead,
    UsageCounterRead,
)

router = APIRouter(prefix="/tenant", tags=["tenant-settings"])


@router.get("/general-settings", response_model=TenantGeneralSettingsRead)
async def get_general_settings(db: DbSession, scope: TenantAdminDep):
    tenant = await db.get(Tenant, scope.tenant_id)
    if not tenant:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    settings = tenant.settings or {}
    return TenantGeneralSettingsRead(timezone=settings.get("timezone") or "Asia/Taipei")


@router.patch("/general-settings", response_model=TenantGeneralSettingsRead)
async def update_general_settings(
    payload: TenantGeneralSettingsUpdate, db: DbSession, scope: TenantAdminDep
):
    tenant = await db.get(Tenant, scope.tenant_id)
    if not tenant:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    settings = dict(tenant.settings or {})
    if payload.timezone is not None:
        settings["timezone"] = payload.timezone
    tenant.settings = settings
    await audit(db, scope, action="tenant_settings_update", resource_type="tenant", flush=False)
    await db.commit()
    await db.refresh(tenant)
    return TenantGeneralSettingsRead(timezone=settings.get("timezone") or "Asia/Taipei")


@router.get("/modules", response_model=TenantModulesRead)
async def get_my_modules(db: DbSession, scope: TenantAdminDep):
    mods = await get_tenant_modules(db, scope.tenant_id)
    return TenantModulesRead(**mods)


# ---------------------------------------------------------------------------
# Payment gateway settings
# ---------------------------------------------------------------------------

@router.get("/payment-settings", response_model=list[TenantPaymentSettingRead])
async def list_payment_settings(db: DbSession, scope: TenantAdminDep):
    rows = (
        await db.execute(
            select(TenantPaymentSetting).where(
                TenantPaymentSetting.tenant_id == scope.tenant_id
            )
        )
    ).scalars().all()
    return rows


@router.put("/payment-settings", response_model=TenantPaymentSettingRead)
async def upsert_payment_setting(
    payload: TenantPaymentSettingUpsert, db: DbSession, scope: TenantAdminDep
):
    existing = (
        await db.execute(
            select(TenantPaymentSetting).where(
                TenantPaymentSetting.tenant_id == scope.tenant_id,
                TenantPaymentSetting.driver == payload.driver,
            )
        )
    ).scalar_one_or_none()
    if existing is None:
        existing = TenantPaymentSetting(
            tenant_id=scope.tenant_id, driver=payload.driver
        )
        db.add(existing)
    existing.is_enabled = payload.is_enabled
    existing.is_sandbox = payload.is_sandbox
    existing.merchant_id = payload.merchant_id
    if payload.hash_key is not None:
        existing.hash_key_enc = encrypt(payload.hash_key)
    if payload.hash_iv is not None:
        existing.hash_iv_enc = encrypt(payload.hash_iv)
    if payload.channel_id is not None:
        existing.channel_id_enc = encrypt(payload.channel_id)
    if payload.channel_secret is not None:
        existing.channel_secret_enc = encrypt(payload.channel_secret)
    await audit(db, scope, action="payment_setting_upsert", resource_type="payment_setting",
                resource_id=payload.driver, flush=False)
    await db.commit()
    await db.refresh(existing)
    return existing


@router.delete("/payment-settings/{driver}", status_code=204)
async def delete_payment_setting(
    driver: str, db: DbSession, scope: TenantAdminDep
):
    existing = (
        await db.execute(
            select(TenantPaymentSetting).where(
                TenantPaymentSetting.tenant_id == scope.tenant_id,
                TenantPaymentSetting.driver == driver,
            )
        )
    ).scalar_one_or_none()
    if not existing:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    await db.delete(existing)
    await audit(db, scope, action="payment_setting_delete", resource_type="payment_setting",
                resource_id=driver, flush=False)
    await db.commit()


# ---------------------------------------------------------------------------
# Invoice gateway settings
# ---------------------------------------------------------------------------

@router.get("/invoice-settings", response_model=list[TenantInvoiceSettingRead])
async def list_invoice_settings(db: DbSession, scope: TenantAdminDep):
    rows = (
        await db.execute(
            select(TenantInvoiceSetting).where(
                TenantInvoiceSetting.tenant_id == scope.tenant_id
            )
        )
    ).scalars().all()
    return rows


@router.put("/invoice-settings", response_model=TenantInvoiceSettingRead)
async def upsert_invoice_setting(
    payload: TenantInvoiceSettingUpsert, db: DbSession, scope: TenantAdminDep
):
    existing = (
        await db.execute(
            select(TenantInvoiceSetting).where(
                TenantInvoiceSetting.tenant_id == scope.tenant_id,
                TenantInvoiceSetting.driver == payload.driver,
            )
        )
    ).scalar_one_or_none()
    if existing is None:
        existing = TenantInvoiceSetting(
            tenant_id=scope.tenant_id, driver=payload.driver
        )
        db.add(existing)
    existing.is_enabled = payload.is_enabled
    existing.is_sandbox = payload.is_sandbox
    existing.merchant_id = payload.merchant_id
    existing.company_tax_id = payload.company_tax_id
    if payload.hash_key is not None:
        existing.hash_key_enc = encrypt(payload.hash_key)
    if payload.hash_iv is not None:
        existing.hash_iv_enc = encrypt(payload.hash_iv)
    await audit(db, scope, action="invoice_setting_upsert", resource_type="invoice_setting",
                resource_id=payload.driver, flush=False)
    await db.commit()
    await db.refresh(existing)
    return existing


# ---------------------------------------------------------------------------
# Subscription / usage (read-only for tenant admins)
# ---------------------------------------------------------------------------

@router.get("/subscription", response_model=TenantSubscriptionRead | None)
async def my_subscription(db: DbSession, scope: TenantAdminDep):
    return (
        await db.execute(
            select(TenantSubscription)
            .where(
                TenantSubscription.tenant_id == scope.tenant_id,
                TenantSubscription.status == "active",
            )
            .order_by(TenantSubscription.started_at.desc())
        )
    ).scalar_one_or_none()


@router.get("/plan", response_model=SubscriptionPlanRead | None)
async def my_plan(db: DbSession, scope: TenantAdminDep):
    return await get_active_plan(db, scope.tenant_id)


@router.get("/usage", response_model=list[UsageCounterRead])
async def my_usage(db: DbSession, scope: TenantAdminDep):
    metrics = ("orders", "api_calls")
    rows: list[UsageCounterRead] = []
    for m in metrics:
        rows.append(UsageCounterRead(
            metric=m,
            period="current",
            value=await get_usage(db, scope.tenant_id, m),
        ))
    return rows


# ---------------------------------------------------------------------------
# Audit-log reader (own tenant only; platform_super sees their selected tenant)
# ---------------------------------------------------------------------------

@router.get("/audit-logs", response_model=list[AuditLogRead])
async def list_audit_logs(
    db: DbSession,
    scope: TenantAdminDep,
    action: str | None = Query(default=None),
    resource_type: str | None = Query(default=None),
    limit: int = Query(default=100, le=500),
):
    """Tenant admins (and platform_super acting on a tenant) can read the
    most recent audit-log rows for traceability / compliance."""
    stmt = select(AuditLog).where(AuditLog.tenant_id == scope.tenant_id)
    if action:
        stmt = stmt.where(AuditLog.action == action)
    if resource_type:
        stmt = stmt.where(AuditLog.resource_type == resource_type)
    stmt = stmt.order_by(AuditLog.created_at.desc()).limit(limit)
    rows = (await db.execute(stmt)).scalars().all()
    return rows
