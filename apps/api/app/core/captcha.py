"""Pluggable CAPTCHA verifier.

Disabled when ``CAPTCHA_PROVIDER`` is empty (dev). In production set the
provider + secret and the public ``/public/applications`` endpoint will
require the corresponding token in the request body.
"""
from __future__ import annotations

import httpx

from .config import get_settings

_VERIFY_URLS = {
    "hcaptcha": "https://hcaptcha.com/siteverify",
    "turnstile": "https://challenges.cloudflare.com/turnstile/v0/siteverify",
}


async def verify_captcha(token: str | None, remote_ip: str | None = None) -> bool:
    settings = get_settings()
    if not settings.CAPTCHA_PROVIDER:
        return True  # dev mode: no captcha configured
    if not token:
        return False
    url = _VERIFY_URLS.get(settings.CAPTCHA_PROVIDER)
    if not url:
        return False
    data = {"secret": settings.CAPTCHA_SECRET, "response": token}
    if remote_ip:
        data["remoteip"] = remote_ip
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            r = await client.post(url, data=data)
            return bool(r.json().get("success"))
    except Exception:  # noqa: BLE001
        return False
