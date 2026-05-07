from datetime import datetime, timedelta, timezone
from typing import Any

from jose import JWTError, jwt
from passlib.context import CryptContext

from .config import get_settings

_pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(p: str) -> str:
    return _pwd.hash(p)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd.verify(plain, hashed)


def _create_token(sub: str, ttl: timedelta, claims: dict[str, Any] | None = None) -> str:
    s = get_settings()
    now = datetime.now(timezone.utc)
    payload: dict[str, Any] = {
        "sub": sub,
        "iat": int(now.timestamp()),
        "exp": int((now + ttl).timestamp()),
    }
    if claims:
        payload.update(claims)
    return jwt.encode(payload, s.JWT_SECRET, algorithm=s.JWT_ALGORITHM)


def create_access_token(sub: str, claims: dict[str, Any] | None = None) -> str:
    s = get_settings()
    return _create_token(sub, timedelta(minutes=s.JWT_ACCESS_TTL_MIN), claims)


def create_refresh_token(sub: str, claims: dict[str, Any] | None = None) -> str:
    s = get_settings()
    return _create_token(sub, timedelta(days=s.JWT_REFRESH_TTL_DAYS), {**(claims or {}), "type": "refresh"})


def decode_token(token: str) -> dict[str, Any]:
    s = get_settings()
    try:
        return jwt.decode(token, s.JWT_SECRET, algorithms=[s.JWT_ALGORITHM])
    except JWTError as e:
        raise ValueError(f"invalid token: {e}") from e
