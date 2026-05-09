"""ECPay (綠界) e-invoice driver - simplified.

Reference: https://www.ecpay.com.tw/Service/API_Dwnld
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

import httpx

from ...core.config import get_settings
from .base import InvoiceDriver, InvoiceIssueRequest, InvoiceResult, InvoiceVoidRequest


class EcpayInvoiceDriver(InvoiceDriver):
    name = "ecpay_invoice"

    def __init__(
        self,
        *,
        merchant_id: str | None = None,
        hash_key: str | None = None,
        hash_iv: str | None = None,
        base_url: str | None = None,
    ) -> None:
        s = get_settings()
        self.merchant_id = merchant_id or s.ECPAY_INVOICE_MERCHANT_ID
        self.hash_key = hash_key or s.ECPAY_INVOICE_HASH_KEY
        self.hash_iv = hash_iv or s.ECPAY_INVOICE_HASH_IV
        self.base_url = base_url or s.ECPAY_INVOICE_BASE_URL

    async def issue(self, req: InvoiceIssueRequest) -> InvoiceResult:
        if not self.merchant_id:
            return InvoiceResult(gateway=self.name, status="failed", raw={"error": "ecpay invoice not configured"})

        # ECPay invoice v3 uses encrypted JSON; we keep this stub simple.
        body: dict[str, Any] = {
            "MerchantID": self.merchant_id,
            "RqHeader": {"Timestamp": int(datetime.now(timezone.utc).timestamp())},
            "Data": {
                "MerchantID": self.merchant_id,
                "RelateNumber": req.order_id.replace("-", "")[:30] + uuid4().hex[:6],
                "CustomerIdentifier": req.tax_id or "",
                "CustomerName": req.company_name or "POS Customer",
                "CustomerEmail": req.email or "",
                "ClearanceMark": "",
                "Print": "0" if req.carrier_type else "1",
                "Donation": "1" if req.donation_code else "0",
                "LoveCode": req.donation_code or "",
                "CarrierType": {
                    None: "",
                    "mobile": "3",
                    "citizenDigital": "2",
                    "member": "1",
                }.get(req.carrier_type, ""),
                "CarrierNum": req.carrier_code or "",
                "TaxType": str(req.tax_type),
                "SalesAmount": req.total_cents,
                "InvoiceRemark": "POS",
                "Items": [
                    {
                        "ItemSeq": i + 1,
                        "ItemName": ln.name,
                        "ItemCount": ln.qty,
                        "ItemWord": "個",
                        "ItemPrice": ln.unit_price_cents,
                        "ItemTaxType": str(ln.tax_type),
                        "ItemAmount": ln.amount_cents,
                    }
                    for i, ln in enumerate(req.lines or [])
                ],
                "InvType": "07",
                "vat": "1",
            },
        }

        try:
            async with httpx.AsyncClient(timeout=15) as client:
                r = await client.post(f"{self.base_url}/B2CInvoice/Issue", json=body)
                r.raise_for_status()
                res = r.json()
        except Exception as e:  # noqa: BLE001
            return InvoiceResult(gateway=self.name, status="failed", raw={"error": str(e)})

        if str(res.get("TransCode")) != "1":
            return InvoiceResult(gateway=self.name, status="failed", raw=res)
        data = res.get("Data", {})
        return InvoiceResult(
            gateway=self.name,
            status="issued",
            invoice_number=data.get("InvoiceNo"),
            invoice_date=datetime.now(timezone.utc),
            raw=res,
        )

    async def void(self, req: InvoiceVoidRequest) -> InvoiceResult:
        if not self.merchant_id:
            return InvoiceResult(gateway=self.name, status="failed", raw={"error": "ecpay invoice not configured"})
        body = {
            "MerchantID": self.merchant_id,
            "RqHeader": {"Timestamp": int(datetime.now(timezone.utc).timestamp())},
            "Data": {
                "MerchantID": self.merchant_id,
                "InvoiceNo": req.invoice_number,
                "InvoiceDate": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
                "Reason": req.reason or "POS void",
            },
        }
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                r = await client.post(f"{self.base_url}/B2CInvoice/Invalid", json=body)
                r.raise_for_status()
                res = r.json()
        except Exception as e:  # noqa: BLE001
            return InvoiceResult(gateway=self.name, status="failed", raw={"error": str(e)})
        ok = str(res.get("TransCode")) == "1"
        return InvoiceResult(
            gateway=self.name,
            status="voided" if ok else "failed",
            invoice_number=req.invoice_number,
            raw=res,
        )
