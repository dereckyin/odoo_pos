from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import or_, select

from ...core.deps import AdminDep, CurrentUserDep, DbSession
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
async def list_levels(db: DbSession, _: CurrentUserDep):
    rows = (
        await db.execute(
            select(MemberLevel).where(MemberLevel.deleted_at.is_(None)).order_by(MemberLevel.sort_order)
        )
    ).scalars().all()
    return rows


@router.post("/levels", response_model=MemberLevelRead, status_code=201)
async def create_level(payload: MemberLevelCreate, db: DbSession, _: AdminDep):
    lvl = MemberLevel(**payload.model_dump())
    db.add(lvl)
    await db.commit()
    await db.refresh(lvl)
    return lvl


@router.get("", response_model=list[MemberRead])
async def search_members(db: DbSession, _: CurrentUserDep, q: str | None = None, limit: int = Query(30, le=100)):
    stmt = select(Member).where(Member.deleted_at.is_(None))
    if q:
        like = f"%{q}%"
        stmt = stmt.where(
            or_(Member.phone.ilike(like), Member.name.ilike(like), Member.qr_code == q)
        )
    stmt = stmt.order_by(Member.last_visit_at.desc().nullslast()).limit(limit)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.post("", response_model=MemberRead, status_code=201)
async def create_member(payload: MemberCreate, db: DbSession, _: CurrentUserDep):
    existing = (
        await db.execute(select(Member).where(Member.phone == payload.phone, Member.deleted_at.is_(None)))
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "phone already registered")
    m = Member(**payload.model_dump(), joined_at=datetime.now(timezone.utc))
    db.add(m)
    await db.commit()
    await db.refresh(m)
    return m


@router.get("/by-phone/{phone}", response_model=MemberRead)
async def find_by_phone(phone: str, db: DbSession, _: CurrentUserDep):
    m = (
        await db.execute(select(Member).where(Member.phone == phone, Member.deleted_at.is_(None)))
    ).scalar_one_or_none()
    if not m:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return m


@router.get("/by-qr/{qr}", response_model=MemberRead)
async def find_by_qr(qr: str, db: DbSession, _: CurrentUserDep):
    m = (
        await db.execute(select(Member).where(Member.qr_code == qr, Member.deleted_at.is_(None)))
    ).scalar_one_or_none()
    if not m:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return m


@router.get("/{mid}", response_model=MemberRead)
async def get_member(mid: str, db: DbSession, _: CurrentUserDep):
    m = await db.get(Member, mid)
    if not m or m.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return m


@router.patch("/{mid}", response_model=MemberRead)
async def update_member(mid: str, payload: MemberUpdate, db: DbSession, _: CurrentUserDep):
    m = await db.get(Member, mid)
    if not m or m.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(m, k, v)
    await db.commit()
    await db.refresh(m)
    return m


@router.post("/points", response_model=PointTransactionRead, status_code=201)
async def record_points(payload: PointTransactionCreate, db: DbSession, _: CurrentUserDep):
    member = await db.get(Member, payload.member_id)
    if not member:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "member not found")
    member.points = max(0, member.points + payload.delta)
    member.last_visit_at = datetime.now(timezone.utc)
    tx = PointTransaction(**payload.model_dump())
    db.add(tx)
    await db.commit()
    await db.refresh(tx)
    return tx
