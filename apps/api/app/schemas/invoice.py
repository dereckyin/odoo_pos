from datetime import datetime

from pydantic import BaseModel

from ._base import ORMModel


class IssueInvoiceRequest(BaseModel):
    order_id: str
    tax_type: int = 1
    carrier_type: str | None = None
    carrier_code: str | None = None
    tax_id: str | None = None
    company_name: str | None = None
    donation_code: str | None = None
    email: str | None = None
    gateway: str = "ezpay"


class VoidInvoiceRequest(BaseModel):
    invoice_id: str
    reason: str | None = None


class InvoiceRead(ORMModel):
    id: str
    tenant_id: str
    order_id: str
    status: str
    invoice_number: str | None
    invoice_date: datetime | None
    total_cents: int
    tax_cents: int
    tax_type: int
    carrier_type: str | None
    carrier_code: str | None
    tax_id: str | None
    company_name: str | None
    donation_code: str | None
    gateway: str | None
    gateway_ref: str | None
    last_error: str | None
    created_at: datetime
