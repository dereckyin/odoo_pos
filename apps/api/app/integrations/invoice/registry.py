from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ...core.crypto import decrypt
from ...models import TenantInvoiceSetting
from .base import InvoiceDriver
from .ecpay_invoice import EcpayInvoiceDriver
from .ezpay import EzpayInvoiceDriver


def invoice_driver_for(name: str) -> InvoiceDriver:
    if name == "ezpay":
        return EzpayInvoiceDriver()
    if name == "ecpay" or name == "ecpay_invoice":
        return EcpayInvoiceDriver()
    raise ValueError(f"unknown invoice driver: {name}")


def _safe_decrypt(value: str | None) -> str | None:
    if not value:
        return None
    try:
        return decrypt(value)
    except Exception:
        return None


async def tenant_invoice_driver_for(
    db: AsyncSession, tenant_id: str | None, name: str
) -> InvoiceDriver:
    """Build an invoice driver using per-tenant credentials when present."""
    if not tenant_id:
        return invoice_driver_for(name)

    canonical = "ecpay" if name in ("ecpay", "ecpay_invoice") else name
    setting = (
        await db.execute(
            select(TenantInvoiceSetting).where(
                TenantInvoiceSetting.tenant_id == tenant_id,
                TenantInvoiceSetting.driver == canonical,
                TenantInvoiceSetting.is_enabled.is_(True),
            )
        )
    ).scalar_one_or_none()
    if setting is None:
        return invoice_driver_for(name)

    hash_key = _safe_decrypt(setting.hash_key_enc)
    hash_iv = _safe_decrypt(setting.hash_iv_enc)

    if canonical == "ezpay":
        return EzpayInvoiceDriver(
            merchant_id=setting.merchant_id,
            hash_key=hash_key,
            hash_iv=hash_iv,
        )
    if canonical == "ecpay":
        return EcpayInvoiceDriver(
            merchant_id=setting.merchant_id,
            hash_key=hash_key,
            hash_iv=hash_iv,
        )
    raise ValueError(f"unknown invoice driver: {name}")
