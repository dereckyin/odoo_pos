from datetime import datetime

from pydantic import BaseModel

from ._base import ORMModel


class StoreRead(ORMModel):
    id: str
    code: str
    name: str
    tax_id: str | None
    address: str | None
    phone: str | None
    updated_at: datetime


class StoreCreate(BaseModel):
    code: str
    name: str
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
    store_id: str
    code: str
    last_seen_at: datetime | None
