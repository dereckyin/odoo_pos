"""Marketplace member center: profile, orders, points, coupons, favorites,
wallet and referrals. All endpoints authenticate with the unified marketplace
member token (see ``public_members.current_marketplace_member``).
"""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.deps import DbSession
from ...core.security import hash_password
from ...models import (
    AllianceMember,
    AlliancePointLedger,
    Coupon,
    GuestOrder,
    MarketplaceListing,
    Member,
    MemberFavoriteStore,
    MemberReferral,
    MemberWallet,
    Store,
    TenantMemberLink,
    WalletTransaction,
)
from ...schemas.marketplace import MarketplaceOrderRead, MarketplaceStoreSummary
from ...services.marketplace import listing_to_summary
from ...services.line_oa import fetch_line_profile
from ...services.marketplace_member import ensure_referral_code, get_or_create_marketplace_alliance
from .public_marketplace import _to_marketplace_read
from .public_members import MarketplaceMemberDep, load_alliance_member

router = APIRouter(prefix="/public/members/me", tags=["public-member-center"])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

async def _linked_member_ids(db, alliance_member_id: str) -> list[str]:
    rows = (
        await db.execute(
            select(TenantMemberLink.member_id).where(
                TenantMemberLink.alliance_member_id == alliance_member_id
            )
        )
    ).scalars().all()
    return list(rows)


async def _get_or_create_wallet(db, alliance_member_id: str) -> MemberWallet:
    w = (
        await db.execute(
            select(MemberWallet).where(MemberWallet.alliance_member_id == alliance_member_id)
        )
    ).scalar_one_or_none()
    if not w:
        w = MemberWallet(alliance_member_id=alliance_member_id, balance_cents=0)
        db.add(w)
        await db.flush()
    return w


# ---------------------------------------------------------------------------
# Profile
# ---------------------------------------------------------------------------

MIN_PASSWORD_LEN = 8


class MemberProfile(BaseModel):
    alliance_member_id: str
    name: str | None
    phone: str
    email: str | None
    points: int
    birthday: str | None
    referral_code: str | None
    wallet_balance_cents: int
    has_password: bool
    line_linked: bool = False


class ProfileUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=64)
    birthday: str | None = Field(default=None, max_length=10)
    email: str | None = Field(default=None, max_length=128)
    password: str | None = Field(default=None, max_length=128)


def _profile(am, code: str, wallet) -> "MemberProfile":
    return MemberProfile(
        alliance_member_id=am.id,
        name=am.name,
        phone=am.phone,
        email=am.email,
        points=am.points,
        birthday=am.birthday,
        referral_code=code,
        wallet_balance_cents=wallet.balance_cents,
        has_password=bool(am.password_hash),
        line_linked=bool(getattr(am, "line_user_id", None)),
    )


@router.get("", response_model=MemberProfile)
async def get_profile(db: DbSession, ctx: MarketplaceMemberDep):
    am = await load_alliance_member(db, ctx)
    code = await ensure_referral_code(db, am)
    wallet = await _get_or_create_wallet(db, am.id)
    await db.commit()
    return _profile(am, code, wallet)


@router.patch("", response_model=MemberProfile)
async def update_profile(payload: ProfileUpdate, db: DbSession, ctx: MarketplaceMemberDep):
    am = await load_alliance_member(db, ctx)
    if payload.name is not None:
        am.name = payload.name[:64] or None
    if payload.birthday is not None:
        am.birthday = payload.birthday[:10] or None
    if payload.email is not None:
        am.email = payload.email.strip()[:128] or None
    if payload.password is not None and payload.password != "":
        if len(payload.password) < MIN_PASSWORD_LEN:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"密碼至少需 {MIN_PASSWORD_LEN} 碼")
        am.password_hash = hash_password(payload.password)
    code = await ensure_referral_code(db, am)
    wallet = await _get_or_create_wallet(db, am.id)
    await db.commit()
    await db.refresh(am)
    return _profile(am, code, wallet)


class LineBindRequest(BaseModel):
    access_token: str = Field(min_length=1)


class LineBindResult(BaseModel):
    line_linked: bool
    display_name: str | None = None


@router.post("/line/bind", response_model=LineBindResult)
async def bind_line(payload: LineBindRequest, db: DbSession, ctx: MarketplaceMemberDep):
    """Bind the member's LINE account using a LIFF user access token.

    The frontend obtains the token via ``liff.getAccessToken()`` and posts it
    here; we resolve the LINE ``userId`` from the LINE profile API and store it.
    """
    profile = await fetch_line_profile(payload.access_token)
    if not profile or not profile.get("userId"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "無法驗證 LINE 帳號")
    line_user_id = profile["userId"]

    existing = (
        await db.execute(
            select(AllianceMember).where(
                AllianceMember.line_user_id == line_user_id,
                AllianceMember.id != ctx.alliance_member_id,
            )
        )
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "此 LINE 帳號已綁定其他會員")

    am = await load_alliance_member(db, ctx)
    am.line_user_id = line_user_id
    await db.commit()
    return LineBindResult(line_linked=True, display_name=profile.get("displayName"))


@router.delete("/line/bind", response_model=LineBindResult)
async def unbind_line(db: DbSession, ctx: MarketplaceMemberDep):
    am = await load_alliance_member(db, ctx)
    am.line_user_id = None
    await db.commit()
    return LineBindResult(line_linked=False)


# ---------------------------------------------------------------------------
# Orders
# ---------------------------------------------------------------------------

@router.get("/orders", response_model=list[MarketplaceOrderRead])
async def my_orders(db: DbSession, ctx: MarketplaceMemberDep, limit: int = 50):
    member_ids = await _linked_member_ids(db, ctx.alliance_member_id)
    if not member_ids:
        return []
    rows = (
        await db.execute(
            select(GuestOrder)
            .where(
                GuestOrder.channel == "marketplace",
                GuestOrder.member_id.in_(member_ids),
            )
            .options(selectinload(GuestOrder.lines))
            .order_by(GuestOrder.created_at.desc())
            .limit(min(limit, 100))
        )
    ).scalars().all()
    out: list[MarketplaceOrderRead] = []
    for g in rows:
        listing = (
            await db.execute(
                select(MarketplaceListing).where(MarketplaceListing.store_id == g.store_id)
            )
        ).scalar_one_or_none()
        store = await db.get(Store, g.store_id)
        if listing and store:
            out.append(_to_marketplace_read(g, listing, store))
    return out


# ---------------------------------------------------------------------------
# Points
# ---------------------------------------------------------------------------

class PointEntry(BaseModel):
    delta: int
    reason: str
    order_id: str | None
    created_at: datetime


class PointsSummary(BaseModel):
    balance: int
    entries: list[PointEntry]


@router.get("/points", response_model=PointsSummary)
async def my_points(db: DbSession, ctx: MarketplaceMemberDep):
    am = await load_alliance_member(db, ctx)
    rows = (
        await db.execute(
            select(AlliancePointLedger)
            .where(AlliancePointLedger.alliance_member_id == am.id)
            .order_by(AlliancePointLedger.created_at.desc())
            .limit(100)
        )
    ).scalars().all()
    return PointsSummary(
        balance=am.points,
        entries=[
            PointEntry(delta=r.delta, reason=r.reason, order_id=r.order_id, created_at=r.created_at)
            for r in rows
        ],
    )


# ---------------------------------------------------------------------------
# Coupons
# ---------------------------------------------------------------------------

class CouponRead(BaseModel):
    code: str
    type: str
    value: float
    min_spend_cents: int
    expires_at: datetime | None


@router.get("/coupons", response_model=list[CouponRead])
async def my_coupons(db: DbSession, ctx: MarketplaceMemberDep):
    member_ids = await _linked_member_ids(db, ctx.alliance_member_id)
    if not member_ids:
        return []
    now = datetime.now(timezone.utc)
    rows = (
        await db.execute(
            select(Coupon).where(
                Coupon.member_id.in_(member_ids),
                Coupon.deleted_at.is_(None),
                Coupon.used_at.is_(None),
            )
        )
    ).scalars().all()
    out = []
    for c in rows:
        if c.expires_at and c.expires_at < now:
            continue
        out.append(
            CouponRead(
                code=c.code,
                type=c.type,
                value=c.value,
                min_spend_cents=c.min_spend_cents,
                expires_at=c.expires_at,
            )
        )
    return out


# ---------------------------------------------------------------------------
# Favorites
# ---------------------------------------------------------------------------

class FavoriteAdd(BaseModel):
    store_slug: str


@router.get("/favorites", response_model=list[MarketplaceStoreSummary])
async def my_favorites(db: DbSession, ctx: MarketplaceMemberDep):
    rows = (
        await db.execute(
            select(MarketplaceListing, Store)
            .join(MemberFavoriteStore, MemberFavoriteStore.listing_id == MarketplaceListing.id)
            .join(Store, Store.id == MarketplaceListing.store_id)
            .where(
                MemberFavoriteStore.alliance_member_id == ctx.alliance_member_id,
                MarketplaceListing.status == "approved",
            )
        )
    ).all()
    out = []
    for listing, store in rows:
        data = listing_to_summary(listing, store)
        data["is_favorite"] = True
        out.append(MarketplaceStoreSummary(**data))
    return out


@router.post("/favorites", status_code=201)
async def add_favorite(payload: FavoriteAdd, db: DbSession, ctx: MarketplaceMemberDep):
    listing = (
        await db.execute(
            select(MarketplaceListing).where(
                MarketplaceListing.slug == payload.store_slug,
                MarketplaceListing.status == "approved",
            )
        )
    ).scalar_one_or_none()
    if not listing:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    existing = (
        await db.execute(
            select(MemberFavoriteStore).where(
                MemberFavoriteStore.alliance_member_id == ctx.alliance_member_id,
                MemberFavoriteStore.listing_id == listing.id,
            )
        )
    ).scalar_one_or_none()
    if not existing:
        db.add(
            MemberFavoriteStore(
                alliance_member_id=ctx.alliance_member_id, listing_id=listing.id
            )
        )
        await db.commit()
    return {"ok": True}


@router.delete("/favorites/{slug}")
async def remove_favorite(slug: str, db: DbSession, ctx: MarketplaceMemberDep):
    listing = (
        await db.execute(
            select(MarketplaceListing).where(MarketplaceListing.slug == slug)
        )
    ).scalar_one_or_none()
    if listing:
        fav = (
            await db.execute(
                select(MemberFavoriteStore).where(
                    MemberFavoriteStore.alliance_member_id == ctx.alliance_member_id,
                    MemberFavoriteStore.listing_id == listing.id,
                )
            )
        ).scalar_one_or_none()
        if fav:
            await db.delete(fav)
            await db.commit()
    return {"ok": True}


# ---------------------------------------------------------------------------
# Wallet
# ---------------------------------------------------------------------------

class WalletTxnRead(BaseModel):
    delta_cents: int
    reason: str
    order_id: str | None
    created_at: datetime


class WalletRead(BaseModel):
    balance_cents: int
    transactions: list[WalletTxnRead]


class TopupRequest(BaseModel):
    amount_cents: int = Field(gt=0, le=1_000_000)


@router.get("/wallet", response_model=WalletRead)
async def my_wallet(db: DbSession, ctx: MarketplaceMemberDep):
    wallet = await _get_or_create_wallet(db, ctx.alliance_member_id)
    txns = (
        await db.execute(
            select(WalletTransaction)
            .where(WalletTransaction.wallet_id == wallet.id)
            .order_by(WalletTransaction.created_at.desc())
            .limit(50)
        )
    ).scalars().all()
    await db.commit()
    return WalletRead(
        balance_cents=wallet.balance_cents,
        transactions=[
            WalletTxnRead(
                delta_cents=t.delta_cents,
                reason=t.reason,
                order_id=t.order_id,
                created_at=t.created_at,
            )
            for t in txns
        ],
    )


@router.post("/wallet/topup", response_model=WalletRead)
async def topup_wallet(payload: TopupRequest, db: DbSession, ctx: MarketplaceMemberDep):
    # Demo top-up: in production this would gate on a payment confirmation.
    wallet = await _get_or_create_wallet(db, ctx.alliance_member_id)
    wallet.balance_cents += payload.amount_cents
    db.add(
        WalletTransaction(
            wallet_id=wallet.id, delta_cents=payload.amount_cents, reason="topup"
        )
    )
    await db.commit()
    return await my_wallet(db, ctx)


# ---------------------------------------------------------------------------
# Referrals
# ---------------------------------------------------------------------------

REFERRAL_REWARD_POINTS = 50


class ReferralInfo(BaseModel):
    code: str
    referred_count: int
    reward_points: int


class ApplyReferral(BaseModel):
    code: str = Field(min_length=4, max_length=32)


@router.get("/referral", response_model=ReferralInfo)
async def my_referral(db: DbSession, ctx: MarketplaceMemberDep):
    am = await load_alliance_member(db, ctx)
    code = await ensure_referral_code(db, am)
    count = len(
        (
            await db.execute(
                select(MemberReferral.id).where(MemberReferral.referrer_member_id == am.id)
            )
        ).scalars().all()
    )
    await db.commit()
    return ReferralInfo(code=code, referred_count=count, reward_points=REFERRAL_REWARD_POINTS)


@router.post("/referral/apply", response_model=ReferralInfo)
async def apply_referral(payload: ApplyReferral, db: DbSession, ctx: MarketplaceMemberDep):
    am = await load_alliance_member(db, ctx)
    # A member can only be referred once.
    already = (
        await db.execute(
            select(MemberReferral).where(MemberReferral.referee_member_id == am.id)
        )
    ).scalar_one_or_none()
    if already:
        raise HTTPException(status.HTTP_409_CONFLICT, "已使用過推薦碼")
    referrer = (
        await db.execute(
            select(AllianceMember).where(
                AllianceMember.referral_code == payload.code.upper(),
                AllianceMember.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not referrer or referrer.id == am.id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "推薦碼無效")
    net = await get_or_create_marketplace_alliance(db)
    referrer.points += REFERRAL_REWARD_POINTS
    am.points += REFERRAL_REWARD_POINTS
    db.add(
        MemberReferral(
            alliance_id=net.id,
            referrer_member_id=referrer.id,
            referee_member_id=am.id,
            code=payload.code.upper(),
            reward_points=REFERRAL_REWARD_POINTS,
            status="rewarded",
        )
    )
    db.add_all(
        [
            AlliancePointLedger(
                alliance_id=net.id,
                alliance_member_id=referrer.id,
                delta=REFERRAL_REWARD_POINTS,
                reason="referral_reward",
            ),
            AlliancePointLedger(
                alliance_id=net.id,
                alliance_member_id=am.id,
                delta=REFERRAL_REWARD_POINTS,
                reason="referral_signup",
            ),
        ]
    )
    code = await ensure_referral_code(db, am)
    await db.commit()
    return ReferralInfo(code=code, referred_count=0, reward_points=REFERRAL_REWARD_POINTS)
