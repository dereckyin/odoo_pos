"""Email OTP issue / verify helpers used by signup + recovery flows."""
from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import EmailOtp
from .config import get_settings
from .notify import send_email
from .security import hash_secret, verify_secret


def _gen_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


async def issue_email_otp(
    db: AsyncSession, *, email: str, purpose: str, related_id: str | None = None
) -> str:
    settings = get_settings()
    code = _gen_code()
    expires = datetime.now(timezone.utc) + timedelta(minutes=settings.EMAIL_OTP_TTL_MIN)
    db.add(
        EmailOtp(
            purpose=purpose,
            email=email.lower(),
            code_hash=hash_secret(code),
            related_id=related_id,
            expires_at=expires,
        )
    )
    await db.flush()
    await send_email(
        to=email,
        subject="POS 平台驗證碼",
        body=(
            f"您的驗證碼是 {code}\n"
            f"請於 {settings.EMAIL_OTP_TTL_MIN} 分鐘內輸入完成驗證。\n"
            f"若您沒有發起本次申請，請忽略此信。"
        ),
    )
    return code  # returned for tests / dev mode


async def verify_email_otp(
    db: AsyncSession, *, email: str, purpose: str, code: str, related_id: str | None = None
) -> bool:
    now = datetime.now(timezone.utc)
    stmt = (
        select(EmailOtp)
        .where(
            EmailOtp.email == email.lower(),
            EmailOtp.purpose == purpose,
            EmailOtp.consumed_at.is_(None),
        )
        .order_by(EmailOtp.created_at.desc())
    )
    if related_id is not None:
        stmt = stmt.where(EmailOtp.related_id == related_id)
    rows = (await db.execute(stmt.limit(5))).scalars().all()
    for otp in rows:
        # SQLite (used in tests) drops timezone info; coerce to UTC so the
        # comparison stays consistent across backends.
        expires = otp.expires_at
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        if expires < now:
            continue
        if otp.attempts >= 5:
            continue
        if verify_secret(code, otp.code_hash):
            otp.consumed_at = now
            await db.flush()
            return True
        otp.attempts += 1
    await db.flush()
    return False
