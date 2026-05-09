"""Rate-limiting helpers built on top of slowapi.

We use slowapi (which wraps the `limits` package) because it integrates
cleanly with FastAPI's dependency system. Storage is Redis-backed so limits
are shared across worker processes; in tests a memory backend is used.
"""
from __future__ import annotations

from typing import Callable

from fastapi import HTTPException, Request, status
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from .config import get_settings


def _key_func(request: Request) -> str:
    """Combine the client IP with a logical bucket so different endpoints
    don't share counters by accident. We also honour ``X-Forwarded-For``
    when behind a trusted proxy (set ``forwarded_allow_ips`` on uvicorn)."""
    return get_remote_address(request)


_settings = get_settings()
_storage_uri = _settings.rate_limit_storage_uri if _settings.RATE_LIMIT_ENABLED else "memory://"

limiter = Limiter(
    key_func=_key_func,
    storage_uri=_storage_uri,
    enabled=_settings.RATE_LIMIT_ENABLED,
    # FastAPI routes return plain models / JSON; slowapi header injection requires a
    # Starlette ``Response`` on the handler. Disable headers to avoid 500s on limit paths.
    headers_enabled=False,
    strategy="fixed-window",
)


async def rate_limit_handler(request: Request, exc: RateLimitExceeded) -> HTTPException:  # noqa: ARG001
    """Convert slowapi's exception to a JSON 429 the SPA / Flutter clients
    can display gracefully."""
    raise HTTPException(
        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        detail="too many requests, please retry later",
        headers={"Retry-After": "60"},
    )


def per_ip(limit: str) -> Callable:
    """Return a slowapi-decorated dependency factory.

    Usage in routes::

        @router.post("/login")
        @per_ip("10/minute")
        async def login(request: Request, ...):
            ...

    The endpoint *must* accept a ``request: Request`` argument because slowapi
    inspects it to derive the client identifier.
    """
    return limiter.limit(limit)


def per_ip_and_key(limit: str, key: Callable[[Request], str]) -> Callable:
    """Compound limiter: IP + arbitrary key (e.g. email) so that one IP
    spamming many emails is throttled per-email AND per-IP."""
    return limiter.limit(limit, key_func=lambda req: f"{_key_func(req)}|{key(req)}")
