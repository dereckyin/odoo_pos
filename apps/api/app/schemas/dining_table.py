from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel


class DiningTableRead(ORMModel):
    id: str
    store_id: str
    label: str
    public_token: str
    seats: int | None
    is_active: bool
    note: str | None
    updated_at: datetime
    created_at: datetime


class DiningTableCreate(BaseModel):
    store_id: str
    label: str = Field(min_length=1, max_length=32)
    seats: int | None = None
    is_active: bool = True
    note: str | None = None


class DiningTableUpdate(BaseModel):
    label: str | None = None
    seats: int | None = None
    is_active: bool | None = None
    note: str | None = None


class DiningTableTokenResponse(BaseModel):
    """Returned by the rotate-token endpoint and embedded in the public meta
    response. Includes only the new token; clients build the customer URL on
    their side from a configured base URL."""

    id: str
    public_token: str
