"""Staff (POS) endpoints for table sessions and listing dining tables."""
from __future__ import annotations

import os
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import DbSession, TenantScope, apply_tenant, ensure_same_tenant
from ...models import DiningTable, Store, TableSession
from ...schemas.dining_table import DiningTableRead
from ...schemas.table_session import TableSessionOpenResponse, TableSessionRead
from ...services.tenant_modules import require_online_ordering

router = APIRouter(
    prefix="/dining-tables",
    tags=["dining-tables"],
    dependencies=[Depends(require_online_ordering)],
)

_DEFAULT_SESSION_HOURS = 4


def _new_session_token() -> str:
    return secrets.token_urlsafe(24)[:32]


def _customer_base_url() -> str:
    return os.environ.get("CUSTOMER_BASE_URL", "https://pos.myvnc.com/customer").rstrip("/")


@router.get("", response_model=list[DiningTableRead])
async def list_store_tables(
    db: DbSession,
    scope: TenantScope,
    store_id: str | None = Query(default=None),
):
    target = store_id or scope.store_id
    if not target:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "store_id required")
    stmt = apply_tenant(
        select(DiningTable).where(
            DiningTable.deleted_at.is_(None),
            DiningTable.is_active.is_(True),
            DiningTable.store_id == target,
        ),
        DiningTable,
        scope,
    ).order_by(DiningTable.label)
    return (await db.execute(stmt)).scalars().all()


async def _close_open_sessions_for_table(db, table_id: str) -> None:
    now = datetime.now(timezone.utc)
    rows = (
        await db.execute(
            select(TableSession).where(
                TableSession.table_id == table_id,
                TableSession.status == "open",
            )
        )
    ).scalars().all()
    for s in rows:
        s.status = "closed"
        s.closed_at = now


@router.post("/{tid}/sessions", response_model=TableSessionOpenResponse, status_code=201)
async def open_table_session(tid: str, db: DbSession, scope: TenantScope):
    table = await db.get(DiningTable, tid)
    if not table or table.deleted_at or not table.is_active:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "table not found")
    ensure_same_tenant(scope, table)

    await _close_open_sessions_for_table(db, table.id)

    expires = datetime.now(timezone.utc) + timedelta(hours=_DEFAULT_SESSION_HOURS)
    session = TableSession(
        tenant_id=table.tenant_id,
        store_id=table.store_id,
        table_id=table.id,
        session_token=_new_session_token(),
        status="open",
        opened_by=scope.user_id,
        expires_at=expires,
    )
    db.add(session)
    await audit(
        db,
        scope,
        action="table_session_open",
        resource_type="table_session",
        flush=False,
    )
    await db.commit()
    await db.refresh(session)

    url = f"{_customer_base_url()}/order?t={session.session_token}"
    return TableSessionOpenResponse(
        session=TableSessionRead.model_validate(session),
        table_label=table.label,
        customer_order_url=url,
    )


@router.post("/sessions/{sid}/close", response_model=TableSessionRead)
async def close_table_session(sid: str, db: DbSession, scope: TenantScope):
    session = await db.get(TableSession, sid)
    if not session:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "session not found")
    ensure_same_tenant(scope, session)
    if session.status != "open":
        raise HTTPException(status.HTTP_409_CONFLICT, "session already closed")
    session.status = "closed"
    session.closed_at = datetime.now(timezone.utc)
    await audit(
        db,
        scope,
        action="table_session_close",
        resource_type="table_session",
        resource_id=sid,
        flush=False,
    )
    await db.commit()
    await db.refresh(session)
    return session


async def close_sessions_for_guest_table(db, table_id: str | None) -> None:
    """Called when a guest order is merged / completed to invalidate QR codes."""
    if not table_id:
        return
    await _close_open_sessions_for_table(db, table_id)
    await db.flush()
