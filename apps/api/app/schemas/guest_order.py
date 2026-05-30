from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel
from .option import SelectedOptionSnapshot


class GuestOrderLineCreate(BaseModel):
    product_id: str
    qty: float = Field(gt=0)
    note: str | None = None
    options: list[SelectedOptionSnapshot] | None = None


class GuestOrderSubmit(BaseModel):
    """Public payload from the customer Vue page. The server snapshots the
    product name / price at the time of submission so a later admin price
    change does not silently rewrite the customer's basket."""

    customer_note: str | None = None
    party_size: int | None = Field(default=None, ge=1)
    member_id: str | None = None
    lines: list[GuestOrderLineCreate]


class GuestOrderLineRead(ORMModel):
    id: str
    product_id: str
    product_name: str
    sku: str
    qty: float
    unit_price_cents: int
    line_total_cents: int
    note: str | None
    options_json: list[SelectedOptionSnapshot] | None = None
    created_at: datetime


class GuestOrderRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    table_id: str
    table_label: str | None = None
    status: str
    customer_note: str | None
    party_size: int | None
    member_id: str | None = None
    estimated_subtotal_cents: int
    accepted_at: datetime | None
    ready_at: datetime | None
    merged_at: datetime | None
    cancelled_at: datetime | None
    accepted_by_user_id: str | None
    merged_order_id: str | None
    cancel_reason: str | None
    created_at: datetime
    updated_at: datetime
    lines: list[GuestOrderLineRead]


class CancelRequest(BaseModel):
    reason: str | None = None


class MergeRequest(BaseModel):
    """Sent by POS once a paid Order has been uploaded (or about to be).
    `order_id` is the canonical paid Order id; the server stamps
    ``source_guest_order_id`` on the order and flips the guest_order to
    ``merged``."""

    order_id: str
