from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import or_, select

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    StoreAdminDep,
    TenantScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...models import Member, MemberLevel, PointTransaction
from ...schemas.member import (
    MemberCreate,
    MemberLevelCreate,
    MemberLevelRead,
    MemberRead,
    MemberUpdate,
    PointTransactionCreate,
    PointTransactionRead,
)

router = APIRouter(prefix="/members", tags=["members"])


@router.get("/levels", response_model=list[MemberLevelRead])
async def list_levels(db: DbSession, scope: TenantScope):
    stmt = apply_tenant(
        select(MemberLevel).where(MemberLevel.deleted_at.is_(None)), MemberLevel, scope
    ).order_by(MemberLevel.sort_order)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.post("/levels", response_model=MemberLevelRead, status_code=201)
async def create_level(
    payload: MemberLevelCreate, db: DbSession, scope: StoreAdminDep
):
    lvl = MemberLevel(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(lvl)
    await audit(db, scope, action="member_level_create", resource_type="member_level",
                flush=False)
    await db.commit()
    await db.refresh(lvl)
    return lvl


@router.get("", response_model=list[MemberRead])
async def search_members(
    db: DbSession, scope: TenantScope, q: str | None = None,
    limit: int = Query(30, le=100),
):
    stmt = apply_tenant(select(Member).where(Member.deleted_at.is_(None)), Member, scope)
    if q:
        like = f"%{q}%"
        stmt = stmt.where(
            or_(Member.phone.ilike(like), Member.name.ilike(like), Member.qr_code == q)
        )
    stmt = stmt.order_by(Member.last_visit_at.desc().nullslast()).limit(limit)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.post("", response_model=MemberRead, status_code=201)
async def create_member(payload: MemberCreate, db: DbSession, scope: TenantScope):
    existing = (
        await db.execute(
            select(Member).where(
                Member.tenant_id == scope.tenant_id,
                Member.phone == payload.phone,
                Member.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "phone already registered")
    m = Member(
        tenant_id=scope.tenant_id,
        joined_at=datetime.now(timezone.utc),
        **payload.model_dump(),
    )
    db.add(m)
    await audit(db, scope, action="member_create", resource_type="member", flush=False)
    await db.commit()
    await db.refresh(m)
    return m


@router.get("/by-phone/{phone}", response_model=MemberRead)
async def find_by_phone(phone: str, db: DbSession, scope: TenantScope):
    m = (
        await db.execute(
            select(Member).where(
                Member.tenant_id == scope.tenant_id,
                Member.phone == phone,
                Member.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not m:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return m


@router.get("/by-qr/{qr}", response_model=MemberRead)
async def find_by_qr(qr: str, db: DbSession, scope: TenantScope):
    m = (
        await db.execute(
            select(Member).where(
                Member.tenant_id == scope.tenant_id,
                Member.qr_code == qr,
                Member.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if not m:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return m


@router.get("/{mid}", response_model=MemberRead)
async def get_member(mid: str, db: DbSession, scope: TenantScope):
    m = await db.get(Member, mid)
    if not m or m.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, m)
    return m


@router.patch("/{mid}", response_model=MemberRead)
async def update_member(
    mid: str, payload: MemberUpdate, db: DbSession, scope: TenantScope
):
    m = await db.get(Member, mid)
    if not m or m.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, m)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(m, k, v)
    await audit(db, scope, action="member_update", resource_type="member",
                resource_id=mid, flush=False)
    await db.commit()
    await db.refresh(m)
    return m


@router.post("/points", response_model=PointTransactionRead, status_code=201)
async def record_points(
    payload: PointTransactionCreate, db: DbSession, scope: TenantScope
):
    member = await db.get(Member, payload.member_id)
    if not member:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "member not found")
    ensure_same_tenant(scope, member)
    member.points = max(0, member.points + payload.delta)
    member.last_visit_at = datetime.now(timezone.utc)
    tx = PointTransaction(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(tx)
    await audit(db, scope, action="member_points_adjust", resource_type="member",
                resource_id=member.id, extra={"delta": payload.delta}, flush=False)
    await db.commit()
    await db.refresh(tx)
    return tx
