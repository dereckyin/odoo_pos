from sqlalchemy import JSON, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import Timestamped


class IdempotencyKey(Base, Timestamped):
    __tablename__ = "idempotency_keys"

    key: Mapped[str] = mapped_column(String(64), primary_key=True)
    method: Mapped[str] = mapped_column(String(8))
    path: Mapped[str] = mapped_column(String(256))
    status_code: Mapped[int] = mapped_column(Integer)
    response: Mapped[dict | None] = mapped_column(JSON, nullable=True)
