from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel


class SupplierRead(ORMModel):
    id: str
    tenant_id: str
    code: str
    name: str
    contact_name: str | None
    phone: str | None
    note: str | None
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None


class SupplierCreate(BaseModel):
    code: str = Field(max_length=32)
    name: str = Field(max_length=128)
    contact_name: str | None = Field(default=None, max_length=128)
    phone: str | None = Field(default=None, max_length=32)
    note: str | None = None


class SupplierUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=128)
    contact_name: str | None = None
    phone: str | None = None
    note: str | None = None


class PurchaseOrderLineIn(BaseModel):
    id: str
    product_id: str
    qty_ordered: float = Field(gt=0)


class PurchaseOrderLineRead(ORMModel):
    id: str
    purchase_order_id: str
    product_id: str
    qty_ordered: float
    qty_received: float
    created_at: datetime
    updated_at: datetime


class PurchaseOrderCreate(BaseModel):
    id: str
    store_id: str
    supplier_id: str
    reference: str | None = Field(default=None, max_length=64)
    note: str | None = None
    lines: list[PurchaseOrderLineIn] = Field(min_length=1)


class PurchaseOrderRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    supplier_id: str
    status: str
    reference: str | None
    ordered_at: datetime | None
    note: str | None
    created_at: datetime
    updated_at: datetime
    lines: list[PurchaseOrderLineRead]


class PurchaseOrderStatusPatch(BaseModel):
    status: str


class ReceiveLineIn(BaseModel):
    line_id: str
    qty: float = Field(gt=0)


class PurchaseOrderReceive(BaseModel):
    lines: list[ReceiveLineIn] = Field(min_length=1)
