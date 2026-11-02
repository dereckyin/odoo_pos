"""Notify 讀冊 my_api after a bookstore checkout is paid or refunded.

POS never sees cust_id and never writes Oracle. my_api re-fetches this
checkout with the partner key, maps it to the member, and writes ORDER_MAS
(or reverses it on refund with F0501).
"""
from __future__ import annotations

import hashlib
import hmac
import json
import logging

import httpx

from ..core.config import get_settings

logger = logging.getLogger(__name__)


def sign_body(secret: str, body: bytes) -> str:
    return hmac.new(secret.encode("utf-8"), body, hashlib.sha256).hexdigest()


def _refund_url(settle_url: str) -> str:
    base = settle_url.rstrip("/")
    if base.endswith("/paid"):
        return base[: -len("/paid")] + "/refunded"
    return base + "/refunded"


async def _post_signed(url: str, secret: str, payload: dict) -> bool:
    body = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "X-Taaze-Signature": "sha256=" + sign_body(secret, body),
        "Accept": "application/json",
    }
    try:
        async with httpx.AsyncClient(timeout=8.0, follow_redirects=False) as client:
            resp = await client.post(url, content=body, headers=headers)
        if resp.status_code >= 300:
            logger.warning(
                "taaze notify rejected url=%s checkout=%s status=%s",
                url,
                payload.get("checkout_id"),
                resp.status_code,
            )
            return False
        return True
    except httpx.HTTPError as exc:
        logger.warning(
            "taaze notify unreachable url=%s checkout=%s (%s)",
            url,
            payload.get("checkout_id"),
            type(exc).__name__,
        )
        return False


async def notify_paid(checkout_id: str, total_cents: int) -> None:
    s = get_settings()
    if not s.TAAZE_SETTLE_URL or not s.TAAZE_SETTLE_SECRET:
        return
    await _post_signed(
        s.TAAZE_SETTLE_URL,
        s.TAAZE_SETTLE_SECRET,
        {"checkout_id": checkout_id, "status": "paid", "total_cents": int(total_cents)},
    )


async def notify_refunded(checkout_id: str, total_cents: int, reason: str = "") -> bool:
    """Best-effort: POS stock is already restored; Oracle/F0501 run on my_api."""
    s = get_settings()
    if not s.TAAZE_SETTLE_URL or not s.TAAZE_SETTLE_SECRET:
        return False
    return await _post_signed(
        _refund_url(s.TAAZE_SETTLE_URL),
        s.TAAZE_SETTLE_SECRET,
        {
            "checkout_id": checkout_id,
            "status": "refunded",
            "total_cents": int(total_cents),
            "reason": (reason or "")[:500],
        },
    )
