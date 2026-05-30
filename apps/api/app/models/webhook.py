from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class WebhookSubscription(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "webhook_subscriptions"

    tenant_id: Mapped[str] = mapped_column(ForeignKey("tenants.id"), index=True, nullable=False)
    url: Mapped[str] = mapped_column(String(512))
    secret: Mapped[str | None] = mapped_column(String(128), nullable=True)
    events: Mapped[list] = mapped_column(JSON, default=list)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class WebhookDelivery(Base, UUIDPrimaryKey, Timestamped):
    __tablename__ = "webhook_deliveries"

    subscription_id: Mapped[str] = mapped_column(
        ForeignKey("webhook_subscriptions.id"), index=True, nullable=False
    )
    event: Mapped[str] = mapped_column(String(64), index=True)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    status: Mapped[str] = mapped_column(String(16), default="pending")  # pending | delivered | failed
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    last_error: Mapped[str | None] = mapped_column(Text, nullable=True)
    delivered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
