"""Public member OTP login for customer order web (Pro+)."""
import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel, Field
from sqlalchemy import select

from ...core.deps import DbSession
from ...core.ratelimit import per_ip
from ...models import DiningTable, EmailOtp, Member, Tenant

router = APIRouter(prefix="/public/members", tags=["public"])


class MemberOtpRequest(BaseModel):
    table_token: str
    phone: str = Field(max_length=32)


class MemberOtpVerify(BaseModel):
    table_token: str
    phone: str
    code: str = Field(min_length=4, max_length=8)


class PublicMemberRead(BaseModel):
    id: str
    name: str
    phone: str
    points: int
    level_id: str | None


async def _tenant_from_table(db: DbSession, table_token: str) -> Tenant:
    table = (
        await db.execute(
            select(DiningTable).where(DiningTable.public_token == table_token)
        )
    ).scalar_one_or_none()
    if not table:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "invalid table token")
    tenant = await db.get(Tenant, table.tenant_id)
    if not tenant or tenant.status != "active":
        raise HTTPException(status.HTTP_404_NOT_FOUND, "tenant unavailable")
    return tenant


@router.post("/otp/request")
@per_ip("10/minute")
async def request_otp(request: Request, payload: MemberOtpRequest, db: DbSession):
    tenant = await _tenant_from_table(db, payload.table_token)
    code = f"{secrets.randbelow(900000) + 100000:06d}"
    otp = EmailOtp(
        purpose="member_login",
        email=payload.phone,
        code_hash=hashlib.sha256(code.encode()).hexdigest(),
        related_id=tenant.id,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
    )
    db.add(otp)
    await db.commit()
    # Dev/demo: return code in response (production would SMS)
    return {"ok": True, "expires_in": 600, "dev_code": code}


@router.post("/otp/verify", response_model=PublicMemberRead)
@per_ip("20/minute")
async def verify_otp(request: Request, payload: MemberOtpVerify, db: DbSession):
    tenant = await _tenant_from_table(db, payload.table_token)
    otp = (
        await db.execute(
            select(EmailOtp)
            .where(
                EmailOtp.purpose == "member_login",
                EmailOtp.email == payload.phone,
                EmailOtp.related_id == tenant.id,
                EmailOtp.consumed_at.is_(None),
            )
            .order_by(EmailOtp.created_at.desc())
        )
    ).scalar_one_or_none()
    if not otp or otp.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "OTP expired")
    if otp.code_hash != hashlib.sha256(payload.code.encode()).hexdigest():
        otp.attempts = otp.attempts + 1
        await db.commit()
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid code")
    otp.consumed_at = datetime.now(timezone.utc)
    member = (
        await db.execute(
            select(Member).where(
                Member.tenant_id == tenant.id,
                Member.phone == payload.phone,
                Member.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not member:
        member = Member(
            tenant_id=tenant.id,
            phone=payload.phone,
            name=payload.phone,
            joined_at=datetime.now(timezone.utc),
        )
        db.add(member)
        await db.flush()
    await db.commit()
    await db.refresh(member)
    return PublicMemberRead(
        id=member.id,
        name=member.name,
        phone=member.phone,
        points=member.points,
        level_id=member.level_id,
    )
