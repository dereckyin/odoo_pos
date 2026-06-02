"""Member analytics endpoints (plan-gated)."""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import func, select

from ...core.deps import DbSession, TenantScope, apply_tenant
from ...core.usage import assert_plan_feature, get_tenant_features
from ...models import Member, MemberLevel, Order
from ...services.reporting import SALE_STATUSES, net_revenue_expr
from ...services.tenant_modules import require_business_intelligence

router = APIRouter(
    prefix="/analytics/members",
    tags=["analytics"],
    dependencies=[Depends(require_business_intelligence)],
)


class MemberOverview(BaseModel):
    total_members: int
    new_members_30d: int
    active_30d: int
    dormant_90d: int
    member_revenue_pct: float
    member_order_count: int
    total_order_count: int


class LevelStat(BaseModel):
    level_id: str | None
    level_name: str
    count: int
    total_spent_cents: int
    avg_spent_cents: int


class RfmCell(BaseModel):
    recency_bucket: str
    frequency_bucket: str
    count: int
    revenue_cents: int


class CohortRow(BaseModel):
    cohort_month: str
    month_offset: int
    active_members: int
    revenue_cents: int


class ChurnMember(BaseModel):
    member_id: str
    name: str
    phone: str
    last_visit_at: datetime | None
    total_spent_cents: int
    points: int


@router.get("/overview", response_model=MemberOverview)
async def member_overview(db: DbSession, scope: TenantScope):
    await assert_plan_feature(db, scope.tenant_id, "member_bi")
    now = datetime.now(timezone.utc)
    d30 = now - timedelta(days=30)
    d90 = now - timedelta(days=90)

    member_base = apply_tenant(
        select(Member).where(Member.deleted_at.is_(None)), Member, scope
    )
    total = int((await db.execute(select(func.count()).select_from(member_base.subquery()))).scalar_one())

    new_30 = int(
        (await db.execute(
            select(func.count(Member.id)).where(
                Member.tenant_id == scope.tenant_id,
                Member.deleted_at.is_(None),
                Member.joined_at >= d30,
            )
        )).scalar_one()
    )
    active = int(
        (await db.execute(
            select(func.count(Member.id)).where(
                Member.tenant_id == scope.tenant_id,
                Member.deleted_at.is_(None),
                Member.last_visit_at >= d30,
            )
        )).scalar_one()
    )
    dormant = int(
        (await db.execute(
            select(func.count(Member.id)).where(
                Member.tenant_id == scope.tenant_id,
                Member.deleted_at.is_(None),
                (Member.last_visit_at.is_(None)) | (Member.last_visit_at < d90),
            )
        )).scalar_one()
    )

    order_base = apply_tenant(select(Order), Order, scope).where(Order.status.in_(SALE_STATUSES))
    total_orders = int((await db.execute(select(func.count()).select_from(order_base.subquery()))).scalar_one())
    member_orders = int(
        (await db.execute(
            select(func.count(Order.id)).where(
                Order.tenant_id == scope.tenant_id,
                Order.status.in_(SALE_STATUSES),
                Order.member_id.isnot(None),
            )
        )).scalar_one()
    )
    member_rev = int(
        (await db.execute(
            select(func.coalesce(func.sum(net_revenue_expr()), 0)).where(
                Order.tenant_id == scope.tenant_id,
                Order.status.in_(SALE_STATUSES),
                Order.member_id.isnot(None),
            )
        )).scalar_one()
    )
    total_rev = int(
        (await db.execute(
            select(func.coalesce(func.sum(net_revenue_expr()), 0)).where(
                Order.tenant_id == scope.tenant_id,
                Order.status.in_(SALE_STATUSES),
            )
        )).scalar_one()
    )
    pct = round(member_rev / total_rev * 100, 1) if total_rev else 0.0

    return MemberOverview(
        total_members=total,
        new_members_30d=new_30,
        active_30d=active,
        dormant_90d=dormant,
        member_revenue_pct=pct,
        member_order_count=member_orders,
        total_order_count=total_orders,
    )


@router.get("/levels", response_model=list[LevelStat])
async def member_levels_stats(db: DbSession, scope: TenantScope):
    await assert_plan_feature(db, scope.tenant_id, "member_bi")
    levels = (
        await db.execute(
            select(MemberLevel).where(
                MemberLevel.tenant_id == scope.tenant_id,
                MemberLevel.deleted_at.is_(None),
            )
        )
    ).scalars().all()
    level_map = {l.id: l.name for l in levels}
    rows = (
        await db.execute(
            select(
                Member.level_id,
                func.count(Member.id),
                func.coalesce(func.sum(Member.total_spent_cents), 0),
            )
            .where(Member.tenant_id == scope.tenant_id, Member.deleted_at.is_(None))
            .group_by(Member.level_id)
        )
    ).all()
    out: list[LevelStat] = []
    for level_id, count, spent in rows:
        name = level_map.get(level_id, "未分級") if level_id else "未分級"
        avg = int(spent // count) if count else 0
        out.append(
            LevelStat(
                level_id=level_id,
                level_name=name,
                count=int(count),
                total_spent_cents=int(spent),
                avg_spent_cents=avg,
            )
        )
    return out


@router.get("/rfm", response_model=list[RfmCell])
async def member_rfm(db: DbSession, scope: TenantScope):
    await assert_plan_feature(db, scope.tenant_id, "member_bi_rfm")
    now = datetime.now(timezone.utc)
    members = (
        await db.execute(
            select(Member).where(
                Member.tenant_id == scope.tenant_id,
                Member.deleted_at.is_(None),
            )
        )
    ).scalars().all()
    cells: dict[tuple[str, str], RfmCell] = {}
    for m in members:
        days = (now - m.last_visit_at).days if m.last_visit_at else 999
        if days <= 30:
            r = "recent"
        elif days <= 90:
            r = "warm"
        else:
            r = "cold"
        freq_orders = int(
            (await db.execute(
                select(func.count(Order.id)).where(
                    Order.member_id == m.id,
                    Order.status.in_(SALE_STATUSES),
                )
            )).scalar_one()
        )
        if freq_orders >= 10:
            f = "high"
        elif freq_orders >= 3:
            f = "mid"
        else:
            f = "low"
        key = (r, f)
        if key not in cells:
            cells[key] = RfmCell(recency_bucket=r, frequency_bucket=f, count=0, revenue_cents=0)
        cells[key].count += 1
        cells[key].revenue_cents += m.total_spent_cents
    return list(cells.values())


@router.get("/cohort", response_model=list[CohortRow])
async def member_cohort(db: DbSession, scope: TenantScope):
    await assert_plan_feature(db, scope.tenant_id, "member_bi_rfm")
    members = (
        await db.execute(
            select(Member).where(
                Member.tenant_id == scope.tenant_id,
                Member.deleted_at.is_(None),
            )
        )
    ).scalars().all()
    rows: list[CohortRow] = []
    for m in members:
        cohort = m.joined_at.strftime("%Y-%m")
        if not m.last_visit_at:
            continue
        offset = (m.last_visit_at.year - m.joined_at.year) * 12 + (
            m.last_visit_at.month - m.joined_at.month
        )
        rows.append(
            CohortRow(
                cohort_month=cohort,
                month_offset=max(0, offset),
                active_members=1,
                revenue_cents=m.total_spent_cents,
            )
        )
    merged: dict[tuple[str, int], CohortRow] = {}
    for r in rows:
        k = (r.cohort_month, r.month_offset)
        if k not in merged:
            merged[k] = r
        else:
            merged[k].active_members += 1
            merged[k].revenue_cents += r.revenue_cents
    return sorted(merged.values(), key=lambda x: (x.cohort_month, x.month_offset))


@router.get("/churn-risk", response_model=list[ChurnMember])
async def churn_risk(
    db: DbSession, scope: TenantScope, limit: int = Query(50, le=200)
):
    feats = await get_tenant_features(db, scope.tenant_id)
    if not feats.get("member_bi_rfm"):
        await assert_plan_feature(db, scope.tenant_id, "member_bi_rfm")
    d90 = datetime.now(timezone.utc) - timedelta(days=90)
    rows = (
        await db.execute(
            select(Member)
            .where(
                Member.tenant_id == scope.tenant_id,
                Member.deleted_at.is_(None),
                Member.total_spent_cents > 0,
                (Member.last_visit_at.is_(None)) | (Member.last_visit_at < d90),
            )
            .order_by(Member.total_spent_cents.desc())
            .limit(limit)
        )
    ).scalars().all()
    return [
        ChurnMember(
            member_id=m.id,
            name=m.name,
            phone=m.phone,
            last_visit_at=m.last_visit_at,
            total_spent_cents=m.total_spent_cents,
            points=m.points,
        )
        for m in rows
    ]
