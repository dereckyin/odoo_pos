from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field

from ._base import ORMModel

PrinterRole = Literal["receipt", "kitchen", "label"]
DocType = Literal["receipt", "kitchen_ticket", "confirmation", "label", "qr_slip", "invoice_proof"]
PrintJobStatus = Literal["pending", "printing", "done", "failed"]


class PrintJobCreate(BaseModel):
    id: str | None = None
    store_id: str | None = None
    printer_role: PrinterRole
    doc_type: DocType
    payload: dict[str, Any] = Field(default_factory=dict)


class PrintJobRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    printer_role: str
    doc_type: str
    payload: dict[str, Any]
    status: str
    retry_count: int
    last_error: str | None
    claimed_at: datetime | None
    completed_at: datetime | None
    created_at: datetime
    updated_at: datetime


class PrintJobFailRequest(BaseModel):
    error: str = Field(min_length=1, max_length=2000)


class PrintJobPendingResponse(BaseModel):
    items: list[PrintJobRead]
