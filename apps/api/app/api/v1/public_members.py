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
from ...core.security import hash_password, verify_password
from ...models import (
    AllianceMember,
    AlliancePointLedger,
    DiningTable,
    EmailOtp,
    MarketplaceListing,
    Member,
    MemberReferral,
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

# Reward granted to both referrer and referee when a referral code is applied.
REFERRAL_REWARD_POINTS = 50
MIN_PASSWORD_LEN = 8


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
    email: str | None = None
    birthday: str | None = None


class MemberRegister(BaseModel):
    phone: str = Field(min_length=4, max_length=32)
    password: str = Field(min_length=MIN_PASSWORD_LEN, max_length=128)
    name: str = Field(min_length=1, max_length=64)
    email: str | None = Field(default=None, max_length=128)
    birthday: str | None = Field(default=None, max_length=10)
    referral_code: str | None = Field(default=None, max_length=32)
    terms_accepted: bool = False


class MemberPasswordLogin(BaseModel):
    phone: str = Field(min_length=4, max_length=32)
    password: str = Field(min_length=1, max_length=128)


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
# Password-based registration / login (unified marketplace member)
# ---------------------------------------------------------------------------

def _member_read(am: AllianceMember, token: str) -> PublicMemberRead:
    return PublicMemberRead(
        id=am.id,
        name=am.name or am.phone,
        phone=am.phone,
        points=am.points,
        level_id=None,
        token=token,
        alliance_member_id=am.id,
        cross_store_points=am.points,
        email=am.email,
        birthday=am.birthday,
    )


async def _apply_referral_at_signup(db: DbSession, alliance_id: str, am: AllianceMember, code: str) -> None:
    """Best-effort referral reward on registration. Invalid codes are ignored
    so a typo never blocks signup (members can re-apply later in the center)."""
    code = code.strip().upper()
    if not code:
        return
    referrer = (
        await db.execute(
            select(AllianceMember).where(
                AllianceMember.referral_code == code,
                AllianceMember.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not referrer or referrer.id == am.id:
        return
    referrer.points += REFERRAL_REWARD_POINTS
    am.points += REFERRAL_REWARD_POINTS
    db.add(
        MemberReferral(
            alliance_id=alliance_id,
            referrer_member_id=referrer.id,
            referee_member_id=am.id,
            code=code,
            reward_points=REFERRAL_REWARD_POINTS,
            status="rewarded",
        )
    )
    db.add_all(
        [
            AlliancePointLedger(
                alliance_id=alliance_id,
                alliance_member_id=referrer.id,
                delta=REFERRAL_REWARD_POINTS,
                reason="referral_reward",
            ),
            AlliancePointLedger(
                alliance_id=alliance_id,
                alliance_member_id=am.id,
                delta=REFERRAL_REWARD_POINTS,
                reason="referral_signup",
            ),
        ]
    )


@router.post("/register", response_model=PublicMemberRead)
@per_ip("10/minute")
async def register_member(request: Request, payload: MemberRegister, db: DbSession):
    phone = payload.phone.strip()
    if not phone:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "手機號碼必填")
    if not payload.terms_accepted:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "請先同意服務條款")
    if len(payload.password) < MIN_PASSWORD_LEN:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"密碼至少需 {MIN_PASSWORD_LEN} 碼")

    net = await get_or_create_marketplace_alliance(db)
    existing = (
        await db.execute(
            select(AllianceMember).where(
                AllianceMember.alliance_id == net.id,
                AllianceMember.phone == phone,
                AllianceMember.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if existing is not None:
        if existing.password_hash:
            raise HTTPException(status.HTTP_409_CONFLICT, "此手機已註冊，請直接登入")
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "此手機已有帳號，請改用驗證碼登入後於會員中心設定密碼",
        )

    now = datetime.now(timezone.utc)
    am = AllianceMember(
        alliance_id=net.id,
        phone=phone,
        name=payload.name.strip()[:64] or None,
        email=(payload.email.strip()[:128] or None) if payload.email else None,
        birthday=(payload.birthday.strip()[:10] or None) if payload.birthday else None,
        password_hash=hash_password(payload.password),
        terms_accepted_at=now,
        verified_at=now,
    )
    db.add(am)
    await db.flush()
    if payload.referral_code:
        await _apply_referral_at_signup(db, net.id, am, payload.referral_code)
    token, _ = issue_member_token(am)
    await db.commit()
    await db.refresh(am)
    return _member_read(am, token)


@router.post("/login", response_model=PublicMemberRead)
@per_ip("20/minute")
async def login_member(request: Request, payload: MemberPasswordLogin, db: DbSession):
    phone = payload.phone.strip()
    net = await get_or_create_marketplace_alliance(db)
    am = (
        await db.execute(
            select(AllianceMember).where(
                AllianceMember.alliance_id == net.id,
                AllianceMember.phone == phone,
                AllianceMember.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if am is not None and not am.password_hash:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "此帳號尚未設定密碼，請改用驗證碼登入")
    if am is None or not verify_password(payload.password, am.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "手機或密碼錯誤")
    token, _ = issue_member_token(am)
    return _member_read(am, token)


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
