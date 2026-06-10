from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class PosShift(Base, UUIDPrimaryKey, Timestamped):
    """A cashier work shift on a terminal.

    Opened at clock-in (login) and closed at 交班結帳. On close we compute the
    expected cash drawer from sales/refunds during the shift and compare it to
    the counted cash so the manager can reconcile the difference.
    """

    __tablename__ = "pos_shifts"

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"), index=True, nullable=False)
    terminal_id: Mapped[str | None] = mapped_column(ForeignKey("terminals.id"), nullable=True, index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True, nullable=False)

    status: Mapped[str] = mapped_column(String(16), default="open", index=True)
    opened_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    closed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    opening_cash_cents: Mapped[int] = mapped_column(Integer, default=0)
    counted_cash_cents: Mapped[int] = mapped_column(Integer, default=0)
    expected_cash_cents: Mapped[int] = mapped_column(Integer, default=0)
    diff_cents: Mapped[int] = mapped_column(Integer, default=0)

    # Per-payment-method totals computed at close, e.g. {"cash": 1234, ...}.
    totals_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
