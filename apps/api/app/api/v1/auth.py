from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException, Request, status
from sqlalchemy import select

from ...core.audit import audit
from ...core.config import get_settings
from ...core.deps import (
    CurrentUserDep,
    DbSession,
    StoreAdminDep,
    assert_refresh_token_valid,
)
from ...core.ratelimit import per_ip
from ...core.security import (
    create_access_token,
    create_refresh_token,
    generate_secret,
    hash_password,
    hash_secret,
    verify_password,
    verify_secret,
)
from ...models import RefreshToken, Store, Tenant, Terminal, User, STORE_ADMIN_ROLES
from ...schemas.auth import (
    AdminLoginRequest,
    ChangePasswordRequest,
    HeartbeatRequest,
    LoginRequest,
    LogoutRequest,
    RefreshRequest,
    SessionRead,
    TerminalRegisterRequest,
    TerminalRegisterResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])

ACCOUNT_LOCK_THRESHOLD = 8
ACCOUNT_LOCK_MINUTES = 15


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def _persist_refresh_token(
    db, *, user: User, jti: str, expires_at: datetime, request: Request | None
) -> None:
    ip = None
    ua = None
    if request:
        ip = request.client.host if request.client else None
        ua = request.headers.get("user-agent")
    db.add(
        RefreshToken(
            id=jti,
            user_id=user.id,
            tenant_id=user.tenant_id,
            issued_at=_now(),
            expires_at=expires_at,
            ip=ip,
            user_agent=ua,
        )
    )


async def _build_session(
    db, *, user: User, tenant: Tenant | None, store_id: str | None, terminal_id: str | None,
    request: Request | None,
) -> SessionRead:
    settings = get_settings()
    claims = {
        "username": user.username,
        "role": user.role,
        "tenant_id": user.tenant_id,
        "store_id": store_id,
        "terminal_id": terminal_id,
    }
    access, access_exp = create_access_token(user.id, claims)
    refresh, jti, refresh_exp = create_refresh_token(user.id, claims)
    await _persist_refresh_token(
        db, user=user, jti=jti, expires_at=refresh_exp, request=request
    )
    user.last_login_at = _now()
    user.failed_login_count = 0
    user.locked_until = None
    return SessionRead(
        user_id=user.id,
        username=user.username,
        display_name=user.display_name,
        role=user.role,
        tenant_id=user.tenant_id,
        tenant_code=tenant.code if tenant else None,
        store_id=store_id,
        terminal_id=terminal_id,
        access_token=access,
        refresh_token=refresh,
        expires_at=access_exp.timestamp(),
        must_change_password=user.must_change_password,
    )


async def _get_user(db, *, tenant: Tenant | None, username: str) -> User | None:
    stmt = select(User).where(
        User.username == username, User.deleted_at.is_(None)
    )
    if tenant is None:
        # Platform super-admin (cross-tenant) login: tenant_id IS NULL.
        stmt = stmt.where(User.tenant_id.is_(None))
    else:
        stmt = stmt.where(User.tenant_id == tenant.id)
    return (await db.execute(stmt)).scalar_one_or_none()


async def _resolve_tenant(db, code: str | None) -> Tenant | None:
    if not code:
        return None
    return (
        await db.execute(
            select(Tenant).where(
                Tenant.code == code, Tenant.deleted_at.is_(None)
            )
        )
    ).scalar_one_or_none()


async def _record_failed_login(db, user: User) -> None:
    user.failed_login_count = (user.failed_login_count or 0) + 1
    if user.failed_login_count >= ACCOUNT_LOCK_THRESHOLD:
        user.locked_until = _now() + timedelta(minutes=ACCOUNT_LOCK_MINUTES)
    await db.commit()


def _check_account_lock(user: User) -> None:
    if user.locked_until and user.locked_until > _now():
        raise HTTPException(
            status.HTTP_423_LOCKED,
            f"account locked until {user.locked_until.isoformat()}",
        )


# ---------------------------------------------------------------------------
# POS station login (terminal-bound)
# ---------------------------------------------------------------------------

@router.post("/login", response_model=SessionRead)
@per_ip("20/minute")
async def login(request: Request, req: LoginRequest, db: DbSession) -> SessionRead:
    tenant = await _resolve_tenant(db, req.tenant_code)
    if not tenant:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "tenant not found")
    if tenant.status != "active":
        raise HTTPException(status.HTTP_403_FORBIDDEN, f"tenant status: {tenant.status}")

    store = (
        await db.execute(
            select(Store).where(
                Store.tenant_id == tenant.id,
                Store.code == req.store_code,
                Store.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not store:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")

    terminal = (
        await db.execute(
            select(Terminal).where(
                Terminal.store_id == store.id,
                Terminal.code == req.terminal_code,
                Terminal.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not terminal or not verify_secret(req.terminal_api_key, terminal.api_key_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid terminal credentials")

    user = await _get_user(db, tenant=tenant, username=req.username)
    if not user or not verify_password(req.password, user.password_hash):
        if user:
            await _record_failed_login(db, user)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid credentials")
    _check_account_lock(user)
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "user disabled")
    # Cashier accounts must belong to this store (or be tenant-wide admins).
    if user.store_id and user.store_id != store.id and user.role not in (
        "tenant_owner", "tenant_admin"
    ):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "user not assigned to this store")

    terminal.last_seen_at = _now()
    session = await _build_session(
        db, user=user, tenant=tenant, store_id=store.id, terminal_id=terminal.id,
        request=request,
    )
    await audit(
        db, None, action="login", resource_type="user", resource_id=user.id,
        request=request, extra={"store_id": store.id, "terminal_id": terminal.id},
        tenant_id=tenant.id, user_id=user.id, flush=False,
    )
    await db.commit()
    return session


# ---------------------------------------------------------------------------
# Browser / admin login (no terminal)
# ---------------------------------------------------------------------------

@router.post("/admin-login", response_model=SessionRead)
@per_ip("20/minute")
async def admin_login(
    request: Request, req: AdminLoginRequest, db: DbSession
) -> SessionRead:
    # Distinguish "no tenant header" (platform super) from "unknown tenant code".
    # If the browser sends e.g. ``demo`` but that tenant does not exist, we must
    # not fall through to the platform-only lookup — that yields a confusing 401.
    raw_tenant = (req.tenant_code or "").strip() or None
    if raw_tenant is None:
        tenant = None
    else:
        tenant = await _resolve_tenant(db, raw_tenant)
        if tenant is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "tenant not found")

    user = await _get_user(db, tenant=tenant, username=req.username)
    if not user or not verify_password(req.password, user.password_hash):
        if user:
            await _record_failed_login(db, user)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid credentials")
    _check_account_lock(user)
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "user disabled")
    if user.role not in STORE_ADMIN_ROLES:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "insufficient permissions for admin console")

    if tenant is None and user.tenant_id:
        # Browser supplied no tenant_code but the user belongs to one — load it
        # so the session response can echo the tenant code back.
        tenant = await db.get(Tenant, user.tenant_id)

    session = await _build_session(
        db, user=user, tenant=tenant, store_id=user.store_id, terminal_id=None,
        request=request,
    )
    await audit(
        db, None, action="admin_login", resource_type="user", resource_id=user.id,
        request=request, tenant_id=user.tenant_id, user_id=user.id, flush=False,
    )
    await db.commit()
    return session


# ---------------------------------------------------------------------------
# Token lifecycle
# ---------------------------------------------------------------------------

@router.post("/refresh", response_model=SessionRead)
@per_ip("60/minute")
async def refresh(request: Request, req: RefreshRequest, db: DbSession) -> SessionRead:
    from ...core.security import decode_token

    try:
        claims = decode_token(req.refresh_token)
    except ValueError as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, str(e)) from e
    if claims.get("type") != "refresh":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "not a refresh token")

    rt = await assert_refresh_token_valid(db, claims.get("jti"), claims["sub"])
    user = await db.get(User, claims["sub"])
    if not user or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "user not active")

    # Rotate: revoke current, issue a new one.
    rt.revoked_at = _now()
    tenant = await db.get(Tenant, user.tenant_id) if user.tenant_id else None
    session = await _build_session(
        db,
        user=user,
        tenant=tenant,
        store_id=claims.get("store_id"),
        terminal_id=claims.get("terminal_id"),
        request=request,
    )
    await db.commit()
    return session


@router.post("/logout", status_code=204)
async def logout(req: LogoutRequest, db: DbSession, user: CurrentUserDep) -> None:
    """Revoke the supplied refresh token (or all of the caller's tokens if
    none was provided)."""
    from sqlalchemy import update as sa_update

    from ...core.security import decode_token

    if req.refresh_token:
        try:
            claims = decode_token(req.refresh_token)
            jti = claims.get("jti")
        except ValueError:
            jti = None
        if jti:
            await db.execute(
                sa_update(RefreshToken)
                .where(RefreshToken.id == jti, RefreshToken.user_id == user.user_id)
                .values(revoked_at=_now())
            )
    else:
        await db.execute(
            sa_update(RefreshToken)
            .where(
                RefreshToken.user_id == user.user_id,
                RefreshToken.revoked_at.is_(None),
            )
            .values(revoked_at=_now())
        )
    await db.commit()


@router.post("/change-password", status_code=204)
async def change_password(
    req: ChangePasswordRequest, db: DbSession, user: CurrentUserDep
) -> None:
    db_user = await db.get(User, user.user_id)
    if not db_user or not verify_password(req.old_password, db_user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "old password mismatch")
    db_user.password_hash = hash_password(req.new_password)
    db_user.must_change_password = False
    # Revoke all other refresh tokens.
    from sqlalchemy import update as sa_update
    await db.execute(
        sa_update(RefreshToken)
        .where(
            RefreshToken.user_id == db_user.id,
            RefreshToken.revoked_at.is_(None),
        )
        .values(revoked_at=_now())
    )
    await db.commit()


# ---------------------------------------------------------------------------
# Terminal registration (admin-only) + heartbeat
# ---------------------------------------------------------------------------

@router.post("/terminals/register", response_model=TerminalRegisterResponse)
async def register_terminal(
    req: TerminalRegisterRequest, db: DbSession, scope: StoreAdminDep
) -> TerminalRegisterResponse:
    """Issue / rotate the API key for a terminal.

    Now requires a store-admin (or higher) JWT, and the terminal must belong
    to the caller's tenant — the previous unauthenticated version allowed
    anyone with a guessable store code to seize control of the cashier
    machine."""
    store = (
        await db.execute(
            select(Store).where(
                Store.tenant_id == scope.tenant_id,
                Store.code == req.store_code,
                Store.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not store:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")

    terminal = (
        await db.execute(
            select(Terminal).where(
                Terminal.store_id == store.id,
                Terminal.code == req.terminal_code,
                Terminal.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()

    api_key = generate_secret(32)
    if terminal is None:
        # Plan-limit check only fires on NEW terminals (rotating an existing
        # one's api_key shouldn't trip the quota).
        from ...core.usage import assert_can_add_terminal
        await assert_can_add_terminal(db, store.tenant_id)
        terminal = Terminal(
            tenant_id=store.tenant_id,
            store_id=store.id,
            code=req.terminal_code,
            api_key_hash=hash_secret(api_key),
        )
        db.add(terminal)
    else:
        terminal.api_key_hash = hash_secret(api_key)

    await audit(
        db, scope, action="terminal_rotate_key", resource_type="terminal",
        resource_id=terminal.code, flush=False,
    )
    await db.commit()
    await db.refresh(terminal)
    return TerminalRegisterResponse(
        terminal_id=terminal.id, store_id=store.id, api_key=api_key
    )


@router.post("/terminals/heartbeat")
async def heartbeat(
    req: HeartbeatRequest, db: DbSession, user: CurrentUserDep
) -> dict:
    terminal = await db.get(Terminal, req.terminal_id)
    if not terminal:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "terminal not found")
    if terminal.tenant_id != user.tenant_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "terminal not found")
    terminal.last_seen_at = _now()
    await db.commit()
    return {"ok": True, "server_time": _now().isoformat()}
