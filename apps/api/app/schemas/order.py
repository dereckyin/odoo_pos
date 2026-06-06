from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel
from .option import SelectedOptionSnapshot


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
    options_json: list[SelectedOptionSnapshot] | None = None


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
    """Payload uploaded by POS once an order is paid.

    ``tenant_id`` / ``store_id`` / ``terminal_id`` / ``cashier_id`` are derived
    from the JWT on the server side and any matching field in the request
    body is ignored. They stay in the schema as optional only so older POS
    clients keep parsing.
    """

    id: str
    store_id: str | None = None
    terminal_id: str | None = None
    cashier_id: str | None = None
    member_id: str | None = None
    status: str = "paid"
    subtotal_cents: int
    discount_cents: int
    tax_cents: int
    total_cents: int
    invoice_carrier: str | None = None
    note: str | None = None
    source_guest_order_id: str | None = None
    points_redeemed: int = 0
    coupon_code: str | None = None
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
    options_json: list[SelectedOptionSnapshot] | None = None
    product_kind: str = "regular"
    consignment_book_share_cents: int = 0
    consignment_restaurant_share_cents: int = 0


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
    order_no: str | None = None
    tenant_id: str
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
    points_redeemed: int = 0
    coupon_code: str | None = None
    invoice_number: str | None
    invoice_carrier: str | None
    note: str | None
    source_guest_order_id: str | None = None
    created_at: datetime
    client_created_at: datetime | None
    lines: list[OrderLineRead]
    payments: list[PaymentRead]


class OrderListItem(OrderRead):
    store_name: str | None = None
    cashier_name: str | None = None
    member_name: str | None = None
    payment_methods: list[str] = []
    source: str = "pos"


class OrderListResponse(BaseModel):
    items: list[OrderListItem]
    total: int
    offset: int
    limit: int


class RefundLineCreate(BaseModel):
    order_line_id: str
    qty: float
    amount_cents: int


class RefundCreate(BaseModel):
    """Refund payload. ``user_id`` is now optional because the server
    automatically uses the authenticated cashier."""

    id: str
    user_id: str | None = None
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
