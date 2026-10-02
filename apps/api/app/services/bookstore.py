"""Physical bookstore stores: store settings, signed tokens and the app
channel identity used to attribute TAAZE app sales to a regular ``Order``."""
from __future__ import annotations

import base64
import hashlib
import hmac
import json
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import get_settings
from ..core.security import generate_secret, hash_password, hash_secret
from ..models import Store, Terminal, User

STORE_KIND_RESTAURANT = "restaurant"
STORE_KIND_BOOKSTORE = "bookstore"

APP_TERMINAL_CODE = "TAAZE-APP"
DOOR_QR_PREFIX = "TAAZEBK1:"


CASH_PRICE_PCT_MIN = 50


def _cash_price_pct(value) -> int:
    try:
        pct = int(value)
    except (TypeError, ValueError):
        return 100
    return min(100, max(CASH_PRICE_PCT_MIN, pct))


def read_bookstore_settings(store: Store) -> dict:
    raw = store.bookstore_json or {}
    return {
        "is_open": bool(raw.get("is_open", True)),
        "cash_enabled": bool(raw.get("cash_enabled", True)),
        # Percentage of the list total paid in cash: 95 means 95 折 (5% off).
        "cash_price_pct": _cash_price_pct(raw.get("cash_price_pct", 100)),
        "online_payment_enabled": bool(raw.get("online_payment_enabled", False)),
        "qr_version": int(raw.get("qr_version", 0)),
        "app_terminal_id": raw.get("app_terminal_id"),
        "app_user_id": raw.get("app_user_id"),
    }


def write_bookstore_settings(store: Store, patch: dict) -> None:
    current = read_bookstore_settings(store)
    current.update({k: v for k, v in patch.items() if v is not None})
    current["cash_price_pct"] = _cash_price_pct(current.get("cash_price_pct"))
    store.bookstore_json = current


def is_bookstore(store: Store | None) -> bool:
    return bool(store) and store.deleted_at is None and store.store_kind == STORE_KIND_BOOKSTORE


async def ensure_app_identity(db: AsyncSession, store: Store) -> tuple[str, str]:
    """Return (terminal_id, user_id) that app orders for this store are booked
    under. Both are created unusable for login: the terminal key and user
    password are random and discarded, and the user is inactive."""
    cfg = read_bookstore_settings(store)
    terminal = await db.get(Terminal, cfg["app_terminal_id"]) if cfg["app_terminal_id"] else None
    if terminal is None or terminal.store_id != store.id or terminal.deleted_at is not None:
        terminal = (
            await db.execute(
                select(Terminal).where(
                    Terminal.store_id == store.id,
                    Terminal.code == APP_TERMINAL_CODE,
                    Terminal.deleted_at.is_(None),
                )
            )
        ).scalar_one_or_none()
    if terminal is None:
        terminal = Terminal(
            tenant_id=store.tenant_id,
            store_id=store.id,
            code=APP_TERMINAL_CODE,
            api_key_hash=hash_secret(generate_secret(32)),
        )
        db.add(terminal)
        await db.flush()

    user = await db.get(User, cfg["app_user_id"]) if cfg["app_user_id"] else None
    if user is None or user.tenant_id != store.tenant_id:
        username = f"taaze-app-{store.code}".lower()[:64]
        user = (
            await db.execute(
                select(User).where(User.tenant_id == store.tenant_id, User.username == username)
            )
        ).scalar_one_or_none()
        if user is None:
            user = User(
                tenant_id=store.tenant_id,
                username=username,
                password_hash=hash_password(generate_secret(32)),
                display_name="讀冊 App",
                role="cashier",
                store_id=store.id,
                is_active=False,
            )
            db.add(user)
            await db.flush()

    write_bookstore_settings(store, {"app_terminal_id": terminal.id, "app_user_id": user.id})
    return terminal.id, user.id


# --- signed tokens --------------------------------------------------------


def _b64e(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def _b64d(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def _signing_key() -> bytes:
    secret = get_settings().BOOKSTORE_SIGNING_SECRET
    if not secret:
        # Dev fallback so local runs work; production refuses to start
        # without a real secret (see validate_settings_or_raise).
        secret = "dev-bookstore-signing-secret"
    return hashlib.sha256(("bookstore:" + secret).encode("utf-8")).digest()


def sign_token(kind: str, payload: dict, ttl: timedelta) -> tuple[str, datetime]:
    expires = datetime.now(timezone.utc) + ttl
    return sign_token_until(kind, payload, expires), expires


def sign_token_until(kind: str, payload: dict, expires: datetime) -> str:
    body = {"t": kind, "exp": int(expires.timestamp()), **payload}
    raw = _b64e(json.dumps(body, separators=(",", ":"), sort_keys=True).encode("utf-8"))
    sig = _b64e(hmac.new(_signing_key(), raw.encode("ascii"), hashlib.sha256).digest())
    return f"{raw}.{sig}"


def verify_token(kind: str, token: str, *, check_exp: bool = True) -> dict | None:
    if not token or token.count(".") != 1 or len(token) > 1024:
        return None
    raw, sig = token.split(".", 1)
    expected = _b64e(hmac.new(_signing_key(), raw.encode("ascii"), hashlib.sha256).digest())
    if not hmac.compare_digest(sig, expected):
        return None
    try:
        body = json.loads(_b64d(raw))
    except (ValueError, json.JSONDecodeError):
        return None
    if not isinstance(body, dict) or body.get("t") != kind:
        return None
    if check_exp and int(body.get("exp", 0)) < int(datetime.now(timezone.utc).timestamp()):
        return None
    return body


def customer_fingerprint(customer_ref: str) -> str:
    return hashlib.sha256(customer_ref.encode("utf-8")).hexdigest()[:24]


def issue_door_qr(store: Store) -> tuple[str, datetime]:
    cfg = read_bookstore_settings(store)
    token, expires = sign_token(
        "door",
        {"s": store.id, "v": cfg["qr_version"]},
        timedelta(days=get_settings().BOOKSTORE_DOOR_QR_DAYS),
    )
    return DOOR_QR_PREFIX + token, expires


def parse_door_qr(content: str) -> dict | None:
    content = (content or "").strip()
    if not content.startswith(DOOR_QR_PREFIX):
        return None
    return verify_token("door", content[len(DOOR_QR_PREFIX):])


def issue_presence_token(store_id: str, customer_ref: str) -> tuple[str, datetime]:
    return sign_token(
        "presence",
        {"s": store_id, "c": customer_fingerprint(customer_ref)},
        timedelta(hours=get_settings().BOOKSTORE_PRESENCE_HOURS),
    )


def assert_presence(token: str | None, store_id: str, customer_ref: str) -> None:
    body = verify_token("presence", token or "")
    if not body or body.get("s") != store_id or body.get("c") != customer_fingerprint(customer_ref):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            {"code": "presence_required", "message": "請先掃描門口 QR Code 再結帳"},
        )
