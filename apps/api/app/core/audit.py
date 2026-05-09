"""Lightweight audit-log writer.

Routes opt in by calling ``audit(db, scope, ...)``. We don't auto-instrument
through middleware because ``before`` / ``after`` snapshots are usually
domain-specific and easier to capture explicitly.
"""
from __future__ import annotations

from typing import Any

from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import AuditLog
from .deps import CurrentUser


def _client_info(request: Request | None) -> tuple[str | None, str | None]:
    if request is None:
        return None, None
    ip = request.client.host if request.client else None
    if "x-forwarded-for" in request.headers:
        ip = request.headers["x-forwarded-for"].split(",")[0].strip()
    ua = request.headers.get("user-agent")
    return ip, ua


async def audit(
    db: AsyncSession,
    scope: CurrentUser | None,
    *,
    action: str,
    resource_type: str,
    resource_id: str | None = None,
    request: Request | None = None,
    before: dict[str, Any] | None = None,
    after: dict[str, Any] | None = None,
    extra: dict[str, Any] | None = None,
    tenant_id: str | None = None,
    user_id: str | None = None,
    flush: bool = True,
) -> None:
    """Append an audit row.

    Either pass a ``CurrentUser`` (regular endpoints) or use the
    ``tenant_id`` / ``user_id`` overrides for pre-authentication flows
    (e.g. login, where there is no JWT yet but we still want to attribute
    the event to the resolved user)."""
    ip, ua = _client_info(request)
    resolved_tenant = scope.tenant_id if scope else tenant_id
    resolved_user = scope.user_id if scope else user_id
    db.add(
        AuditLog(
            tenant_id=resolved_tenant,
            user_id=resolved_user,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            ip=ip,
            user_agent=ua,
            before=before,
            after=after,
            extra=extra,
        )
    )
    if flush:
        await db.flush()
