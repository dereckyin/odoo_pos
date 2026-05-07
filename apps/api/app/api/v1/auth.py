import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from ...core.config import get_settings
from ...core.deps import CurrentUserDep, DbSession
from ...core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from ...models import Store, Terminal, User
from ...schemas.auth import (
    AdminLoginRequest,
    HeartbeatRequest,
    LoginRequest,
    RefreshRequest,
    SessionRead,
    TerminalRegisterRequest,
    TerminalRegisterResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])


def _build_session(*, user: User, store_id: str, terminal_id: str) -> SessionRead:
    settings = get_settings()
    claims = {
        "username": user.username,
        "role": user.role,
        "store_id": store_id,
        "terminal_id": terminal_id,
    }
    access = create_access_token(user.id, claims)
    refresh = create_refresh_token(user.id, claims)
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_ACCESS_TTL_MIN)
    return SessionRead(
        user_id=user.id,
        username=user.username,
        display_name=user.display_name,
        role=user.role,
        store_id=store_id,
        terminal_id=terminal_id,
        access_token=access,
        refresh_token=refresh,
        expires_at=expires_at.timestamp(),
    )


@router.post("/login", response_model=SessionRead)
async def login(req: LoginRequest, db: DbSession) -> SessionRead:
    user = (
        await db.execute(select(User).where(User.username == req.username, User.deleted_at.is_(None)))
    ).scalar_one_or_none()
    if not user or not verify_password(req.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid credentials")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "user disabled")

    terminal = (
        await db.execute(select(Terminal).where(Terminal.code == req.terminal_code))
    ).scalar_one_or_none()
    if not terminal:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "terminal not registered")

    terminal.last_seen_at = datetime.now(timezone.utc)
    await db.commit()

    return _build_session(user=user, store_id=terminal.store_id, terminal_id=terminal.id)


@router.post("/refresh", response_model=SessionRead)
async def refresh(req: RefreshRequest, db: DbSession) -> SessionRead:
    try:
        claims = decode_token(req.refresh_token)
    except ValueError as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, str(e)) from e
    if claims.get("type") != "refresh":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "not a refresh token")
    user = await db.get(User, claims["sub"])
    if not user or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "user not active")
    return _build_session(
        user=user,
        store_id=claims.get("store_id", ""),
        terminal_id=claims.get("terminal_id", ""),
    )


@router.post("/admin-login", response_model=SessionRead)
async def admin_login(req: AdminLoginRequest, db: DbSession) -> SessionRead:
    """Login for admin panel — no terminal required."""
    user = (
        await db.execute(select(User).where(User.username == req.username, User.deleted_at.is_(None)))
    ).scalar_one_or_none()
    if not user or not verify_password(req.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid credentials")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "user disabled")
    if user.role not in ("admin", "manager"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "insufficient permissions")

    return _build_session(user=user, store_id=user.store_id or "", terminal_id="")


@router.post("/terminals/register", response_model=TerminalRegisterResponse)
async def register_terminal(req: TerminalRegisterRequest, db: DbSession) -> TerminalRegisterResponse:
    store = (await db.execute(select(Store).where(Store.code == req.store_code))).scalar_one_or_none()
    if not store:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    terminal = (
        await db.execute(
            select(Terminal).where(Terminal.code == req.terminal_code, Terminal.store_id == store.id)
        )
    ).scalar_one_or_none()
    api_key = secrets.token_urlsafe(32)
    if not terminal:
        terminal = Terminal(
            store_id=store.id,
            code=req.terminal_code,
            api_key_hash=hash_password(api_key),
        )
        db.add(terminal)
    else:
        terminal.api_key_hash = hash_password(api_key)
    await db.commit()
    await db.refresh(terminal)
    return TerminalRegisterResponse(terminal_id=terminal.id, store_id=store.id, api_key=api_key)


@router.post("/terminals/heartbeat")
async def heartbeat(req: HeartbeatRequest, db: DbSession, _: CurrentUserDep) -> dict:
    terminal = await db.get(Terminal, req.terminal_id)
    if not terminal:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "terminal not found")
    terminal.last_seen_at = datetime.now(timezone.utc)
    await db.commit()
    return {"ok": True, "server_time": datetime.now(timezone.utc).isoformat()}
