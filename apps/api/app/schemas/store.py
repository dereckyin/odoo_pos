from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel


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
    updated_at: datetime


class StoreCreate(BaseModel):
    code: str = Field(min_length=1, max_length=32)
    name: str = Field(min_length=1, max_length=128)
    tax_id: str | None = None
    address: str | None = None
    phone: str | None = None


class StoreUpdate(BaseModel):
    code: str | None = None
    name: str | None = None
    tax_id: str | None = None
    address: str | None = None
    phone: str | None = None


class TerminalRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    code: str
    last_seen_at: datetime | None
