"""LINE Pay v3 driver.

Reference: https://pay.line.me/tw/developers/apis/onlineApis

We sign requests with HMAC-SHA256 according to the v3 spec:
    signature = base64(hmac-sha256(channel_secret, channel_secret + uri + body + nonce))
"""
from __future__ import annotations

import base64
import hashlib
import hmac
import json
from typing import Any
from uuid import uuid4

import httpx

from ...core.config import get_settings
from .base import ChargeRequest, PaymentDriver, PaymentResult, RefundRequest, RefundResult


class LinePayDriver(PaymentDriver):
    name = "linepay"

    def __init__(
        self,
        *,
        channel_id: str | None = None,
        channel_secret: str | None = None,
        base_url: str | None = None,
        confirm_url: str | None = None,
        cancel_url: str | None = None,
    ) -> None:
        s = get_settings()
        self.channel_id = channel_id or s.LINEPAY_CHANNEL_ID
        self.channel_secret = channel_secret or s.LINEPAY_CHANNEL_SECRET
        self.base_url = base_url or s.LINEPAY_BASE_URL
        self.confirm_url = confirm_url or s.LINEPAY_CONFIRM_URL
        self.cancel_url = cancel_url or s.LINEPAY_CANCEL_URL

    def _sign(self, uri: str, body: str, nonce: str) -> str:
        msg = (self.channel_secret + uri + body + nonce).encode("utf-8")
        digest = hmac.new(self.channel_secret.encode("utf-8"), msg, hashlib.sha256).digest()
        return base64.b64encode(digest).decode("utf-8")

    async def _post(self, uri: str, body: dict[str, Any]) -> dict[str, Any]:
        if not self.channel_id or not self.channel_secret:
            raise RuntimeError("LINE Pay credentials not configured")
        nonce = uuid4().hex
        body_text = json.dumps(body, ensure_ascii=False)
        signature = self._sign(uri, body_text, nonce)
        headers = {
            "Content-Type": "application/json",
            "X-LINE-ChannelId": self.channel_id,
            "X-LINE-Authorization-Nonce": nonce,
            "X-LINE-Authorization": signature,
        }
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.post(f"{self.base_url}{uri}", headers=headers, content=body_text)
            r.raise_for_status()
            return r.json()

    async def charge(self, req: ChargeRequest) -> PaymentResult:
        uri = "/v3/payments/request"
        body = {
            "amount": req.amount_cents,  # TWD has no minor units
            "currency": req.currency,
            "orderId": req.order_id,
            "packages": [
                {
                    "id": req.order_id,
                    "amount": req.amount_cents,
                    "name": req.description or "POS Order",
                    "products": [
                        {
                            "name": req.description or "POS Order",
                            "quantity": 1,
                            "price": req.amount_cents,
                        }
                    ],
                }
            ],
            "redirectUrls": {
                "confirmUrl": req.return_url or self.confirm_url,
                "cancelUrl": self.cancel_url,
            },
        }
        try:
            res = await self._post(uri, body)
        except Exception as e:  # noqa: BLE001
            return PaymentResult(gateway=self.name, status="failed", raw={"error": str(e)})

        if res.get("returnCode") != "0000":
            return PaymentResult(gateway=self.name, status="failed", raw=res)
        info = res.get("info", {})
        return PaymentResult(
            gateway=self.name,
            status="pending",
            gateway_ref=info.get("transactionId"),
            redirect_url=info.get("paymentUrl", {}).get("web"),
            deep_link=info.get("paymentUrl", {}).get("app"),
            raw=res,
        )

    async def confirm(self, gateway_ref: str, payload: dict[str, Any]) -> PaymentResult:
        uri = f"/v3/payments/{gateway_ref}/confirm"
        body = {"amount": payload["amount"], "currency": payload.get("currency", "TWD")}
        try:
            res = await self._post(uri, body)
        except Exception as e:  # noqa: BLE001
            return PaymentResult(gateway=self.name, status="failed", gateway_ref=gateway_ref, raw={"error": str(e)})
        ok = res.get("returnCode") == "0000"
        return PaymentResult(
            gateway=self.name,
            status="captured" if ok else "failed",
            gateway_ref=gateway_ref,
            raw=res,
        )

    async def refund(self, req: RefundRequest) -> RefundResult:
        uri = f"/v3/payments/{req.gateway_ref}/refund"
        body = {"refundAmount": req.amount_cents}
        try:
            res = await self._post(uri, body)
        except Exception as e:  # noqa: BLE001
            return RefundResult(gateway=self.name, status="failed", raw={"error": str(e)})
        ok = res.get("returnCode") == "0000"
        return RefundResult(
            gateway=self.name,
            status="refunded" if ok else "failed",
            gateway_ref=res.get("info", {}).get("refundTransactionId"),
            raw=res,
        )
