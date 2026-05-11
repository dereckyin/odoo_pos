"""Email / SMS notification stubs.

Resend (RESEND_API_KEY) or SMTP (SMTP_HOST) send real mail; otherwise the
stub logs at INFO so developers can copy the OTP from the console.
"""
from __future__ import annotations

import logging
import smtplib
from email.message import EmailMessage

import httpx

from .config import get_settings

logger = logging.getLogger(__name__)

_RESEND_API_URL = "https://api.resend.com/emails"


async def send_email(to: str, subject: str, body: str) -> None:
    settings = get_settings()
    if settings.RESEND_API_KEY:
        await _send_via_resend(to=to, subject=subject, body=body)
        return
    if not settings.SMTP_HOST:
        logger.info("[stub-email] to=%s subject=%s body=%s", to, subject, body)
        return
    msg = EmailMessage()
    msg["From"] = settings.SMTP_FROM
    msg["To"] = to
    msg["Subject"] = subject
    msg.set_content(body)
    try:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as smtp:
            smtp.starttls()
            if settings.SMTP_USER:
                smtp.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            smtp.send_message(msg)
    except Exception:  # noqa: BLE001
        logger.exception("failed to send email to=%s", to)


async def _send_via_resend(*, to: str, subject: str, body: str) -> None:
    settings = get_settings()
    payload = {
        "from": settings.SMTP_FROM,
        "to": [to],
        "subject": subject,
        "text": body,
    }
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(
                _RESEND_API_URL,
                headers={
                    "Authorization": f"Bearer {settings.RESEND_API_KEY}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
        if resp.status_code >= 400:
            logger.error(
                "resend failed to=%s status=%s body=%s",
                to,
                resp.status_code,
                resp.text,
            )
    except Exception:  # noqa: BLE001
        logger.exception("failed to send email via resend to=%s", to)
