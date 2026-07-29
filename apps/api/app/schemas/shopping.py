"""Schemas for the unified shopping (/shopping/) public channel."""
from datetime import datetime

from pydantic import BaseModel, Field

from .guest_order import GuestOrderLineCreate, GuestOrderLineRead
from .public import PublicCategory, PublicProduct


class ShoppingStoreSummary(BaseModel):
    id: str
    name: str
    address: str | None = None
    phone: str | None = None
    supports_pickup: bool = True
    supports_delivery: bool = False
    supports_dine_in: bool = True
    payment_counter: bool = True
    payment_online: bool = False
    min_order_cents: int = 0
    delivery_fee_cents: int = 0
    is_open: bool = True


class ShoppingMenuMeta(BaseModel):
    """Mirrors marketplace menu meta so shopping_web can reuse the same adapter."""

    table_id: str = ""
    table_label: str = ""
    store_id: str
    store_name: str
    store_address: str | None = None
    slug: str  # store UUID for shopping channel
    display_name: str
    tagline: str | None = None
    logo_url: str | None = None
    supports_pickup: bool = True
    supports_delivery: bool = False
    supports_dine_in: bool = True
    payment_counter: bool = True
    payment_online: bool = False
    min_order_cents: int = 0
    delivery_fee_cents: int = 0
    is_open: bool = True


class ShoppingMenu(BaseModel):
    meta: ShoppingMenuMeta
    categories: list[PublicCategory]
    root_category_ids: list[str] = Field(default_factory=list)
    products: list[PublicProduct]


class ShoppingOrderSubmit(BaseModel):
    fulfillment_type: str = Field(description="pickup | delivery | dine_in")
    payment_method: str = Field(description="counter | online")
    customer_name: str = Field(min_length=1, max_length=64)
    customer_phone: str = Field(min_length=1, max_length=32)
    customer_note: str | None = None
    party_size: int | None = Field(default=None, ge=1)
    delivery_address: str | None = None
    delivery_lat: float | None = None
    delivery_lng: float | None = None
    delivery_note: str | None = None
    table_label: str | None = None
    lines: list[GuestOrderLineCreate]


class ShoppingOrderCreated(BaseModel):
    order_id: str
    access_token: str
    payment_method: str
    payment_status: str | None = None
    estimated_subtotal_cents: int


class ShoppingOrderRead(BaseModel):
    id: str
    status: str
    channel: str
    fulfillment_type: str | None
    payment_method: str | None
    payment_status: str | None
    delivery_status: str | None
    customer_name: str | None
    customer_phone: str | None
    delivery_address: str | None
    store_name: str
    store_id: str
    estimated_subtotal_cents: int
    discount_cents: int = 0
    customer_note: str | None
    party_size: int | None
    created_at: datetime
    accepted_at: datetime | None
    ready_at: datetime | None
    merged_at: datetime | None
    cancelled_at: datetime | None
    lines: list[GuestOrderLineRead]
