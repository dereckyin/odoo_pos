"""Email / SMS notification stubs.

In production wire this to a real provider (SES, SendGrid, Mailgun, AWS
SNS, etc.). The stub mode logs the message at INFO so developers can copy
the OTP from the console.
"""
from __future__ import annotations

import logging
import smtplib
from email.message import EmailMessage

from .config import get_settings

logger = logging.getLogger(__name__)


async def send_email(to: str, subject: str, body: str) -> None:
    settings = get_settings()
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
