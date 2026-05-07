from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey


class User(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "users"

    username: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(128))
    display_name: Mapped[str] = mapped_column(String(128))
    role: Mapped[str] = mapped_column(String(32), default="cashier")
    store_id: Mapped[str | None] = mapped_column(ForeignKey("stores.id"), nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True)
