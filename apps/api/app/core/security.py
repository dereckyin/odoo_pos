import secrets
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import uuid4

from jose import JWTError, jwt
from passlib.context import CryptContext

from .config import get_settings

_pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(p: str) -> str:
    return _pwd.hash(p)


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return _pwd.verify(plain, hashed)
    except Exception:  # noqa: BLE001 - malformed hash should not crash
        return False


def generate_secret(nbytes: int = 32) -> str:
    """URL-safe high-entropy token used for terminal API keys, OTPs, etc."""
    return secrets.token_urlsafe(nbytes)


def hash_secret(plain: str) -> str:
    """Hash arbitrary secrets (terminal api_key, OTP code) with bcrypt."""
    return _pwd.hash(plain)


def verify_secret(plain: str, hashed: str) -> bool:
    return verify_password(plain, hashed)


def _create_token(
    sub: str, ttl: timedelta, claims: dict[str, Any] | None = None, jti: str | None = None
) -> tuple[str, str, datetime]:
    """Returns (token, jti, expires_at)."""
    s = get_settings()
    now = datetime.now(timezone.utc)
    expires = now + ttl
    actual_jti = jti or uuid4().hex
    payload: dict[str, Any] = {
        "sub": sub,
        "iat": int(now.timestamp()),
        "exp": int(expires.timestamp()),
        "jti": actual_jti,
    }
    if claims:
        payload.update(claims)
    return jwt.encode(payload, s.JWT_SECRET, algorithm=s.JWT_ALGORITHM), actual_jti, expires


def create_access_token(sub: str, claims: dict[str, Any] | None = None) -> tuple[str, datetime]:
    s = get_settings()
    token, _, expires = _create_token(sub, timedelta(minutes=s.JWT_ACCESS_TTL_MIN), claims)
    return token, expires


def create_token_with_ttl(
    sub: str, ttl: timedelta, claims: dict[str, Any] | None = None
) -> tuple[str, datetime]:
    """Issue a signed token with a caller-supplied lifetime.

    Used for long-lived public identities (e.g. marketplace member sessions)
    that are not tied to the staff access/refresh token lifecycle.
    """
    token, _, expires = _create_token(sub, ttl, claims)
    return token, expires


def create_refresh_token(
    sub: str, claims: dict[str, Any] | None = None
) -> tuple[str, str, datetime]:
    """Returns (token, jti, expires_at) so the caller can persist the JTI in
    the ``refresh_tokens`` table for later revocation."""
    s = get_settings()
    payload = {**(claims or {}), "type": "refresh"}
    return _create_token(sub, timedelta(days=s.JWT_REFRESH_TTL_DAYS), payload)


def decode_token(token: str) -> dict[str, Any]:
    s = get_settings()
    try:
        return jwt.decode(token, s.JWT_SECRET, algorithms=[s.JWT_ALGORITHM])
    except JWTError as e:
        raise ValueError(f"invalid token: {e}") from e
