"""Auth + tenant-scope dependencies for FastAPI routes.

The single source of truth is the JWT issued by ``api/v1/auth.py``. Every
authenticated endpoint MUST take ``CurrentUserDep`` (or one of the
specialisations below); resource queries MUST then pass the resulting
``TenantScope`` through ``apply_tenant`` / ``ensure_same_tenant`` so a
mistake at the route layer cannot leak data across tenants.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import RefreshToken, TENANT_ADMIN_ROLES, STORE_ADMIN_ROLES
from .db import get_db
from .security import decode_token


class CurrentUser:
    """The decoded JWT, plus a few convenience checks. ``store_id`` may be
    None for tenant-wide admins; ``tenant_id`` may be None only for the
    platform super-admin. Treat both as untrusted from the client."""

    __slots__ = ("user_id", "username", "role", "tenant_id", "store_id", "terminal_id", "jti")

    def __init__(
        self,
        *,
        user_id: str,
        username: str,
        role: str,
        tenant_id: str | None,
        store_id: str | None,
        terminal_id: str | None,
        jti: str | None = None,
    ) -> None:
        self.user_id = user_id
        self.username = username
        self.role = role
        self.tenant_id = tenant_id
        self.store_id = store_id
        self.terminal_id = terminal_id
        self.jti = jti

    @property
    def is_platform_super(self) -> bool:
        return self.role == "platform_super"

    @property
    def is_tenant_admin(self) -> bool:
        return self.role in TENANT_ADMIN_ROLES

    @property
    def is_store_admin(self) -> bool:
        return self.role in STORE_ADMIN_ROLES

    def require_tenant(self) -> str:
        """Resolve the tenant for the current request, refusing the
        platform super-admin if they didn't pick one explicitly via
        ``X-Tenant-Id``. The dependency below already handles that hand-off."""
        if not self.tenant_id:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "tenant scope required (set X-Tenant-Id when acting as platform admin)",
            )
        return self.tenant_id


async def current_user(
    authorization: Annotated[str | None, Header()] = None,
    x_tenant_id: Annotated[str | None, Header(alias="X-Tenant-Id")] = None,
) -> CurrentUser:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer token")
    token = authorization.split(" ", 1)[1]
    try:
        claims = decode_token(token)
    except ValueError as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, str(e))
    if claims.get("type") == "refresh":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "refresh token cannot access resources")

    role = claims.get("role", "cashier")
    token_tenant = claims.get("tenant_id")
    # Only the platform super-admin may switch tenants via header. Everyone
    # else is locked to whatever the issuer stamped into the JWT.
    effective_tenant = token_tenant
    if role == "platform_super" and x_tenant_id:
        effective_tenant = x_tenant_id
    elif x_tenant_id and x_tenant_id != token_tenant:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "cross-tenant access not allowed")

    return CurrentUser(
        user_id=claims["sub"],
        username=claims.get("username", ""),
        role=role,
        tenant_id=effective_tenant,
        store_id=claims.get("store_id") or None,
        terminal_id=claims.get("terminal_id") or None,
        jti=claims.get("jti"),
    )


async def require_platform_super(
    user: Annotated[CurrentUser, Depends(current_user)],
) -> CurrentUser:
    if not user.is_platform_super:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "platform super-admin only")
    return user


async def require_tenant_admin(
    user: Annotated[CurrentUser, Depends(current_user)],
) -> CurrentUser:
    if not user.is_tenant_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "tenant admin only")
    user.require_tenant()
    return user


async def require_store_admin(
    user: Annotated[CurrentUser, Depends(current_user)],
) -> CurrentUser:
    if not user.is_store_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "store admin or above required")
    user.require_tenant()
    return user


async def require_active_session(
    user: Annotated[CurrentUser, Depends(current_user)],
) -> CurrentUser:
    """Same as ``current_user`` but enforces that any tenant scope exists
    (rejects the platform super if no ``X-Tenant-Id`` was supplied)."""
    user.require_tenant()
    return user


async def require_non_kitchen_session(
    user: Annotated[CurrentUser, Depends(require_active_session)],
) -> CurrentUser:
    """Active tenant session that additionally rejects the ``kitchen`` role.

    Kitchen is a KDS-only role (guest orders + state transitions). Use this to
    keep POS sales orders out of kitchen reach even at the API level, not just
    in the POS UI router."""
    if user.role == "kitchen":
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "kitchen role cannot access sales orders"
        )
    return user


def ensure_same_tenant(scope: CurrentUser, *resources) -> None:
    """Defensive check: every passed resource must have ``tenant_id``
    attribute matching the caller's tenant. Raises 404 (NOT 403) on mismatch
    to avoid leaking the existence of cross-tenant rows."""
    if scope.is_platform_super:
        return
    for r in resources:
        if r is None:
            continue
        rid = getattr(r, "tenant_id", None)
        if rid is not None and rid != scope.tenant_id:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "not found")


def apply_tenant(stmt, model, scope: CurrentUser):
    """Append a ``tenant_id == scope.tenant_id`` filter to the query. The
    platform super-admin sees everything when no specific tenant is set."""
    if scope.is_platform_super and not scope.tenant_id:
        return stmt
    return stmt.where(model.tenant_id == scope.tenant_id)


async def assert_refresh_token_valid(
    db: AsyncSession, jti: str | None, user_id: str
) -> RefreshToken:
    if not jti:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing jti")
    rt = (
        await db.execute(select(RefreshToken).where(RefreshToken.id == jti))
    ).scalar_one_or_none()
    if not rt or rt.user_id != user_id:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "refresh token unknown")
    if rt.revoked_at is not None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "refresh token revoked")
    expires = rt.expires_at
    if expires.tzinfo is None:
        # SQLite (used in tests) drops timezone info; assume UTC so the
        # comparison stays correct without a backend-specific branch.
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < datetime.now(timezone.utc):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "refresh token expired")
    return rt


DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUserDep = Annotated[CurrentUser, Depends(current_user)]
TenantScope = Annotated[CurrentUser, Depends(require_active_session)]
NonKitchenScope = Annotated[CurrentUser, Depends(require_non_kitchen_session)]
TenantAdminDep = Annotated[CurrentUser, Depends(require_tenant_admin)]
StoreAdminDep = Annotated[CurrentUser, Depends(require_store_admin)]
PlatformSuperDep = Annotated[CurrentUser, Depends(require_platform_super)]
# Backwards-compatible aliases so we don't churn callsites unnecessarily.
AdminDep = StoreAdminDep
