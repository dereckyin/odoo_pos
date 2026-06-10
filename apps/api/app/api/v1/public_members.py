"""Public member OTP login + member center for customer order / marketplace web.

Two identity modes:
- ``table_token`` (in-store QR ordering): tenant-local ``Member`` only.
- ``store_slug`` (marketplace): unified cross-store ``AllianceMember`` in the
  platform marketplace alliance, linked to each store's local ``Member``.
"""
import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from pydantic import BaseModel, Field
from sqlalchemy import select

from ...core.deps import DbSession
from ...core.notify import send_sms
from ...core.ratelimit import per_ip
from ...models import (
    AllianceMember,
    DiningTable,
    EmailOtp,
    MarketplaceListing,
    Member,
    Tenant,
)
from ...services.alliance_service import resolve_alliance_member
from ...services.marketplace_member import (
    MarketplaceMemberContext,
    decode_member_token,
    ensure_tenant_in_marketplace_alliance,
    get_or_create_marketplace_alliance,
    issue_member_token,
    resolve_marketplace_member,
)

router = APIRouter(prefix="/public/members", tags=["public"])


class MemberOtpRequest(BaseModel):
    table_token: str | None = None
    store_slug: str | None = None
    phone: str = Field(max_length=32)


class MemberOtpVerify(BaseModel):
    table_token: str | None = None
    store_slug: str | None = None
    phone: str
    code: str = Field(min_length=4, max_length=8)
    name: str | None = Field(default=None, max_length=64)


class PublicMemberRead(BaseModel):
    id: str
    name: str
    phone: str
    points: int
    level_id: str | None = None
    # Marketplace unified-identity fields (None for in-store table login).
    token: str | None = None
    alliance_member_id: str | None = None
    cross_store_points: int | None = None


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


async def _tenant_from_slug(db: DbSession, store_slug: str) -> Tenant:
    listing = (
        await db.execute(
            select(MarketplaceListing).where(
                MarketplaceListing.slug == store_slug,
                MarketplaceListing.status == "approved",
            )
        )
    ).scalar_one_or_none()
    if not listing:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "invalid store slug")
    tenant = await db.get(Tenant, listing.tenant_id)
    if not tenant or tenant.status != "active":
        raise HTTPException(status.HTTP_404_NOT_FOUND, "tenant unavailable")
    return tenant


async def _resolve_tenant(db: DbSession, table_token: str | None, store_slug: str | None) -> Tenant:
    if table_token:
        return await _tenant_from_table(db, table_token)
    if store_slug:
        return await _tenant_from_slug(db, store_slug)
    raise HTTPException(status.HTTP_400_BAD_REQUEST, "table_token or store_slug required")


async def _otp_scope_id(db: DbSession, table_token: str | None, store_slug: str | None) -> str:
    """The OTP's ``related_id`` scope. Store/table -> tenant id; otherwise the
    platform marketplace alliance id (tenant-agnostic member-center login)."""
    if table_token or store_slug:
        tenant = await _resolve_tenant(db, table_token, store_slug)
        return tenant.id
    net = await get_or_create_marketplace_alliance(db)
    return net.id


@router.post("/otp/request")
@per_ip("10/minute")
async def request_otp(request: Request, payload: MemberOtpRequest, db: DbSession):
    scope_id = await _otp_scope_id(db, payload.table_token, payload.store_slug)
    code = f"{secrets.randbelow(900000) + 100000:06d}"
    otp = EmailOtp(
        purpose="member_login",
        email=payload.phone,
        code_hash=hashlib.sha256(code.encode()).hexdigest(),
        related_id=scope_id,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=10),
    )
    db.add(otp)
    await db.commit()
    # Try to dispatch via SMS provider; falls back to dev echo when unconfigured.
    delivered = await send_sms(payload.phone, f"您的驗證碼為 {code}（10 分鐘內有效）")
    resp = {"ok": True, "expires_in": 600}
    if not delivered:
        resp["dev_code"] = code
    return resp


@router.post("/otp/verify", response_model=PublicMemberRead)
@per_ip("20/minute")
async def verify_otp(request: Request, payload: MemberOtpVerify, db: DbSession):
    tenant = None
    if payload.table_token or payload.store_slug:
        tenant = await _resolve_tenant(db, payload.table_token, payload.store_slug)
    scope_id = tenant.id if tenant else (await get_or_create_marketplace_alliance(db)).id
    otp = (
        await db.execute(
            select(EmailOtp)
            .where(
                EmailOtp.purpose == "member_login",
                EmailOtp.email == payload.phone,
                EmailOtp.related_id == scope_id,
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

    # Marketplace login (store-scoped) -> unified identity + tenant link.
    if payload.store_slug and tenant is not None:
        net = await get_or_create_marketplace_alliance(db)
        await ensure_tenant_in_marketplace_alliance(db, tenant.id)
        am, member = await resolve_alliance_member(
            db,
            alliance_id=net.id,
            tenant_id=tenant.id,
            phone=payload.phone,
            name=payload.name,
        )
        if payload.name and (not member.name or member.name == member.phone):
            member.name = payload.name[:64]
        token, _ = issue_member_token(am)
        await db.commit()
        await db.refresh(am)
        await db.refresh(member)
        return PublicMemberRead(
            id=member.id,
            name=am.name or member.name,
            phone=am.phone,
            points=am.points,
            level_id=member.level_id,
            token=token,
            alliance_member_id=am.id,
            cross_store_points=am.points,
        )

    # Marketplace-global login (member center, no store) -> alliance identity only.
    if tenant is None:
        am = await resolve_marketplace_member(db, phone=payload.phone, name=payload.name)
        token, _ = issue_member_token(am)
        await db.commit()
        await db.refresh(am)
        return PublicMemberRead(
            id=am.id,
            name=am.name or am.phone,
            phone=am.phone,
            points=am.points,
            level_id=None,
            token=token,
            alliance_member_id=am.id,
            cross_store_points=am.points,
        )

    # In-store table login -> tenant-local member (legacy behavior).
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
            name=payload.name or payload.phone,
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


# ---------------------------------------------------------------------------
# Marketplace member dependency
# ---------------------------------------------------------------------------

async def current_marketplace_member(
    authorization: Annotated[str | None, Header()] = None,
) -> MarketplaceMemberContext:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing member token")
    token = authorization.split(" ", 1)[1]
    return decode_member_token(token)


async def optional_marketplace_member(
    authorization: Annotated[str | None, Header()] = None,
) -> MarketplaceMemberContext | None:
    if not authorization or not authorization.lower().startswith("bearer "):
        return None
    token = authorization.split(" ", 1)[1]
    try:
        return decode_member_token(token)
    except HTTPException:
        return None


MarketplaceMemberDep = Annotated[MarketplaceMemberContext, Depends(current_marketplace_member)]
OptionalMarketplaceMemberDep = Annotated[
    MarketplaceMemberContext | None, Depends(optional_marketplace_member)
]


async def load_alliance_member(db: DbSession, ctx: MarketplaceMemberContext) -> AllianceMember:
    am = await db.get(AllianceMember, ctx.alliance_member_id)
    if not am or am.deleted_at is not None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "member not found")
    return am
