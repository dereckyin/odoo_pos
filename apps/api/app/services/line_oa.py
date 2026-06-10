"""LINE Official Account integration helpers.

Per-tenant LINE channel config is stored in ``Tenant.settings["line"]`` and is
controlled by the ``line`` module flag. The access token is used for push
notifications; the channel secret is used to verify inbound webhooks.
"""
from __future__ import annotations

import base64
import hashlib
import hmac

import httpx

_KEYS = ("channel_id", "channel_secret", "access_token", "liff_id")


def read_line_settings(settings: dict | None) -> dict[str, str]:
    raw = (settings or {}).get("line") or {}
    return {k: str(raw.get(k) or "") for k in _KEYS}


def public_line_settings(settings: dict | None) -> dict[str, str]:
    """LINE config safe to expose publicly (no secrets)."""
    cfg = read_line_settings(settings)
    return {"liff_id": cfg["liff_id"], "channel_id": cfg["channel_id"]}


def apply_line_patch(settings: dict | None, patch: dict[str, str | None]) -> dict:
    merged = dict(settings or {})
    current = read_line_settings(merged)
    for k in _KEYS:
        if patch.get(k) is not None:
            current[k] = str(patch[k] or "")
    merged["line"] = current
    return merged


def verify_webhook_signature(channel_secret: str, body: bytes, signature: str) -> bool:
    if not channel_secret or not signature:
        return False
    digest = hmac.new(channel_secret.encode("utf-8"), body, hashlib.sha256).digest()
    expected = base64.b64encode(digest).decode("utf-8")
    return hmac.compare_digest(expected, signature)


async def fetch_line_profile(access_token: str) -> dict | None:
    """Fetch the LINE profile (userId/displayName) for a user-scoped LIFF
    access token. Returns None when the token is invalid/expired."""
    if not access_token:
        return None
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                "https://api.line.me/v2/profile",
                headers={"Authorization": f"Bearer {access_token}"},
            )
        if resp.status_code != 200:
            return None
        return resp.json()
    except Exception:  # noqa: BLE001
        return None
