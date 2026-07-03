"""Extract Taiwan e-invoice proof-of-purchase fields from gateway responses."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .base import InvoiceResult


@dataclass
class InvoiceProof:
    random_code: str | None = None
    barcode: str | None = None
    qr_left: str | None = None
    qr_right: str | None = None


def extract_invoice_proof(res: InvoiceResult) -> InvoiceProof:
    if res.random_code or res.barcode or res.qr_left or res.qr_right:
        return InvoiceProof(
            random_code=res.random_code,
            barcode=res.barcode,
            qr_left=res.qr_left,
            qr_right=res.qr_right,
        )
    raw = res.raw or {}
    gateway = res.gateway or ""

    if gateway == "ezpay":
        return _from_ezpay(raw)
    if gateway.startswith("ecpay"):
        return _from_ecpay(raw)
    return InvoiceProof()


def _from_ezpay(raw: dict[str, Any]) -> InvoiceProof:
    result = raw.get("Result") or raw.get("result") or {}
    if isinstance(result, str):
        return InvoiceProof()
    return InvoiceProof(
        random_code=_first(result, "RandomNum", "random_num", "RandomNumber"),
        barcode=_first(result, "BarCode", "barcode", "BarCode1"),
        qr_left=_first(result, "QRCodeL", "qr_code_l", "QRcodeL"),
        qr_right=_first(result, "QRCodeR", "qr_code_r", "QRcodeR"),
    )


def _from_ecpay(raw: dict[str, Any]) -> InvoiceProof:
    data = raw.get("Data") or raw.get("data") or {}
    return InvoiceProof(
        random_code=_first(data, "RandomNumber", "random_number"),
        barcode=_first(data, "BarCode", "barcode"),
        qr_left=_first(data, "QRCodeL", "qr_code_l"),
        qr_right=_first(data, "QRCodeR", "qr_code_r"),
    )


def _first(d: dict[str, Any], *keys: str) -> str | None:
    for k in keys:
        v = d.get(k)
        if v is not None and str(v).strip():
            return str(v)
    return None
