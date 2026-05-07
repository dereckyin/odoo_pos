from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel


class OrderLineCreate(BaseModel):
    id: str
    product_id: str
    product_name: str
    sku: str
    qty: float
    unit_price_cents: int
    line_discount_cents: int = 0
    line_total_cents: int
    tax_rate: float = 0.05
    note: str | None = None


class PaymentCreate(BaseModel):
    id: str
    method: str
    amount_cents: int
    status: str = "captured"
    gateway_ref: str | None = None
    gateway_response: dict | None = None
    tendered_cents: int | None = None
    change_due_cents: int | None = None


class OrderCreate(BaseModel):
    """Payload uploaded by POS once an order is paid."""

    id: str
    store_id: str
    terminal_id: str
    cashier_id: str
    member_id: str | None = None
    status: str = "paid"
    subtotal_cents: int
    discount_cents: int
    tax_cents: int
    total_cents: int
    invoice_carrier: str | None = None
    note: str | None = None
    client_created_at: datetime
    lines: list[OrderLineCreate]
    payments: list[PaymentCreate]


class OrderLineRead(ORMModel):
    id: str
    product_id: str
    product_name: str
    sku: str
    qty: float
    unit_price_cents: int
    line_discount_cents: int
    line_total_cents: int
    tax_rate: float
    note: str | None


class PaymentRead(ORMModel):
    id: str
    method: str
    amount_cents: int
    status: str
    gateway_ref: str | None
    tendered_cents: int | None
    change_due_cents: int | None


class OrderRead(ORMModel):
    id: str
    store_id: str
    terminal_id: str
    cashier_id: str
    member_id: str | None
    status: str
    subtotal_cents: int
    discount_cents: int
    tax_cents: int
    total_cents: int
    refunded_cents: int
    invoice_number: str | None
    invoice_carrier: str | None
    note: str | None
    created_at: datetime
    client_created_at: datetime | None
    lines: list[OrderLineRead]
    payments: list[PaymentRead]


class RefundLineCreate(BaseModel):
    order_line_id: str
    qty: float
    amount_cents: int


class RefundCreate(BaseModel):
    id: str
    user_id: str
    method: str = "cash"
    reason: str | None = None
    lines: list[RefundLineCreate] = Field(default_factory=list)
    """Empty `lines` means full refund."""


class RefundRead(ORMModel):
    id: str
    order_id: str
    user_id: str
    method: str
    total_amount_cents: int
    reason: str | None
    gateway_ref: str | None
    created_at: datetime
