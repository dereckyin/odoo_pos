from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, or_, select

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    StoreAdminDep,
    TenantScope,
    apply_tenant,
    ensure_same_tenant,
)
from ...core.usage import assert_member_limit, assert_plan_feature, get_tenant_features
from ...models import LoyaltyRule, Member, MemberLevel, Order, PointTransaction, Tenant
from ...schemas.member import (
    LoyaltyRuleCreate,
    LoyaltyRuleRead,
    LoyaltyRuleUpdate,
    LoyaltySettings,
    MemberCreate,
    MemberLevelCreate,
    MemberLevelRead,
    MemberLevelUpdate,
    MemberRead,
    MemberUpdate,
    PointTransactionCreate,
    PointTransactionRead,
)
from ...schemas.order import OrderListItem, OrderListResponse
from ...services.loyalty_engine import loyalty_settings
from ...services.member_no import next_member_no
from ...services.order_query import enrich_order_item, load_order_display_maps
from ...services.webhooks import emit_webhook

router = APIRouter(prefix="/members", tags=["members"])


@router.get("/levels", response_model=list[MemberLevelRead])
async def list_levels(db: DbSession, scope: TenantScope):
    stmt = apply_tenant(
        select(MemberLevel).where(MemberLevel.deleted_at.is_(None)), MemberLevel, scope
    ).order_by(MemberLevel.sort_order)
    return (await db.execute(stmt)).scalars().all()


@router.post("/levels", response_model=MemberLevelRead, status_code=201)
async def create_level(payload: MemberLevelCreate, db: DbSession, scope: StoreAdminDep):
    feats = await get_tenant_features(db, scope.tenant_id)
    cap = int(feats.get("max_levels") or 0)
    if cap > 0:
        count = (
            await db.execute(
                select(func.count(MemberLevel.id)).where(
                    MemberLevel.tenant_id == scope.tenant_id,
                    MemberLevel.deleted_at.is_(None),
                )
            )
        ).scalar() or 0
        if count >= cap:
            raise HTTPException(status.HTTP_402_PAYMENT_REQUIRED, f"level limit ({cap}) reached")
    lvl = MemberLevel(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(lvl)
    await audit(db, scope, action="member_level_create", resource_type="member_level", flush=False)
    await db.commit()
    await db.refresh(lvl)
    return lvl


DEFAULT_LEVELS = [
    {"name": "一般會員", "discount_rate": 1.0, "min_spend": 0, "min_points": 0, "sort_order": 0, "color": "#9CA3AF"},
    {"name": "尊榮會員", "discount_rate": 0.95, "min_spend": 1000000, "min_points": 0, "sort_order": 1, "color": "#F59E0B"},
    {"name": "永久會員", "discount_rate": 0.9, "min_spend": 0, "min_points": 0, "sort_order": 2, "color": "#7C3AED"},
]


@router.post("/levels/seed-defaults", response_model=list[MemberLevelRead])
async def seed_default_levels(db: DbSession, scope: StoreAdminDep):
    """Create the 一般／尊榮／永久 default member levels (skips existing names).

    永久會員 is intended to be assigned manually (`PATCH /members/{id}` level_id);
    尊榮會員 auto-upgrades by spend when ``auto_level`` is on.
    """
    existing = set(
        (
            await db.execute(
                select(MemberLevel.name).where(
                    MemberLevel.tenant_id == scope.tenant_id,
                    MemberLevel.deleted_at.is_(None),
                )
            )
        ).scalars().all()
    )
    created: list[MemberLevel] = []
    for spec in DEFAULT_LEVELS:
        if spec["name"] in existing:
            continue
        lvl = MemberLevel(tenant_id=scope.tenant_id, **spec)
        db.add(lvl)
        created.append(lvl)
    if created:
        await audit(
            db, scope, action="member_levels_seed_defaults", resource_type="member_level", flush=False
        )
        await db.commit()
        for lvl in created:
            await db.refresh(lvl)
    stmt = apply_tenant(
        select(MemberLevel).where(MemberLevel.deleted_at.is_(None)), MemberLevel, scope
    ).order_by(MemberLevel.sort_order)
    return (await db.execute(stmt)).scalars().all()


@router.patch("/levels/{lid}", response_model=MemberLevelRead)
async def update_level(lid: str, payload: MemberLevelUpdate, db: DbSession, scope: StoreAdminDep):
    lvl = await db.get(MemberLevel, lid)
    if not lvl or lvl.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, lvl)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(lvl, k, v)
    await audit(db, scope, action="member_level_update", resource_type="member_level", resource_id=lid, flush=False)
    await db.commit()
    await db.refresh(lvl)
    return lvl


@router.delete("/levels/{lid}", status_code=204)
async def delete_level(lid: str, db: DbSession, scope: StoreAdminDep):
    lvl = await db.get(MemberLevel, lid)
    if not lvl or lvl.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, lvl)
    lvl.deleted_at = datetime.now(timezone.utc)
    await audit(db, scope, action="member_level_delete", resource_type="member_level", resource_id=lid, flush=False)
    await db.commit()


@router.get("/loyalty/settings", response_model=LoyaltySettings)
async def get_loyalty_settings(db: DbSession, scope: TenantScope):
    tenant = await db.get(Tenant, scope.tenant_id)
    return LoyaltySettings(**loyalty_settings(tenant))


@router.put("/loyalty/settings", response_model=LoyaltySettings)
async def update_loyalty_settings(payload: LoyaltySettings, db: DbSession, scope: StoreAdminDep):
    tenant = await db.get(Tenant, scope.tenant_id)
    if not tenant:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    settings = dict(tenant.settings or {})
    settings["loyalty"] = payload.model_dump()
    tenant.settings = settings
    await audit(db, scope, action="loyalty_settings_update", resource_type="tenant", flush=False)
    await db.commit()
    return payload


@router.get("/loyalty/rules", response_model=list[LoyaltyRuleRead])
async def list_loyalty_rules(db: DbSession, scope: TenantScope):
    stmt = apply_tenant(
        select(LoyaltyRule).where(LoyaltyRule.deleted_at.is_(None)), LoyaltyRule, scope
    ).order_by(LoyaltyRule.sort_order)
    return (await db.execute(stmt)).scalars().all()


@router.post("/loyalty/rules", response_model=LoyaltyRuleRead, status_code=201)
async def create_loyalty_rule(payload: LoyaltyRuleCreate, db: DbSession, scope: StoreAdminDep):
    feats = await get_tenant_features(db, scope.tenant_id)
    cap = int(feats.get("max_loyalty_rules") or 0)
    if cap > 0:
        count = (
            await db.execute(
                select(func.count(LoyaltyRule.id)).where(
                    LoyaltyRule.tenant_id == scope.tenant_id,
                    LoyaltyRule.deleted_at.is_(None),
                )
            )
        ).scalar() or 0
        if count >= cap:
            raise HTTPException(status.HTTP_402_PAYMENT_REQUIRED, "loyalty rule limit reached")
    rule = LoyaltyRule(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(rule)
    await db.commit()
    await db.refresh(rule)
    return rule


@router.patch("/loyalty/rules/{rid}", response_model=LoyaltyRuleRead)
async def update_loyalty_rule(rid: str, payload: LoyaltyRuleUpdate, db: DbSession, scope: StoreAdminDep):
    rule = await db.get(LoyaltyRule, rid)
    if not rule or rule.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, rule)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(rule, k, v)
    await db.commit()
    await db.refresh(rule)
    return rule


@router.delete("/loyalty/rules/{rid}", status_code=204)
async def delete_loyalty_rule(rid: str, db: DbSession, scope: StoreAdminDep):
    rule = await db.get(LoyaltyRule, rid)
    if not rule or rule.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, rule)
    rule.deleted_at = datetime.now(timezone.utc)
    await db.commit()


@router.get("", response_model=list[MemberRead])
async def search_members(
    db: DbSession, scope: TenantScope, q: str | None = None,
    limit: int = Query(30, le=100),
):
    stmt = apply_tenant(select(Member).where(Member.deleted_at.is_(None)), Member, scope)
    if q:
        like = f"%{q}%"
        stmt = stmt.where(
            or_(
                Member.phone.ilike(like),
                Member.name.ilike(like),
                Member.member_no.ilike(like),
                Member.qr_code == q,
            )
        )
    stmt = stmt.order_by(Member.last_visit_at.desc().nullslast()).limit(limit)
    return (await db.execute(stmt)).scalars().all()


@router.post("", response_model=MemberRead, status_code=201)
async def create_member(payload: MemberCreate, db: DbSession, scope: TenantScope):
    await assert_member_limit(db, scope.tenant_id)
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
    data = payload.model_dump()
    opt_in = bool(data.get("marketing_opt_in"))
    member_no = data.pop("member_no", None) or await next_member_no(db, scope.tenant_id)
    qr_code = data.pop("qr_code", None) or member_no
    m = Member(
        tenant_id=scope.tenant_id,
        joined_at=datetime.now(timezone.utc),
        member_no=member_no,
        qr_code=qr_code,
        marketing_opt_in_at=datetime.now(timezone.utc) if opt_in else None,
        **data,
    )
    db.add(m)
    await audit(db, scope, action="member_create", resource_type="member", flush=False)
    await db.commit()
    await db.refresh(m)
    await emit_webhook(
        db,
        tenant_id=scope.tenant_id,
        event="member.created",
        payload={"member_id": m.id, "phone": m.phone, "name": m.name},
    )
    await db.commit()
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


@router.get("/by-no/{no}", response_model=MemberRead)
async def find_by_no(no: str, db: DbSession, scope: TenantScope):
    m = (
        await db.execute(
            select(Member).where(
                Member.tenant_id == scope.tenant_id,
                Member.member_no == no,
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
async def update_member(mid: str, payload: MemberUpdate, db: DbSession, scope: TenantScope):
    m = await db.get(Member, mid)
    if not m or m.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, m)
    changes = payload.model_dump(exclude_unset=True)
    if "marketing_opt_in" in changes:
        new_opt = bool(changes["marketing_opt_in"])
        if new_opt and not m.marketing_opt_in:
            m.marketing_opt_in_at = datetime.now(timezone.utc)
        elif not new_opt:
            m.marketing_opt_in_at = None
    for k, v in changes.items():
        setattr(m, k, v)
    await audit(db, scope, action="member_update", resource_type="member", resource_id=mid, flush=False)
    await db.commit()
    await db.refresh(m)
    return m


@router.get("/{mid}/points", response_model=list[PointTransactionRead])
async def list_point_transactions(
    mid: str, db: DbSession, scope: TenantScope, limit: int = Query(50, le=200)
):
    m = await db.get(Member, mid)
    if not m or m.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, m)
    rows = (
        await db.execute(
            select(PointTransaction)
            .where(PointTransaction.member_id == mid)
            .order_by(PointTransaction.created_at.desc())
            .limit(limit)
        )
    ).scalars().all()
    return rows


@router.get("/{mid}/orders", response_model=OrderListResponse)
async def list_member_orders(
    mid: str, db: DbSession, scope: TenantScope, limit: int = Query(20, le=100), offset: int = 0
):
    m = await db.get(Member, mid)
    if not m or m.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, m)
    base = apply_tenant(select(Order), Order, scope).where(Order.member_id == mid)
    total = int((await db.execute(select(func.count()).select_from(base.subquery()))).scalar_one())
    rows = (
        await db.execute(
            base.order_by(Order.client_created_at.desc().nullslast()).limit(limit).offset(offset)
        )
    ).scalars().all()
    store_map, cashier_map, member_map = await load_order_display_maps(db, rows)
    items = [
        enrich_order_item(
            o,
            store_name=store_map.get(o.store_id),
            cashier_name=cashier_map.get(o.cashier_id),
            member_name=member_map.get(o.member_id) if o.member_id else None,
        )
        for o in rows
    ]
    return OrderListResponse(items=items, total=total, offset=offset, limit=limit)


@router.post("/points", response_model=PointTransactionRead, status_code=201)
async def record_points(payload: PointTransactionCreate, db: DbSession, scope: TenantScope):
    member = await db.get(Member, payload.member_id)
    if not member:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "member not found")
    ensure_same_tenant(scope, member)
    member.points = max(0, member.points + payload.delta)
    member.last_visit_at = datetime.now(timezone.utc)
    tx = PointTransaction(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(tx)
    await audit(
        db, scope, action="member_points_adjust", resource_type="member",
        resource_id=member.id, extra={"delta": payload.delta}, flush=False,
    )
    await db.commit()
    await db.refresh(tx)
    return tx
