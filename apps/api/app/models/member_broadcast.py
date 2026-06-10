from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import Timestamped, UUIDPrimaryKey


class MemberBroadcast(Base, UUIDPrimaryKey, Timestamped):
    """A record of an SMS broadcast sent to marketing-opted-in members."""

    __tablename__ = "member_broadcasts"

    tenant_id: Mapped[str] = mapped_column(
        ForeignKey("tenants.id"), index=True, nullable=False
    )
    channel: Mapped[str] = mapped_column(String(16), default="sms", server_default="sms")
    message: Mapped[str] = mapped_column(Text, nullable=False)
    audience_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    sent_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    failed_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    created_by: Mapped[str | None] = mapped_column(String(36), nullable=True)
