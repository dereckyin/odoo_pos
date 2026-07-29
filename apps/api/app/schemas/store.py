from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field

from ._base import ORMModel


class OnlineOrderingSettings(BaseModel):
    enabled: bool = False
    supports_pickup: bool = True
    supports_dine_in: bool = True
    supports_delivery: bool = False
    payment_counter: bool = True
    payment_online: bool = False
    min_order_cents: int = Field(default=0, ge=0)
    delivery_fee_cents: int = Field(default=0, ge=0)


class StoreRead(ORMModel):
    id: str
    tenant_id: str
    code: str
    name: str
    tax_id: str | None
    address: str | None
    phone: str | None
    latitude: float | None = None
    longitude: float | None = None
    geocoded_at: datetime | None = None
    geocode_label: str | None = None
    online_ordering_json: dict[str, Any] | None = None
    updated_at: datetime


class StoreCreate(BaseModel):
    code: str = Field(min_length=1, max_length=32)
    name: str = Field(min_length=1, max_length=128)
    tax_id: str | None = None
    address: str | None = None
    phone: str | None = None
    online_ordering_json: OnlineOrderingSettings | None = None


class StoreUpdate(BaseModel):
    code: str | None = None
    name: str | None = None
    tax_id: str | None = None
    address: str | None = None
    phone: str | None = None
    online_ordering_json: OnlineOrderingSettings | None = None


class TerminalRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    code: str
    last_seen_at: datetime | None
