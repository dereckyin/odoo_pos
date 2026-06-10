from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from ..core.db import Base
from ._mixins import SoftDelete, Timestamped, UUIDPrimaryKey

# Role hierarchy (highest authority first):
#   platform_super  - cross-tenant administrator (the SaaS operator)
#   tenant_owner    - owns the tenant; can do anything within it
#   tenant_admin    - manages tenant-wide config (products, members, ...)
#   store_manager   - manages a single store (settings + reports)
#   cashier         - operates POS, refunds limited
#   kitchen         - read guest orders + state transitions only
ALL_ROLES = (
    "platform_super",
    "tenant_owner",
    "tenant_admin",
    "store_manager",
    "cashier",
    "kitchen",
)
TENANT_ADMIN_ROLES = {"tenant_owner", "tenant_admin", "platform_super", "admin"}
STORE_ADMIN_ROLES = TENANT_ADMIN_ROLES | {"store_manager"}


class User(Base, UUIDPrimaryKey, Timestamped, SoftDelete):
    __tablename__ = "users"
    __table_args__ = (
        UniqueConstraint("tenant_id", "username", name="uq_user_tenant_username"),
        UniqueConstraint("tenant_id", "employee_id", name="uq_user_tenant_employee"),
    )

    tenant_id: Mapped[str | None] = mapped_column(ForeignKey("tenants.id"), nullable=True, index=True)
    username: Mapped[str] = mapped_column(String(64), index=True)
    password_hash: Mapped[str] = mapped_column(String(128))
    display_name: Mapped[str] = mapped_column(String(128))
    role: Mapped[str] = mapped_column(String(32), default="cashier")
    store_id: Mapped[str | None] = mapped_column(ForeignKey("stores.id"), nullable=True)
    email: Mapped[str | None] = mapped_column(String(128), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    must_change_password: Mapped[bool] = mapped_column(Boolean, default=False)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    failed_login_count: Mapped[int] = mapped_column(Integer, default=0)
    locked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Employee-ID + PIN fast login (layer 2/3 staff switch on a trusted terminal).
    employee_id: Mapped[str | None] = mapped_column(String(32), nullable=True, index=True)
    pin_hash: Mapped[str | None] = mapped_column(String(128), nullable=True)
    pin_failed_count: Mapped[int] = mapped_column(Integer, default=0)
    pin_locked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Two-factor (TOTP) for layer-1 admins.
    totp_secret: Mapped[str | None] = mapped_column(String(64), nullable=True)
    totp_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
