"""Marketing SMS broadcast to opted-in members (plan-gated)."""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select

from ...core.deps import DbSession, StoreAdminDep, apply_tenant
from ...core.notify import send_sms
from ...core.usage import get_tenant_features
from ...models import Member, MemberBroadcast

router = APIRouter(prefix="/members/broadcasts", tags=["members"])


class BroadcastRead(BaseModel):
    id: str
    channel: str
    message: str
    audience_count: int
    sent_count: int
    failed_count: int
    created_at: datetime

    class Config:
        from_attributes = True


class AudiencePreview(BaseModel):
    count: int


class BroadcastCreate(BaseModel):
    message: str = Field(min_length=1, max_length=480)


def _opted_in_filter(stmt):
    return stmt.where(
        Member.deleted_at.is_(None),
        Member.marketing_opt_in.is_(True),
        Member.phone.is_not(None),
        Member.phone != "",
    )


@router.get("/audience", response_model=AudiencePreview)
async def audience_preview(db: DbSession, scope: StoreAdminDep):
    stmt = _opted_in_filter(
        apply_tenant(select(func.count(Member.id)), Member, scope)
    )
    count = int((await db.execute(stmt)).scalar_one())
    return AudiencePreview(count=count)


@router.get("", response_model=list[BroadcastRead])
async def list_broadcasts(
    db: DbSession, scope: StoreAdminDep, limit: int = Query(50, le=200)
):
    stmt = (
        apply_tenant(select(MemberBroadcast), MemberBroadcast, scope)
        .order_by(MemberBroadcast.created_at.desc())
        .limit(limit)
    )
    return (await db.execute(stmt)).scalars().all()


@router.post("", response_model=BroadcastRead, status_code=201)
async def send_broadcast(
    payload: BroadcastCreate, db: DbSession, scope: StoreAdminDep
):
    # Plan threshold: optional monthly cap on number of broadcasts.
    feats = await get_tenant_features(db, scope.tenant_id)
    cap = int(feats.get("max_broadcast_per_month") or 0)
    if cap > 0:
        month_start = datetime.now(timezone.utc).replace(
            day=1, hour=0, minute=0, second=0, microsecond=0
        )
        used = int(
            (
                await db.execute(
                    select(func.count(MemberBroadcast.id)).where(
                        MemberBroadcast.tenant_id == scope.tenant_id,
                        MemberBroadcast.created_at >= month_start,
                    )
                )
            ).scalar_one()
        )
        if used >= cap:
            raise HTTPException(
                status.HTTP_402_PAYMENT_REQUIRED,
                f"monthly broadcast limit ({cap}) reached; upgrade plan to send more.",
            )

    rows = (
        await db.execute(
            _opted_in_filter(apply_tenant(select(Member), Member, scope))
        )
    ).scalars().all()

    audience = len(rows)
    if audience == 0:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "no marketing-opted-in members to send to"
        )

    sent = 0
    failed = 0
    for m in rows:
        try:
            ok = await send_sms(m.phone, payload.message)
        except Exception:  # noqa: BLE001
            ok = False
        if ok:
            sent += 1
        else:
            failed += 1

    rec = MemberBroadcast(
        tenant_id=scope.tenant_id,
        channel="sms",
        message=payload.message,
        audience_count=audience,
        sent_count=sent,
        failed_count=failed,
        created_by=scope.user_id,
    )
    db.add(rec)
    await db.commit()
    await db.refresh(rec)
    return rec
