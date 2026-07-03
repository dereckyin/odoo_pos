from datetime import datetime

from pydantic import BaseModel

from ._base import ORMModel


class TableSessionRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    table_id: str
    session_token: str
    status: str
    opened_by: str | None
    expires_at: datetime | None
    closed_at: datetime | None
    created_at: datetime


class TableSessionOpenResponse(BaseModel):
    session: TableSessionRead
    table_label: str
    customer_order_url: str
