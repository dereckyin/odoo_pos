from datetime import datetime

from pydantic import BaseModel

from ._base import ORMModel


class InventoryLevelRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    product_id: str
    on_hand: float
    safety_stock: float
    reserved: float
    updated_at: datetime
    store_name: str | None = None
    product_name: str | None = None
    product_sku: str | None = None


class InventoryLevelUpdate(BaseModel):
    safety_stock: float | None = None


class MovementCreate(BaseModel):
    """``store_id`` is optional; defaults to the JWT's store. ``user_id`` and
    ``terminal_id`` are likewise derived from the session."""

    id: str
    store_id: str | None = None
    product_id: str
    qty_delta: float
    reason: str
    ref_type: str | None = None
    ref_id: str | None = None
    terminal_id: str | None = None
    user_id: str | None = None
    note: str | None = None
    client_created_at: datetime


class MovementRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    product_id: str
    qty_delta: float
    reason: str
    ref_type: str | None
    ref_id: str | None
    created_at: datetime


class TransferLineIn(BaseModel):
    id: str
    product_id: str
    qty: float
    received_qty: float | None = None


class TransferCreate(BaseModel):
    id: str
    from_store_id: str
    to_store_id: str
    status: str = "draft"
    note: str | None = None
    lines: list[TransferLineIn]


class TransferUpdate(BaseModel):
    status: str


class TransferRead(ORMModel):
    id: str
    tenant_id: str
    from_store_id: str
    to_store_id: str
    status: str
    dispatched_at: datetime | None
    received_at: datetime | None
    note: str | None
    created_at: datetime


class StocktakeLineIn(BaseModel):
    id: str
    product_id: str
    expected_qty: float
    actual_qty: float


class StocktakeCreate(BaseModel):
    id: str
    store_id: str | None = None
    note: str | None = None
    lines: list[StocktakeLineIn]


class StocktakeRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    completed_at: datetime | None
    note: str | None
    created_at: datetime


class InventoryAdjustCreate(BaseModel):
    store_id: str
    product_id: str
    mode: str = "delta"  # delta | set
    qty: float
    note: str | None = None
    reason: str = "adjustment"  # adjustment | initial
