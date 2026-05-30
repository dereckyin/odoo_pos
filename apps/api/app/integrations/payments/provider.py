"""Payment provider abstraction for marketplace online checkout."""
from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class PaymentInitResult:
    payment_url: str | None = None
    payment_form_html: str | None = None
    provider_ref: str | None = None
    message: str | None = None


class PaymentProvider(ABC):
    @abstractmethod
    async def initiate(
        self,
        *,
        order_id: str,
        amount_cents: int,
        description: str,
        customer_name: str,
        customer_phone: str,
        return_url: str,
        notify_url: str,
    ) -> PaymentInitResult:
        ...

    @abstractmethod
    async def verify_webhook(self, payload: dict) -> tuple[str, str, int] | None:
        """Return (order_id, provider_ref, amount_cents) if valid, else None."""
        ...


class StubPaymentProvider(PaymentProvider):
    """Development / unconfigured ECPay fallback."""

    async def initiate(
        self,
        *,
        order_id: str,
        amount_cents: int,
        description: str,
        customer_name: str,
        customer_phone: str,
        return_url: str,
        notify_url: str,
    ) -> PaymentInitResult:
        return PaymentInitResult(
            message=(
                "Online payment is not configured. Set ECPAY_MERCHANT_ID, "
                "ECPAY_HASH_KEY, ECPAY_HASH_IV in deploy/.env.api"
            ),
        )

    async def verify_webhook(self, payload: dict) -> tuple[str, str, int] | None:
        return None


class ECPayProvider(PaymentProvider):
    """Minimal ECPay All-in-One checkout (redirect mode)."""

    def __init__(self, merchant_id: str, hash_key: str, hash_iv: str, sandbox: bool = True):
        self.merchant_id = merchant_id
        self.hash_key = hash_key
        self.hash_iv = hash_iv
        self.api_url = (
            "https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5"
            if sandbox
            else "https://payment.ecpay.com.tw/Cashier/AioCheckOut/V5"
        )

    async def initiate(
        self,
        *,
        order_id: str,
        amount_cents: int,
        description: str,
        customer_name: str,
        customer_phone: str,
        return_url: str,
        notify_url: str,
    ) -> PaymentInitResult:
        from urllib.parse import urlencode

        params = {
            "MerchantID": self.merchant_id,
            "MerchantTradeNo": order_id.replace("-", "")[:20],
            "MerchantTradeDate": __import__("datetime").datetime.now().strftime("%Y/%m/%d %H:%M:%S"),
            "PaymentType": "aio",
            "TotalAmount": str(amount_cents // 100 or 1),
            "TradeDesc": description[:200],
            "ItemName": description[:400],
            "ReturnURL": notify_url,
            "OrderResultURL": return_url,
            "ChoosePayment": "ALL",
            "EncryptType": "1",
        }
        check_mac = _ecpay_check_mac(params, self.hash_key, self.hash_iv)
        params["CheckMacValue"] = check_mac
        form_fields = "".join(
            f'<input type="hidden" name="{k}" value="{v}">' for k, v in params.items()
        )
        html = (
            f'<form id="ecpay" method="post" action="{self.api_url}">{form_fields}'
            f'<script>document.getElementById("ecpay").submit();</script></form>'
        )
        return PaymentInitResult(payment_form_html=html, provider_ref=params["MerchantTradeNo"])

    async def verify_webhook(self, payload: dict) -> tuple[str, str, int] | None:
        mac = payload.get("CheckMacValue")
        if not mac:
            return None
        expected = _ecpay_check_mac(
            {k: v for k, v in payload.items() if k != "CheckMacValue"},
            self.hash_key,
            self.hash_iv,
        )
        if mac.upper() != expected.upper():
            return None
        if payload.get("RtnCode") != "1":
            return None
        trade_no = payload.get("MerchantTradeNo", "")
        amount = int(float(payload.get("TradeAmt", 0))) * 100
        return trade_no, payload.get("TradeNo", ""), amount


def _ecpay_check_mac(params: dict, hash_key: str, hash_iv: str) -> str:
    from urllib.parse import quote_plus
    import hashlib

    sorted_items = sorted((k, str(v)) for k, v in params.items() if v is not None and k != "CheckMacValue")
    raw = f"HashKey={hash_key}&" + "&".join(f"{k}={v}" for k, v in sorted_items) + f"&HashIV={hash_iv}"
    encoded = quote_plus(raw).lower().replace("%20", "+").replace("%2d", "-").replace("%5f", "_").replace("%2e", ".").replace("%21", "!").replace("%2a", "*").replace("%28", "(").replace("%29", ")")
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest().upper()


def get_payment_provider() -> PaymentProvider:
    from ...core.config import settings

    mid = settings.ECPAY_MERCHANT_ID
    key = settings.ECPAY_HASH_KEY
    iv = settings.ECPAY_HASH_IV
    if mid and key and iv:
        sandbox = "stage" in settings.ECPAY_BASE_URL
        return ECPayProvider(mid, key, iv, sandbox=sandbox)
    return StubPaymentProvider()
