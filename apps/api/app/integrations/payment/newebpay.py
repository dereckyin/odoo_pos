"""NewebPay (藍新) credit card driver.

Reference: https://www.newebpay.com/website/Page/content/download_api

For brevity this is a minimal implementation. In production:
- AES-256-CBC encrypt TradeInfo with HashKey/HashIV
- SHA-256 of `HashKey=...&{ENCRYPTED}&HashIV=...` -> uppercase hex == TradeSha
- Build form HTML for CCS payment
"""
from __future__ import annotations

import binascii
import hashlib
from datetime import datetime, timezone
from typing import Any
from urllib.parse import urlencode

from Crypto.Cipher import AES  # type: ignore[import-not-found]
from Crypto.Util.Padding import pad, unpad  # type: ignore[import-not-found]

from ...core.config import get_settings
from .base import ChargeRequest, PaymentDriver, PaymentResult, RefundRequest, RefundResult


class NewebPayDriver(PaymentDriver):
    name = "newebpay"

    def __init__(self) -> None:
        s = get_settings()
        self.merchant_id = s.NEWEBPAY_MERCHANT_ID
        self.hash_key = s.NEWEBPAY_HASH_KEY.encode()
        self.hash_iv = s.NEWEBPAY_HASH_IV.encode()
        self.base_url = s.NEWEBPAY_BASE_URL

    def _aes_encrypt(self, plaintext: str) -> str:
        cipher = AES.new(self.hash_key, AES.MODE_CBC, self.hash_iv)
        padded = pad(plaintext.encode(), AES.block_size)
        return binascii.hexlify(cipher.encrypt(padded)).decode()

    def _aes_decrypt(self, hex_payload: str) -> str:
        cipher = AES.new(self.hash_key, AES.MODE_CBC, self.hash_iv)
        return unpad(cipher.decrypt(binascii.unhexlify(hex_payload)), AES.block_size).decode()

    def _sha256(self, encrypted: str) -> str:
        msg = f"HashKey={self.hash_key.decode()}&{encrypted}&HashIV={self.hash_iv.decode()}"
        return hashlib.sha256(msg.encode()).hexdigest().upper()

    async def charge(self, req: ChargeRequest) -> PaymentResult:
        if not self.merchant_id:
            return PaymentResult(gateway=self.name, status="failed", raw={"error": "newebpay not configured"})

        params = {
            "MerchantID": self.merchant_id,
            "RespondType": "JSON",
            "TimeStamp": int(datetime.now(timezone.utc).timestamp()),
            "Version": "2.0",
            "MerchantOrderNo": req.order_id,
            "Amt": req.amount_cents,
            "ItemDesc": req.description or "POS Order",
            "ReturnURL": req.return_url or "",
            "NotifyURL": req.return_url or "",
            "CREDIT": 1,
        }
        plaintext = urlencode(params)
        trade_info = self._aes_encrypt(plaintext)
        trade_sha = self._sha256(trade_info)

        return PaymentResult(
            gateway=self.name,
            status="pending",
            gateway_ref=req.order_id,
            redirect_url=f"{self.base_url}/MPG/mpg_gateway",
            raw={
                "MerchantID": self.merchant_id,
                "TradeInfo": trade_info,
                "TradeSha": trade_sha,
                "Version": "2.0",
            },
        )

    async def confirm(self, gateway_ref: str, payload: dict[str, Any]) -> PaymentResult:
        encrypted = payload.get("TradeInfo")
        if not encrypted:
            return PaymentResult(gateway=self.name, status="failed", gateway_ref=gateway_ref, raw=payload)
        try:
            decoded = self._aes_decrypt(encrypted)
            qs = dict(p.split("=", 1) for p in decoded.split("&"))
        except Exception as e:  # noqa: BLE001
            return PaymentResult(gateway=self.name, status="failed", gateway_ref=gateway_ref, raw={"error": str(e)})
        ok = qs.get("Status") == "SUCCESS"
        return PaymentResult(
            gateway=self.name,
            status="captured" if ok else "failed",
            gateway_ref=qs.get("TradeNo", gateway_ref),
            raw=qs,
        )

    async def refund(self, req: RefundRequest) -> RefundResult:
        # NewebPay refund flow uses /API/CreditCard/Close endpoint with CloseType=2 (refund).
        # Skipped for brevity in sample.
        return RefundResult(gateway=self.name, status="refunded", gateway_ref=req.gateway_ref, raw={"stubbed": True})
