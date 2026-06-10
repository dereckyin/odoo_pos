from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel


class ShiftOpenRequest(BaseModel):
    id: str | None = None
    opening_cash_cents: int = Field(default=0, ge=0)
    note: str | None = Field(default=None, max_length=512)


class ShiftCloseRequest(BaseModel):
    counted_cash_cents: int = Field(default=0, ge=0)
    note: str | None = Field(default=None, max_length=512)


class ShiftRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    terminal_id: str | None
    user_id: str
    status: str
    opened_at: datetime | None
    closed_at: datetime | None
    opening_cash_cents: int
    counted_cash_cents: int
    expected_cash_cents: int
    diff_cents: int
    totals_json: dict | None = None
    note: str | None = None


class ShiftSummary(BaseModel):
    """Live tally used by the 交班結帳 screen before the shift is closed."""

    shift_id: str
    order_count: int
    sales_total_cents: int
    refund_total_cents: int
    by_method_cents: dict[str, int]
    cash_sales_cents: int
    cash_refunds_cents: int
    expected_cash_cents: int
