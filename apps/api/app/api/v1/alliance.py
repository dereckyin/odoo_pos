"""Cross-brand alliance API (Enterprise)."""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import func, select

from ...core.audit import audit
from ...core.deps import DbSession, PlatformSuperDep, StoreAdminDep, TenantScope
from ...core.usage import assert_plan_feature
from ...models import (
    AllianceMember,
    AllianceNetwork,
    AllianceTenant,
    EmailOtp,
    Member,
)
from ...schemas.member import MemberRead
from ...services.alliance_service import earn_alliance_points, resolve_alliance_member, tenant_alliance

router = APIRouter(prefix="/alliance", tags=["alliance"])


class AllianceNetworkRead(BaseModel):
    id: str
    name: str
    code: str
    description: str | None
    status: str

    class Config:
        from_attributes = True


class AllianceNetworkCreate(BaseModel):
    name: str
    code: str
    description: str | None = None


class AllianceTenantRead(BaseModel):
    id: str
    alliance_id: str
    tenant_id: str
    data_scope: str
    status: str
    joined_at: datetime

    class Config:
        from_attributes = True


class JoinAllianceRequest(BaseModel):
    alliance_id: str
    data_scope: str = "points"


class ResolveMemberRequest(BaseModel):
    phone: str
    name: str | None = None
    otp_code: str


class AllianceDashboard(BaseModel):
    alliance_id: str
    active_members: int
    total_points: int
    tenant_count: int
    cross_brand_links: int


@router.get("/networks", response_model=list[AllianceNetworkRead])
async def list_networks(db: DbSession, scope: PlatformSuperDep):
    rows = (
        await db.execute(
            select(AllianceNetwork).where(AllianceNetwork.deleted_at.is_(None))
        )
    ).scalars().all()
    return rows


@router.post("/networks", response_model=AllianceNetworkRead, status_code=201)
async def create_network(payload: AllianceNetworkCreate, db: DbSession, scope: PlatformSuperDep):
    net = AllianceNetwork(**payload.model_dump())
    db.add(net)
    await audit(db, scope, action="alliance_create", resource_type="alliance", flush=False)
    await db.commit()
    await db.refresh(net)
    return net


@router.post("/join", response_model=AllianceTenantRead, status_code=201)
async def join_alliance(payload: JoinAllianceRequest, db: DbSession, scope: StoreAdminDep):
    await assert_plan_feature(db, scope.tenant_id, "alliance")
    existing = await tenant_alliance(db, scope.tenant_id)
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "tenant already in an alliance")
    net = await db.get(AllianceNetwork, payload.alliance_id)
    if not net or net.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "alliance not found")
    at = AllianceTenant(
        alliance_id=payload.alliance_id,
        tenant_id=scope.tenant_id,
        data_scope=payload.data_scope,
        status="active",
        joined_at=datetime.now(timezone.utc),
    )
    db.add(at)
    await audit(db, scope, action="alliance_join", resource_type="alliance_tenant", flush=False)
    await db.commit()
    await db.refresh(at)
    return at


@router.get("/me", response_model=AllianceTenantRead | None)
async def my_alliance(db: DbSession, scope: TenantScope):
    at = await tenant_alliance(db, scope.tenant_id)
    return at


@router.post("/resolve", response_model=MemberRead)
async def resolve_member(payload: ResolveMemberRequest, db: DbSession, scope: TenantScope):
    await assert_plan_feature(db, scope.tenant_id, "alliance")
    at = await tenant_alliance(db, scope.tenant_id)
    if not at:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "tenant not in an alliance")
    otp = (
        await db.execute(
            select(EmailOtp)
            .where(
                EmailOtp.purpose == "member_login",
                EmailOtp.email == payload.phone,
                EmailOtp.consumed_at.is_(None),
            )
            .order_by(EmailOtp.created_at.desc())
        )
    ).scalar_one_or_none()
    if not otp or otp.expires_at < datetime.now(timezone.utc):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "OTP expired or not found")
    import hashlib
    if otp.code_hash != hashlib.sha256(payload.otp_code.encode()).hexdigest():
        otp.attempts = otp.attempts + 1
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid OTP")
    otp.consumed_at = datetime.now(timezone.utc)
    _, member = await resolve_alliance_member(
        db,
        alliance_id=at.alliance_id,
        tenant_id=scope.tenant_id,
        phone=payload.phone,
        name=payload.name,
    )
    await db.commit()
    await db.refresh(member)
    return member


@router.get("/dashboard", response_model=AllianceDashboard)
async def alliance_dashboard(db: DbSession, scope: StoreAdminDep):
    await assert_plan_feature(db, scope.tenant_id, "alliance")
    at = await tenant_alliance(db, scope.tenant_id)
    if not at:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "not in alliance")
    aid = at.alliance_id
    active_members = int(
        (await db.execute(
            select(func.count(AllianceMember.id)).where(
                AllianceMember.alliance_id == aid,
                AllianceMember.deleted_at.is_(None),
            )
        )).scalar_one()
    )
    total_points = int(
        (await db.execute(
            select(func.coalesce(func.sum(AllianceMember.points), 0)).where(
                AllianceMember.alliance_id == aid,
                AllianceMember.deleted_at.is_(None),
            )
        )).scalar_one()
    )
    tenant_count = int(
        (await db.execute(
            select(func.count(AllianceTenant.id)).where(
                AllianceTenant.alliance_id == aid,
                AllianceTenant.status == "active",
            )
        )).scalar_one()
    )
    links = int(
        (await db.execute(
            select(func.count(TenantMemberLink.id)).where(
                TenantMemberLink.alliance_id == aid,
            )
        )).scalar_one()
    )
    return AllianceDashboard(
        alliance_id=aid,
        active_members=active_members,
        total_points=total_points,
        tenant_count=tenant_count,
        cross_brand_links=links,
    )
