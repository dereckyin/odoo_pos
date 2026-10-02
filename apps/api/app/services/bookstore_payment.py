"""ECPay All-in-One checkout for bookstore scan-and-go orders.

Amounts in this codebase are whole TWD despite the ``*_cents`` column names,
so they are passed to ECPay unchanged.
"""
from __future__ import annotations

import html
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import get_settings
from ..core.crypto import decrypt
from ..integrations.payments.provider import _ecpay_check_mac
from ..models import TenantPaymentSetting
from .business_time import tenant_timezone


@dataclass
class EcpayCredentials:
    merchant_id: str
    hash_key: str
    hash_iv: str
    sandbox: bool

    @property
    def checkout_url(self) -> str:
        host = "payment-stage.ecpay.com.tw" if self.sandbox else "payment.ecpay.com.tw"
        return f"https://{host}/Cashier/AioCheckOut/V5"


@dataclass
class VerifiedNotify:
    merchant_trade_no: str
    gateway_trade_no: str
    amount: int


def _safe_decrypt(value: str | None) -> str | None:
    if not value:
        return None
    try:
        return decrypt(value)
    except Exception:  # noqa: BLE001 - treat undecryptable creds as missing
        return None


async def resolve_ecpay_credentials(db: AsyncSession, tenant_id: str) -> EcpayCredentials | None:
    setting = (
        await db.execute(
            select(TenantPaymentSetting).where(
                TenantPaymentSetting.tenant_id == tenant_id,
                TenantPaymentSetting.driver == "ecpay",
                TenantPaymentSetting.is_enabled.is_(True),
            )
        )
    ).scalar_one_or_none()
    if setting is not None:
        key = _safe_decrypt(setting.hash_key_enc)
        iv = _safe_decrypt(setting.hash_iv_enc)
        if setting.merchant_id and key and iv:
            return EcpayCredentials(setting.merchant_id, key, iv, bool(setting.is_sandbox))
        return None
    s = get_settings()
    if s.ECPAY_MERCHANT_ID and s.ECPAY_HASH_KEY and s.ECPAY_HASH_IV:
        return EcpayCredentials(
            s.ECPAY_MERCHANT_ID, s.ECPAY_HASH_KEY, s.ECPAY_HASH_IV, "stage" in s.ECPAY_BASE_URL
        )
    return None


def build_checkout_form(
    creds: EcpayCredentials,
    *,
    merchant_trade_no: str,
    amount: int,
    item_names: list[str],
    notify_url: str,
    result_url: str,
    tenant_settings: dict | None,
) -> str:
    now_local = datetime.now(tenant_timezone(tenant_settings))
    items = "#".join(n.replace("#", " ")[:60] for n in item_names)[:400] or "書籍"
    params = {
        "MerchantID": creds.merchant_id,
        "MerchantTradeNo": merchant_trade_no,
        "MerchantTradeDate": now_local.strftime("%Y/%m/%d %H:%M:%S"),
        "PaymentType": "aio",
        "TotalAmount": str(int(amount)),
        "TradeDesc": "讀冊實體書店",
        "ItemName": items,
        "ReturnURL": notify_url,
        "OrderResultURL": result_url,
        "ClientBackURL": result_url,
        "ChoosePayment": get_settings().BOOKSTORE_ECPAY_CHOOSE_PAYMENT or "Credit",
        "EncryptType": "1",
        "NeedExtraPaidInfo": "N",
    }
    params["CheckMacValue"] = _ecpay_check_mac(params, creds.hash_key, creds.hash_iv)
    fields = "".join(
        f'<input type="hidden" name="{html.escape(k)}" value="{html.escape(str(v))}">'
        for k, v in params.items()
    )
    return (
        f'<form id="ecpay" method="post" action="{html.escape(creds.checkout_url)}">{fields}'
        '<noscript><button type="submit">前往付款</button></noscript></form>'
        '<script>document.getElementById("ecpay").submit();</script>'
    )


def verify_notify(creds: EcpayCredentials, payload: dict[str, str]) -> VerifiedNotify | None:
    mac = payload.get("CheckMacValue")
    if not mac:
        return None
    expected = _ecpay_check_mac(
        {k: v for k, v in payload.items() if k != "CheckMacValue"}, creds.hash_key, creds.hash_iv
    )
    if mac.upper() != expected.upper():
        return None
    if payload.get("RtnCode") != "1":
        return None
    if payload.get("SimulatePaid") == "1" and (get_settings().is_production or not creds.sandbox):
        return None
    try:
        amount = int(float(payload.get("TradeAmt", "0")))
    except ValueError:
        return None
    return VerifiedNotify(
        merchant_trade_no=payload.get("MerchantTradeNo", ""),
        gateway_trade_no=payload.get("TradeNo", ""),
        amount=amount,
    )
