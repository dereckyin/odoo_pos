"""Notify 讀冊 my_api after a bookstore checkout is paid.

POS never sees cust_id and never writes Oracle. my_api re-fetches this
checkout with the partner key, maps it to the member, and writes ORDER_MAS.
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


async def notify_paid(checkout_id: str, total_cents: int) -> None:
    s = get_settings()
    if not s.TAAZE_SETTLE_URL or not s.TAAZE_SETTLE_SECRET:
        return
    payload = json.dumps(
        {"checkout_id": checkout_id, "status": "paid", "total_cents": int(total_cents)},
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "X-Taaze-Signature": "sha256=" + sign_body(s.TAAZE_SETTLE_SECRET, payload),
        "Accept": "application/json",
    }
    try:
        async with httpx.AsyncClient(timeout=4.0, follow_redirects=False) as client:
            resp = await client.post(s.TAAZE_SETTLE_URL, content=payload, headers=headers)
        if resp.status_code >= 300:
            logger.warning(
                "taaze settle rejected checkout=%s status=%s", checkout_id, resp.status_code
            )
    except httpx.HTTPError as exc:
        logger.warning("taaze settle unreachable checkout=%s (%s)", checkout_id, type(exc).__name__)
