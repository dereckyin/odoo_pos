"""ECPay (綠界) credit card driver - minimal sample.

Reference: https://developers.ecpay.com.tw/?p=2509
"""
from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from typing import Any
from urllib.parse import quote_plus, urlencode

from ...core.config import get_settings
from .base import ChargeRequest, PaymentDriver, PaymentResult, RefundRequest, RefundResult


def _ecpay_sign(params: dict[str, Any], hash_key: str, hash_iv: str) -> str:
    sorted_qs = "&".join(f"{k}={v}" for k, v in sorted(params.items()))
    raw = f"HashKey={hash_key}&{sorted_qs}&HashIV={hash_iv}"
    encoded = quote_plus(raw).lower()
    encoded = (
        encoded.replace("%21", "!")
        .replace("%2a", "*")
        .replace("%28", "(")
        .replace("%29", ")")
    )
    return hashlib.sha256(encoded.encode()).hexdigest().upper()


class EcpayDriver(PaymentDriver):
    name = "ecpay"

    def __init__(self) -> None:
        s = get_settings()
        self.merchant_id = s.ECPAY_MERCHANT_ID
        self.hash_key = s.ECPAY_HASH_KEY
        self.hash_iv = s.ECPAY_HASH_IV
        self.base_url = s.ECPAY_BASE_URL

    async def charge(self, req: ChargeRequest) -> PaymentResult:
        params = {
            "MerchantID": self.merchant_id,
            "MerchantTradeNo": req.order_id.replace("-", "")[:20],
            "MerchantTradeDate": datetime.now(timezone.utc).strftime("%Y/%m/%d %H:%M:%S"),
            "PaymentType": "aio",
            "TotalAmount": req.amount_cents,
            "TradeDesc": (req.description or "POS Order")[:200],
            "ItemName": req.description or "POS Order",
            "ReturnURL": req.return_url or "",
            "ChoosePayment": "Credit",
            "EncryptType": 1,
        }
        params["CheckMacValue"] = _ecpay_sign(params, self.hash_key, self.hash_iv)
        return PaymentResult(
            gateway=self.name,
            status="pending",
            gateway_ref=params["MerchantTradeNo"],
            redirect_url=f"{self.base_url}/Cashier/AioCheckOut/V5",
            raw={"form": params, "submit_url": f"{self.base_url}/Cashier/AioCheckOut/V5"},
        )

    async def confirm(self, gateway_ref: str, payload: dict[str, Any]) -> PaymentResult:
        # ECPay sends asynchronous notify with a CheckMacValue we must verify.
        sig = payload.pop("CheckMacValue", None)
        expected = _ecpay_sign(payload, self.hash_key, self.hash_iv)
        ok = sig == expected and payload.get("RtnCode") == "1"
        return PaymentResult(
            gateway=self.name,
            status="captured" if ok else "failed",
            gateway_ref=payload.get("TradeNo", gateway_ref),
            raw=payload,
        )

    async def refund(self, req: RefundRequest) -> RefundResult:
        return RefundResult(gateway=self.name, status="refunded", gateway_ref=req.gateway_ref, raw={"stubbed": True})

    @staticmethod
    def _querystring(params: dict[str, Any]) -> str:
        return urlencode(params)
