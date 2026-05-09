"""Symmetric encryption helpers for tenant-supplied secrets.

We use Fernet (AES-128-CBC + HMAC) under the hood — overkill for short
strings but proven and safe. The key comes from ``SECRETS_ENCRYPTION_KEY``
which is required in production. In development a per-process random key is
generated so the API still runs without manual setup; restarting the dev
server invalidates any stored ciphertext (acceptable trade-off).
"""
from __future__ import annotations

from cryptography.fernet import Fernet, InvalidToken

from .config import get_settings

_dev_fallback_key: bytes | None = None


def _get_fernet() -> Fernet:
    global _dev_fallback_key
    settings = get_settings()
    if settings.SECRETS_ENCRYPTION_KEY:
        return Fernet(settings.SECRETS_ENCRYPTION_KEY.encode())
    if _dev_fallback_key is None:
        _dev_fallback_key = Fernet.generate_key()
    return Fernet(_dev_fallback_key)


def encrypt(plain: str | None) -> str | None:
    if plain is None or plain == "":
        return None
    return _get_fernet().encrypt(plain.encode()).decode()


def decrypt(token: str | None) -> str | None:
    if not token:
        return None
    try:
        return _get_fernet().decrypt(token.encode()).decode()
    except InvalidToken:
        return None
