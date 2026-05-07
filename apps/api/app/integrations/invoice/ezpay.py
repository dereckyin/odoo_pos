"""Ezpay (台灣電子發票, 藍新) driver.

Reference: https://www.ezpay.com.tw/dist/ezpay/upload/Ezpay_INV_developer_v1.5.4.pdf

This is a thin wrapper over the AES + SHA256 protocol.
"""
from __future__ import annotations

import binascii
import hashlib
from datetime import datetime, timezone
from typing import Any
from urllib.parse import parse_qsl, urlencode

import httpx

try:  # pragma: no cover
    from Crypto.Cipher import AES  # type: ignore[import-not-found]
    from Crypto.Util.Padding import pad, unpad  # type: ignore[import-not-found]
except Exception:  # noqa: BLE001
    AES = None  # type: ignore[assignment]
    pad = unpad = None  # type: ignore[assignment]

from ...core.config import get_settings
from .base import InvoiceDriver, InvoiceIssueRequest, InvoiceResult, InvoiceVoidRequest


class EzpayInvoiceDriver(InvoiceDriver):
    name = "ezpay"

    def __init__(self) -> None:
        s = get_settings()
        self.merchant_id = s.EZPAY_MERCHANT_ID
        self.hash_key = s.EZPAY_HASH_KEY
        self.hash_iv = s.EZPAY_HASH_IV
        self.base_url = s.EZPAY_BASE_URL

    def _aes_encrypt(self, plaintext: str) -> str:
        cipher = AES.new(self.hash_key.encode(), AES.MODE_CBC, self.hash_iv.encode())
        padded = pad(plaintext.encode(), AES.block_size)
        return binascii.hexlify(cipher.encrypt(padded)).decode()

    def _sha256(self, encrypted: str) -> str:
        msg = f"HashKey={self.hash_key}&{encrypted}&HashIV={self.hash_iv}"
        return hashlib.sha256(msg.encode()).hexdigest().upper()

    async def issue(self, req: InvoiceIssueRequest) -> InvoiceResult:
        if not self.merchant_id:
            return InvoiceResult(gateway=self.name, status="failed", raw={"error": "ezpay not configured"})
        item_names = "|".join(ln.name for ln in req.lines) or "POS Order"
        item_counts = "|".join(str(ln.qty) for ln in req.lines) or "1"
        item_units = "|".join("個" for _ in req.lines) or "個"
        item_prices = "|".join(str(ln.unit_price_cents) for ln in req.lines) or str(req.total_cents)
        item_amounts = "|".join(str(ln.amount_cents) for ln in req.lines) or str(req.total_cents)

        amount_no_tax = req.total_cents - req.tax_cents
        post_data = {
            "RespondType": "JSON",
            "Version": "1.5",
            "TimeStamp": int(datetime.now(timezone.utc).timestamp()),
            "MerchantOrderNo": req.order_id.replace("-", "")[:20],
            "Status": "1",
            "Category": "B2C" if not req.tax_id else "B2B",
            "BuyerName": req.company_name or "POS Customer",
            "BuyerEmail": req.email or "",
            "BuyerUBN": req.tax_id or "",
            "PrintFlag": "Y" if not req.carrier_type else "N",
            "TaxType": req.tax_type,
            "TaxRate": 5,
            "Amt": amount_no_tax,
            "TaxAmt": req.tax_cents,
            "TotalAmt": req.total_cents,
            "ItemName": item_names,
            "ItemCount": item_counts,
            "ItemUnit": item_units,
            "ItemPrice": item_prices,
            "ItemAmt": item_amounts,
            "Comment": "POS",
        }
        if req.donation_code:
            post_data.update({"Category": "B2C", "Donation": "1", "LoveCode": req.donation_code})
        elif req.carrier_type == "mobile":
            post_data.update({"CarrierType": "0", "CarrierNum": req.carrier_code or ""})
        elif req.carrier_type == "citizenDigital":
            post_data.update({"CarrierType": "1", "CarrierNum": req.carrier_code or ""})
        elif req.carrier_type == "member":
            post_data.update({"CarrierType": "2", "CarrierNum": req.carrier_code or ""})

        plaintext = urlencode(post_data)
        encrypted = self._aes_encrypt(plaintext)
        body = {"MerchantID_": self.merchant_id, "PostData_": encrypted}
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.post(f"{self.base_url}/Api/invoice_issue", data=body)
            r.raise_for_status()
            res = r.json()

        if res.get("Status") != "SUCCESS":
            return InvoiceResult(gateway=self.name, status="failed", raw=res)
        result = res.get("Result", {})
        invoice_number = result.get("InvoiceNumber")
        invoice_date = None
        if result.get("CreateTime"):
            try:
                invoice_date = datetime.fromisoformat(result["CreateTime"].replace(" ", "T"))
            except ValueError:
                invoice_date = None
        return InvoiceResult(
            gateway=self.name,
            status="issued",
            invoice_number=invoice_number,
            invoice_date=invoice_date,
            raw=res,
        )

    async def void(self, req: InvoiceVoidRequest) -> InvoiceResult:
        if not self.merchant_id:
            return InvoiceResult(gateway=self.name, status="failed", raw={"error": "ezpay not configured"})
        post_data = {
            "RespondType": "JSON",
            "Version": "1.0",
            "TimeStamp": int(datetime.now(timezone.utc).timestamp()),
            "InvoiceNumber": req.invoice_number,
            "InvalidReason": req.reason or "POS void",
        }
        plaintext = urlencode(post_data)
        encrypted = self._aes_encrypt(plaintext)
        body = {"MerchantID_": self.merchant_id, "PostData_": encrypted}
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.post(f"{self.base_url}/Api/invoice_invalid", data=body)
            r.raise_for_status()
            res = r.json()
        if res.get("Status") != "SUCCESS":
            return InvoiceResult(gateway=self.name, status="failed", raw=res)
        return InvoiceResult(gateway=self.name, status="voided", invoice_number=req.invoice_number, raw=res)

    @staticmethod
    def parse_callback(payload: str) -> dict[str, Any]:
        return dict(parse_qsl(payload))
