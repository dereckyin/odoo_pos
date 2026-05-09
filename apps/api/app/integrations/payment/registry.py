"""Payment-driver factory.

For backwards compatibility ``driver_for(name)`` still returns a driver
configured from platform-level fallback settings. New code paths SHOULD
use ``tenant_driver_for`` to load credentials from
``tenant_payment_settings`` (Fernet-encrypted in the database).
"""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ...core.crypto import decrypt
from ...models import TenantPaymentSetting
from .base import PaymentDriver
from .ecpay import EcpayDriver
from .linepay import LinePayDriver
from .newebpay import NewebPayDriver


def registered_drivers() -> dict[str, PaymentDriver]:
    return {
        "linepay": LinePayDriver(),
        "newebpay": NewebPayDriver(),
        "ecpay": EcpayDriver(),
    }


def driver_for(name: str) -> PaymentDriver:
    drivers = registered_drivers()
    if name not in drivers:
        raise ValueError(f"unknown payment driver: {name}")
    return drivers[name]


def _safe_decrypt(value: str | None) -> str | None:
    if not value:
        return None
    try:
        return decrypt(value)
    except Exception:
        return None


async def tenant_driver_for(
    db: AsyncSession, tenant_id: str | None, name: str
) -> PaymentDriver:
    """Build a driver instance using per-tenant credentials when present.

    Falls back to platform settings if the tenant has not configured this
    driver — useful for shared sandboxes / smoke tests."""
    if not tenant_id:
        return driver_for(name)

    setting = (
        await db.execute(
            select(TenantPaymentSetting).where(
                TenantPaymentSetting.tenant_id == tenant_id,
                TenantPaymentSetting.driver == name,
                TenantPaymentSetting.is_enabled.is_(True),
            )
        )
    ).scalar_one_or_none()
    if setting is None:
        return driver_for(name)

    hash_key = _safe_decrypt(setting.hash_key_enc)
    hash_iv = _safe_decrypt(setting.hash_iv_enc)
    channel_id = _safe_decrypt(setting.channel_id_enc)
    channel_secret = _safe_decrypt(setting.channel_secret_enc)

    if name == "ecpay":
        return EcpayDriver(
            merchant_id=setting.merchant_id,
            hash_key=hash_key,
            hash_iv=hash_iv,
        )
    if name == "newebpay":
        return NewebPayDriver(
            merchant_id=setting.merchant_id,
            hash_key=hash_key,
            hash_iv=hash_iv,
        )
    if name == "linepay":
        return LinePayDriver(
            channel_id=channel_id or setting.merchant_id,
            channel_secret=channel_secret,
        )
    raise ValueError(f"unknown payment driver: {name}")
