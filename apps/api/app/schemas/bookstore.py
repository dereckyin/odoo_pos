from __future__ import annotations

import re
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator

StockStatus = Literal["in_stock", "last_one", "out_of_stock"]

_MOBILE_CARRIER = re.compile(r"^/[0-9A-Z.+\-]{7}$")
_CITIZEN_CARRIER = re.compile(r"^[A-Z]{2}[0-9]{14}$")
_TAX_ID = re.compile(r"^[0-9]{8}$")
_DONATION = re.compile(r"^[0-9]{3,7}$")


class BookstoreStoreRead(BaseModel):
    id: str
    code: str
    name: str
    address: str | None = None
    phone: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    is_open: bool = True
    cash_enabled: bool = True
    cash_price_pct: int = 100
    online_payment_enabled: bool = False


class DoorQrResolveRequest(BaseModel):
    content: str = Field(min_length=1, max_length=1024)


class DoorQrResolveResponse(BaseModel):
    store: BookstoreStoreRead
    presence_token: str
    presence_expires_at: datetime


class BookstoreCategoryRead(BaseModel):
    id: str
    name: str


class BookstoreProductRead(BaseModel):
    id: str
    name: str
    author: str | None = None
    publisher: str | None = None
    isbn: str | None = None
    image_url: str | None = None
    description: str | None = None
    category_id: str | None = None
    category_name: str | None = None
    price_cents: int
    list_price_cents: int | None = None
    stock_status: StockStatus
    max_qty: int = 0


class BookstoreProductPage(BaseModel):
    items: list[BookstoreProductRead]
    total: int
    page: int
    page_size: int


class CheckoutLineIn(BaseModel):
    product_id: str = Field(min_length=1, max_length=36)
    qty: int = Field(ge=1, le=99)


class InvoiceIn(BaseModel):
    carrier_type: Literal["mobile", "citizenDigital"] | None = None
    carrier_code: str | None = Field(default=None, max_length=64)
    tax_id: str | None = Field(default=None, max_length=16)
    donation_code: str | None = Field(default=None, max_length=16)

    @model_validator(mode="after")
    def _check(self) -> "InvoiceIn":
        chosen = [bool(self.carrier_type), bool(self.tax_id), bool(self.donation_code)]
        if sum(chosen) > 1:
            raise ValueError("choose only one of carrier, tax_id or donation_code")
        if self.carrier_type == "mobile" and not _MOBILE_CARRIER.match(self.carrier_code or ""):
            raise ValueError("invalid mobile carrier code")
        if self.carrier_type == "citizenDigital" and not _CITIZEN_CARRIER.match(self.carrier_code or ""):
            raise ValueError("invalid citizen digital certificate carrier")
        if not self.carrier_type and self.carrier_code:
            raise ValueError("carrier_code requires carrier_type")
        if self.tax_id and not _TAX_ID.match(self.tax_id):
            raise ValueError("invalid tax_id")
        if self.donation_code and not _DONATION.match(self.donation_code):
            raise ValueError("invalid donation_code")
        return self


class CheckoutCreate(BaseModel):
    store_id: str = Field(min_length=1, max_length=36)
    presence_token: str = Field(min_length=1, max_length=1024)
    client_request_id: str = Field(min_length=8, max_length=64, pattern=r"^[A-Za-z0-9\-_]+$")
    lines: list[CheckoutLineIn] = Field(min_length=1)
    invoice: InvoiceIn | None = None

    @field_validator("lines")
    @classmethod
    def _merge_duplicates(cls, v: list[CheckoutLineIn]) -> list[CheckoutLineIn]:
        merged: dict[str, int] = {}
        for ln in v:
            merged[ln.product_id] = merged.get(ln.product_id, 0) + ln.qty
        return [CheckoutLineIn(product_id=k, qty=q) for k, q in merged.items()]


class CheckoutLineRead(BaseModel):
    product_id: str
    product_name: str
    isbn: str | None = None
    qty: int
    unit_price_cents: int
    line_total_cents: int


class ExitPassRead(BaseModel):
    token: str
    code: str
    expires_at: datetime


class CashPaymentRead(BaseModel):
    """Shown by the app at the counter; staff scan ``token`` or type ``code``."""

    token: str
    code: str
    expires_at: datetime


class CheckoutRead(BaseModel):
    id: str
    store_id: str
    store_name: str
    status: str
    subtotal_cents: int
    discount_cents: int = 0
    tax_cents: int
    total_cents: int
    payment_method: str | None = None
    cash_payment: CashPaymentRead | None = None
    expires_at: datetime
    paid_at: datetime | None = None
    invoice_status: str
    invoice_number: str | None = None
    order_no: str | None = None
    exit_verified_at: datetime | None = None
    exit_pass: ExitPassRead | None = None
    lines: list[CheckoutLineRead]
    created_at: datetime


class PaymentStartRequest(BaseModel):
    return_url: str | None = Field(default=None, max_length=512)


class PaymentStartResponse(BaseModel):
    checkout_id: str
    payment_url: str
    expires_at: datetime


class ExitVerifyRequest(BaseModel):
    token: str | None = Field(default=None, max_length=1024)
    code: str | None = Field(default=None, max_length=8)
    store_id: str | None = None

    @model_validator(mode="after")
    def _one(self) -> "ExitVerifyRequest":
        if not self.token and not self.code:
            raise ValueError("token or code required")
        return self


class ExitVerifyResponse(BaseModel):
    result: Literal["valid", "already_used", "expired", "not_paid", "invalid"]
    checkout_id: str | None = None
    order_no: str | None = None
    total_cents: int | None = None
    paid_at: datetime | None = None
    verified_at: datetime | None = None
    lines: list[CheckoutLineRead] = []


class StaffCheckoutRead(BaseModel):
    id: str
    store_id: str
    status: str
    subtotal_cents: int = 0
    discount_cents: int = 0
    total_cents: int
    payment_method: str | None = None
    expires_at: datetime | None = None
    order_no: str | None = None
    invoice_status: str
    invoice_number: str | None = None
    paid_at: datetime | None = None
    paid_after_expiry: bool = False
    exit_verified_at: datetime | None = None
    refunded_at: datetime | None = None
    created_at: datetime
    lines: list[CheckoutLineRead]


class RefundRequest(BaseModel):
    reason: str = Field(min_length=1, max_length=500)


class RefundResponse(BaseModel):
    checkout: StaffCheckoutRead
    invoice_voided: bool
    gateway_refund: Literal["manual"]
    message: str


class DoorQrRead(BaseModel):
    content: str
    expires_at: datetime


class BookstoreSettingsUpdate(BaseModel):
    is_open: bool | None = None
    cash_enabled: bool | None = None
    cash_price_pct: int | None = Field(default=None, ge=50, le=100)
    online_payment_enabled: bool | None = None


class CashLookupRequest(BaseModel):
    token: str | None = Field(default=None, max_length=1024)
    code: str | None = Field(default=None, max_length=8)
    store_id: str | None = None

    @model_validator(mode="after")
    def _one(self) -> "CashLookupRequest":
        if not self.token and not self.code:
            raise ValueError("token or code required")
        return self


class CashLookupResponse(BaseModel):
    result: Literal["found", "invalid", "already_paid", "closed"]
    checkout: StaffCheckoutRead | None = None


class CashConfirmRequest(BaseModel):
    store_id: str | None = None
    expected_total_cents: int = Field(ge=1)
