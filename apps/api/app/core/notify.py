"""Email / SMS notification stubs.

Delivery priority:
1) AWS SES (SES_ACCESS_KEY/SES_SECRET_KEY/SES_REGION/SENDER)
2) Resend (RESEND_API_KEY)
3) SMTP (SMTP_HOST)
4) Stub log output (dev fallback)
"""
from __future__ import annotations

import logging
import smtplib
from asyncio import to_thread
from email.message import EmailMessage

import httpx

from .config import get_settings

logger = logging.getLogger(__name__)

_RESEND_API_URL = "https://api.resend.com/emails"


async def send_email(to: str, subject: str, body: str) -> None:
    settings = get_settings()
    if (
        settings.SES_ACCESS_KEY
        and settings.SES_SECRET_KEY
        and settings.SES_REGION
        and settings.SENDER
    ):
        await _send_via_ses(to=to, subject=subject, body=body)
        return
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


async def send_sms(to: str, body: str) -> bool:
    """Send an SMS. Returns True when handed to a real provider, False when it
    fell back to the dev stub (so callers can echo a dev code instead)."""
    settings = get_settings()
    if (
        settings.SMS_PROVIDER == "twilio"
        and settings.TWILIO_ACCOUNT_SID
        and settings.TWILIO_AUTH_TOKEN
        and settings.TWILIO_FROM_NUMBER
    ):
        url = (
            f"https://api.twilio.com/2010-04-01/Accounts/"
            f"{settings.TWILIO_ACCOUNT_SID}/Messages.json"
        )
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.post(
                    url,
                    auth=(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN),
                    data={"From": settings.TWILIO_FROM_NUMBER, "To": to, "Body": body},
                )
            if resp.status_code >= 400:
                logger.error("twilio sms failed to=%s status=%s", to, resp.status_code)
                return False
            return True
        except Exception:  # noqa: BLE001
            logger.exception("failed to send sms to=%s", to)
            return False
    logger.info("[stub-sms] to=%s body=%s", to, body)
    return False


async def send_line_push(access_token: str, to: str, text: str) -> bool:
    """Push a text message to a LINE user via the Messaging API.

    Returns True on success. Falls back to a stub log (and returns False) when
    no ``access_token`` is configured, mirroring the SMS dev fallback.
    """
    if not access_token or not to:
        logger.info("[stub-line] to=%s text=%s", to, text)
        return False
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(
                "https://api.line.me/v2/bot/message/push",
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
                json={"to": to, "messages": [{"type": "text", "text": text}]},
            )
        if resp.status_code >= 400:
            logger.error(
                "line push failed to=%s status=%s body=%s",
                to,
                resp.status_code,
                resp.text,
            )
            return False
        return True
    except Exception:  # noqa: BLE001
        logger.exception("failed to push line message to=%s", to)
        return False


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


async def _send_via_ses(*, to: str, subject: str, body: str) -> None:
    settings = get_settings()
    try:
        import boto3
    except Exception:  # noqa: BLE001
        logger.exception("boto3 not installed; cannot send email via SES")
        return

    ses_client = boto3.client(
        "ses",
        region_name=settings.SES_REGION,
        aws_access_key_id=settings.SES_ACCESS_KEY,
        aws_secret_access_key=settings.SES_SECRET_KEY,
    )
    try:
        await to_thread(
            ses_client.send_email,
            Source=settings.SENDER,
            Destination={"ToAddresses": [to]},
            Message={
                "Subject": {"Data": subject, "Charset": "UTF-8"},
                "Body": {"Text": {"Data": body, "Charset": "UTF-8"}},
            },
        )
        logger.info("email sent via SES to=%s subject=%s", to, subject)
    except Exception:  # noqa: BLE001
        logger.exception("failed to send email via SES to=%s", to)
