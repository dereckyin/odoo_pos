from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass
class InvoiceLine:
    name: str
    qty: float
    unit_price_cents: int
    amount_cents: int
    tax_type: int = 1
    note: str | None = None


@dataclass
class InvoiceIssueRequest:
    order_id: str
    total_cents: int
    tax_cents: int
    tax_type: int = 1  # 1=應稅, 2=零稅率, 3=免稅
    carrier_type: str | None = None  # mobile / citizenDigital / member / None
    carrier_code: str | None = None
    tax_id: str | None = None
    company_name: str | None = None
    donation_code: str | None = None
    email: str | None = None
    lines: list[InvoiceLine] = field(default_factory=list)


@dataclass
class InvoiceVoidRequest:
    invoice_number: str
    reason: str | None = None


@dataclass
class InvoiceResult:
    gateway: str
    status: str  # issued | voided | failed
    invoice_number: str | None = None
    invoice_date: datetime | None = None
    random_code: str | None = None
    barcode: str | None = None
    qr_left: str | None = None
    qr_right: str | None = None
    raw: dict[str, Any] | None = None


class InvoiceDriver(ABC):
    name: str = "abstract"

    @abstractmethod
    async def issue(self, req: InvoiceIssueRequest) -> InvoiceResult: ...

    @abstractmethod
    async def void(self, req: InvoiceVoidRequest) -> InvoiceResult: ...
