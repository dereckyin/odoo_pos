"""Platform-super-admin endpoints.

Used by the SaaS operator to review applications, suspend tenants, and
manage subscription plans. None of these endpoints should be exposed to
tenant users — guarded by ``PlatformSuperDep``.
"""
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from fastapi import APIRouter, HTTPException, Query, Request, status
from sqlalchemy import func, select

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    PlatformSuperDep,
    current_user,
)
from ...core.notify import send_email
from ...core.security import generate_secret, hash_password
from ...models import (
    Category,
    GuestOrder,
    MarketplaceListing,
    Product,
    ProductBarcode,
    Promotion,
    Store,
    SubscriptionPlan,
    Tenant,
    TenantApplication,
    TenantSubscription,
    User,
)
from ...schemas.auth import (
    TenantApplicationApprove,
    TenantDirectCreateRequest,
    TenantDirectCreateResponse,
    TenantApplicationRead,
    TenantApplicationReject,
)
from ...schemas.tenant import (
    PlatformDashboardStats,
    SubscriptionPlanRead,
    TenantModulesRead,
    TenantModulesUpdate,
    TenantRead,
    TenantUpdate,
)
from ...services.tenant_modules import (
    apply_modules_patch,
    get_tenant_modules,
)
from .tenant_apply import _to_read as _app_to_read

router = APIRouter(prefix="/platform", tags=["platform"])


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _taipei_today_bounds() -> tuple[datetime, datetime]:
    tz = ZoneInfo("Asia/Taipei")
    now = datetime.now(tz)
    start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    end = start.replace(hour=23, minute=59, second=59, microsecond=999999)
    return start.astimezone(timezone.utc), end.astimezone(timezone.utc)


DEFAULT_CATEGORIES = ["飲料", "零食", "便當/熟食", "生活用品", "煙酒"]
DEFAULT_PRODUCTS: list[tuple[str, str, int, str]] = [
    ("4710001000017", "可口可樂 350ml", 25, "飲料"),
    ("4710001000024", "雪碧 350ml", 25, "飲料"),
    ("4710001000031", "礦泉水 600ml", 18, "飲料"),
    ("4710001000048", "舒跑 350ml", 25, "飲料"),
    ("4710002000016", "樂事洋芋片", 35, "零食"),
    ("4710002000023", "波卡洋芋片", 30, "零食"),
    ("4710002000030", "義美夾心酥", 45, "零食"),
    ("4710003000015", "御便當-雞腿", 95, "便當/熟食"),
    ("4710003000022", "御便當-排骨", 85, "便當/熟食"),
    ("4710003000039", "三角飯糰", 28, "便當/熟食"),
    ("4710004000014", "舒潔面紙", 65, "生活用品"),
    ("4710004000021", "盤尼西林牙膏", 75, "生活用品"),
    ("4710005000013", "台啤經典 350ml", 38, "煙酒"),
    ("4710005000020", "黑松沙士 600ml", 30, "飲料"),
    ("4710006000012", "茶葉蛋", 13, "便當/熟食"),
]


async def _seed_default_catalog(
    db: DbSession, tenant_id: str
) -> tuple[dict[str, Category], int]:
    rows = (
        await db.execute(
            select(Category).where(
                Category.tenant_id == tenant_id,
                Category.deleted_at.is_(None),
            )
        )
    ).scalars().all()
    cat_map = {c.name: c for c in rows}
    for name in DEFAULT_CATEGORIES:
        if name not in cat_map:
            c = Category(tenant_id=tenant_id, name=name)
            db.add(c)
            await db.flush()
            cat_map[name] = c

    created_count = 0
    for sku, name, price, cat_name in DEFAULT_PRODUCTS:
        existing = (
            await db.execute(
                select(Product).where(
                    Product.tenant_id == tenant_id,
                    Product.sku == sku,
                    Product.deleted_at.is_(None),
                )
            )
        ).scalar_one_or_none()
        if existing:
            continue

        p = Product(
            tenant_id=tenant_id,
            sku=sku,
            name=name,
            price_cents=price,
            tax_rate=0.05,
            category_id=cat_map[cat_name].id,
            is_active=True,
            unit="個",
        )
        db.add(p)
        await db.flush()
        db.add(ProductBarcode(tenant_id=tenant_id, product_id=p.id, barcode=sku))
        created_count += 1
    return cat_map, created_count


async def _seed_default_promotions(
    db: DbSession, tenant_id: str, cat_map: dict[str, Category]
) -> int:
    now = _now()
    specs = [
        (
            "滿 200 折 20",
            "thresholdAmountOff",
            {"threshold_amount": 200, "off_amount": 20},
            10,
            [],
        ),
        (
            "飲料第二件 8 折",
            "nthItemDiscount",
            {"nth": 2, "nth_discount_pct": 20},
            20,
            [cat_map["飲料"].id] if "飲料" in cat_map else [],
        ),
        (
            "零食買二送一",
            "buyXGetY",
            {"buy_n": 2, "get_n": 1, "get_discount_pct": 100},
            15,
            [cat_map["零食"].id] if "零食" in cat_map else [],
        ),
    ]
    created_count = 0
    for name, strategy, config, priority, category_ids in specs:
        existing = (
            await db.execute(
                select(Promotion).where(
                    Promotion.tenant_id == tenant_id,
                    Promotion.name == name,
                    Promotion.deleted_at.is_(None),
                )
            )
        ).scalar_one_or_none()
        if existing:
            continue
        db.add(
            Promotion(
                tenant_id=tenant_id,
                name=name,
                strategy=strategy,
                config=config,
                priority=priority,
                starts_at=now - timedelta(days=1),
                ends_at=now + timedelta(days=30),
                is_active=True,
                applicable_product_ids=[],
                applicable_category_ids=category_ids,
                member_level_ids=[],
            )
        )
        created_count += 1
    return created_count


@router.get("/dashboard", response_model=PlatformDashboardStats)
async def platform_dashboard(db: DbSession, _: PlatformSuperDep):
    pending_apps = (
        await db.execute(
            select(func.count()).select_from(TenantApplication).where(
                TenantApplication.status == "pending"
            )
        )
    ).scalar_one() or 0
    pending_listings = (
        await db.execute(
            select(func.count()).select_from(MarketplaceListing).where(
                MarketplaceListing.status == "pending"
            )
        )
    ).scalar_one() or 0
    active_tenants = (
        await db.execute(
            select(func.count()).select_from(Tenant).where(
                Tenant.deleted_at.is_(None),
                Tenant.status == "active",
            )
        )
    ).scalar_one() or 0
    suspended_tenants = (
        await db.execute(
            select(func.count()).select_from(Tenant).where(
                Tenant.deleted_at.is_(None),
                Tenant.status == "suspended",
            )
        )
    ).scalar_one() or 0
    day_start, day_end = _taipei_today_bounds()
    mp_stats = (
        await db.execute(
            select(
                func.count(GuestOrder.id),
                func.coalesce(func.sum(GuestOrder.estimated_subtotal_cents), 0),
            ).where(
                GuestOrder.channel == "marketplace",
                GuestOrder.created_at >= day_start,
                GuestOrder.created_at <= day_end,
            )
        )
    ).one()
    return PlatformDashboardStats(
        pending_applications=pending_apps,
        pending_marketplace_listings=pending_listings,
        active_tenants=active_tenants,
        suspended_tenants=suspended_tenants,
        marketplace_orders_today=int(mp_stats[0] or 0),
        marketplace_revenue_today_cents=int(mp_stats[1] or 0),
    )


# ---------------------------------------------------------------------------
# Tenants
# ---------------------------------------------------------------------------

@router.get("/tenants", response_model=list[TenantRead])
async def list_tenants(
    db: DbSession,
    _: PlatformSuperDep,
    status_filter: str | None = Query(default=None, alias="status"),
    limit: int = Query(50, le=200),
):
    stmt = select(Tenant).where(Tenant.deleted_at.is_(None))
    if status_filter:
        stmt = stmt.where(Tenant.status == status_filter)
    stmt = stmt.order_by(Tenant.created_at.desc()).limit(limit)
    rows = (await db.execute(stmt)).scalars().all()
    return rows


@router.get("/tenants/{tenant_id}", response_model=TenantRead)
async def get_tenant(tenant_id: str, db: DbSession, _: PlatformSuperDep):
    t = await db.get(Tenant, tenant_id)
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return t


@router.patch("/tenants/{tenant_id}", response_model=TenantRead)
async def update_tenant(
    tenant_id: str,
    payload: TenantUpdate,
    request: Request,
    db: DbSession,
    user: PlatformSuperDep,
):
    t = await db.get(Tenant, tenant_id)
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(t, k, v)
    await audit(db, user, action="tenant_update", resource_type="tenant",
                resource_id=tenant_id, request=request, flush=False)
    await db.commit()
    await db.refresh(t)
    return t


@router.post("/tenants/direct-create", response_model=TenantDirectCreateResponse, status_code=201)
async def direct_create_tenant(
    payload: TenantDirectCreateRequest,
    request: Request,
    db: DbSession,
    user: PlatformSuperDep,
):
    plan = (
        await db.execute(
            select(SubscriptionPlan).where(SubscriptionPlan.code == payload.plan_code)
        )
    ).scalar_one_or_none()
    if not plan:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "unknown plan_code")

    tenant_code = payload.tenant_code.lower()
    if (await db.execute(select(Tenant).where(Tenant.code == tenant_code))).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "tenant code already in use")

    tenant = Tenant(
        code=tenant_code,
        name=payload.company_name,
        contact_email=payload.contact_email.lower(),
        contact_phone=payload.contact_phone,
        tax_id=payload.tax_id,
        status="active",
        plan_code=plan.code,
    )
    db.add(tenant)
    await db.flush()

    store = Store(
        tenant_id=tenant.id,
        code="MAIN",
        name=payload.company_name,
        tax_id=payload.tax_id,
        address=payload.address,
    )
    db.add(store)
    await db.flush()

    one_time_password = generate_secret(12)
    owner = User(
        tenant_id=tenant.id,
        username=payload.owner_username,
        password_hash=hash_password(one_time_password),
        display_name=payload.contact_name,
        email=payload.contact_email.lower(),
        role="tenant_owner",
        is_active=True,
        must_change_password=True,
    )
    db.add(owner)

    sub = TenantSubscription(
        tenant_id=tenant.id,
        plan_id=plan.id,
        status="active",
        started_at=_now(),
    )
    db.add(sub)

    seeded_products = 0
    seeded_promotions = 0
    cat_map: dict[str, Category] = {}
    if payload.seed_default_products or payload.seed_default_promotions:
        cat_map, seeded_products = await _seed_default_catalog(db, tenant.id)
    if payload.seed_default_promotions:
        if not cat_map:
            cat_map, _ = await _seed_default_catalog(db, tenant.id)
        seeded_promotions = await _seed_default_promotions(db, tenant.id, cat_map)

    await audit(
        db,
        user,
        action="tenant_direct_create",
        resource_type="tenant",
        resource_id=tenant.id,
        request=request,
        extra={
            "tenant_code": tenant.code,
            "plan_code": plan.code,
            "seed_default_products": payload.seed_default_products,
            "seed_default_promotions": payload.seed_default_promotions,
            "seeded_products": seeded_products,
            "seeded_promotions": seeded_promotions,
        },
        flush=False,
    )
    await db.commit()

    return TenantDirectCreateResponse(
        tenant_id=tenant.id,
        tenant_code=tenant.code,
        owner_username=owner.username,
        one_time_password=one_time_password,
    )


@router.get("/tenants/{tenant_id}/modules", response_model=TenantModulesRead)
async def get_tenant_modules_endpoint(
    tenant_id: str, db: DbSession, _: PlatformSuperDep
):
    mods = await get_tenant_modules(db, tenant_id)
    return TenantModulesRead(**mods)


@router.patch("/tenants/{tenant_id}/modules", response_model=TenantModulesRead)
async def update_tenant_modules(
    tenant_id: str,
    payload: TenantModulesUpdate,
    request: Request,
    db: DbSession,
    user: PlatformSuperDep,
):
    t = await db.get(Tenant, tenant_id)
    if not t:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    t.settings = apply_modules_patch(t.settings, payload.model_dump(exclude_unset=True))
    await audit(
        db,
        user,
        action="tenant_modules_update",
        resource_type="tenant",
        resource_id=tenant_id,
        request=request,
        flush=False,
    )
    await db.commit()
    mods = await get_tenant_modules(db, tenant_id)
    return TenantModulesRead(**mods)


# ---------------------------------------------------------------------------
# Application review
# ---------------------------------------------------------------------------

@router.get("/applications", response_model=list[TenantApplicationRead])
async def list_applications(
    db: DbSession,
    _: PlatformSuperDep,
    status_filter: str | None = Query(default=None, alias="status"),
    limit: int = Query(50, le=200),
):
    stmt = select(TenantApplication)
    if status_filter:
        stmt = stmt.where(TenantApplication.status == status_filter)
    stmt = stmt.order_by(TenantApplication.created_at.desc()).limit(limit)
    rows = (await db.execute(stmt)).scalars().all()
    return [_app_to_read(a) for a in rows]


@router.get("/applications/{aid}", response_model=TenantApplicationRead)
async def get_application(aid: str, db: DbSession, _: PlatformSuperDep):
    app = await db.get(TenantApplication, aid)
    if not app:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return _app_to_read(app)


@router.post("/applications/{aid}/approve", response_model=TenantApplicationRead)
async def approve_application(
    aid: str,
    payload: TenantApplicationApprove,
    request: Request,
    db: DbSession,
    user: PlatformSuperDep,
):
    """Provision a tenant from an application:

    1. Email must be verified.
    2. Build a ``Tenant`` row with the supplied plan.
    3. Build a default ``Store`` (using ``proposed_subdomain`` as code).
    4. Build the owner ``User`` with a one-time password mailed to them.
    5. Activate the subscription record.
    """
    app = await db.get(TenantApplication, aid)
    if not app:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if app.status not in ("email_verified",):
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "application must be in email_verified state to approve",
        )

    plan = (
        await db.execute(
            select(SubscriptionPlan).where(SubscriptionPlan.code == payload.plan_code)
        )
    ).scalar_one_or_none()
    if not plan:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "unknown plan_code")

    tenant_code = (
        payload.tenant_code or app.proposed_subdomain or generate_secret(8).lower()[:12]
    ).lower()
    if (await db.execute(select(Tenant).where(Tenant.code == tenant_code))).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "tenant code already in use")

    tenant = Tenant(
        code=tenant_code,
        name=app.company_name,
        contact_email=app.contact_email,
        contact_phone=app.contact_phone,
        tax_id=app.tax_id,
        status="active",
        plan_code=plan.code,
    )
    db.add(tenant)
    await db.flush()

    # Default first store (the owner can rename / add more later).
    store = Store(
        tenant_id=tenant.id,
        code="MAIN",
        name=app.company_name,
        tax_id=app.tax_id,
        address=app.address,
    )
    db.add(store)
    await db.flush()

    # Owner user with a temp password and forced rotation on first login.
    one_time_password = generate_secret(9)
    owner = User(
        tenant_id=tenant.id,
        username=payload.owner_username,
        password_hash=hash_password(one_time_password),
        display_name=app.contact_name,
        email=app.contact_email,
        role="tenant_owner",
        is_active=True,
        must_change_password=True,
    )
    db.add(owner)

    sub = TenantSubscription(
        tenant_id=tenant.id,
        plan_id=plan.id,
        status="active",
        started_at=_now(),
    )
    db.add(sub)

    app.status = "provisioned"
    app.reviewed_at = _now()
    app.reviewed_by_user_id = user.user_id
    app.provisioned_tenant_id = tenant.id

    await audit(db, user, action="application_approve", resource_type="tenant_application",
                resource_id=aid, request=request,
                extra={"tenant_id": tenant.id, "plan_code": plan.code}, flush=False)
    await db.commit()

    await send_email(
        to=app.contact_email,
        subject=f"歡迎加入 POS 平台 — {app.company_name}",
        body=(
            f"您的店家已開通完成。\n\n"
            f"租戶代號 (tenant_code): {tenant.code}\n"
            f"預設店面代號: MAIN\n"
            f"管理員帳號: {owner.username}\n"
            f"一次性密碼: {one_time_password}\n\n"
            f"請於首次登入後立即修改密碼。"
        ),
    )

    return _app_to_read(app)


@router.post("/applications/{aid}/reject", response_model=TenantApplicationRead)
async def reject_application(
    aid: str,
    payload: TenantApplicationReject,
    request: Request,
    db: DbSession,
    user: PlatformSuperDep,
):
    app = await db.get(TenantApplication, aid)
    if not app:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if app.status in ("rejected", "provisioned"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"already {app.status}")
    app.status = "rejected"
    app.reject_reason = payload.reason
    app.reviewed_at = _now()
    app.reviewed_by_user_id = user.user_id
    await audit(db, user, action="application_reject", resource_type="tenant_application",
                resource_id=aid, request=request,
                extra={"reason": payload.reason}, flush=False)
    await db.commit()
    await send_email(
        to=app.contact_email,
        subject="您的 POS 平台店家申請結果",
        body=(
            f"很遺憾通知您，本次申請未通過審核。\n\n"
            f"原因：{payload.reason}\n"
            f"您可以調整資料後再次申請。"
        ),
    )
    return _app_to_read(app)


# ---------------------------------------------------------------------------
# Subscription plans
# ---------------------------------------------------------------------------

@router.get("/plans", response_model=list[SubscriptionPlanRead])
async def list_plans(db: DbSession, _: PlatformSuperDep):
    rows = (
        await db.execute(
            select(SubscriptionPlan)
            .where(SubscriptionPlan.is_active.is_(True))
            .order_by(SubscriptionPlan.price_cents)
        )
    ).scalars().all()
    return rows


# ---------------------------------------------------------------------------
# Marketplace listing review
# ---------------------------------------------------------------------------

@router.get("/marketplace/applications")
async def list_marketplace_applications(
    db: DbSession,
    _: PlatformSuperDep,
    status_filter: str = Query(default="pending"),
):
    from ...models import MarketplaceListing
    from .marketplace_admin import _to_read

    stmt = select(MarketplaceListing).where(MarketplaceListing.status == status_filter)
    stmt = stmt.order_by(MarketplaceListing.submitted_at.desc().nullslast())
    rows = (await db.execute(stmt)).scalars().all()
    return [_to_read(r) for r in rows]


@router.post("/marketplace/applications/{listing_id}/approve")
async def approve_marketplace_listing(
    listing_id: str,
    request: Request,
    db: DbSession,
    user: PlatformSuperDep,
):
    from ...models import MarketplaceListing
    from .marketplace_admin import _to_read

    row = await db.get(MarketplaceListing, listing_id)
    if not row:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if row.status != "pending":
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot approve from status={row.status}")
    row.status = "approved"
    row.approved_at = _now()
    row.approved_by_user_id = user.user_id
    # Auto-enroll the tenant into the platform marketplace alliance so customers
    # get a single unified cross-store member identity.
    from ...services.marketplace_member import ensure_tenant_in_marketplace_alliance

    await ensure_tenant_in_marketplace_alliance(db, row.tenant_id)
    await audit(
        db,
        user,
        action="marketplace_listing_approve",
        resource_type="marketplace_listing",
        resource_id=listing_id,
        request=request,
        flush=False,
    )
    await db.commit()
    await db.refresh(row)
    return _to_read(row)


@router.post("/maintenance/loyalty")
async def run_loyalty_maintenance(db: DbSession, _: PlatformSuperDep):
    """Run scheduled loyalty jobs: expire stale points + grant birthday bonuses.

    Intended to be hit by a daily cron / scheduled task.
    """
    from ...services.loyalty_maintenance import run_birthday_rewards, run_point_expiry

    expired = await run_point_expiry(db)
    birthdays = await run_birthday_rewards(db)
    return {"expired_points_entries": expired, "birthday_rewards": birthdays}


@router.post("/marketplace/applications/{listing_id}/suspend")
async def suspend_marketplace_listing(
    listing_id: str,
    request: Request,
    db: DbSession,
    user: PlatformSuperDep,
):
    from ...models import MarketplaceListing
    from .marketplace_admin import _to_read

    row = await db.get(MarketplaceListing, listing_id)
    if not row:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    row.status = "suspended"
    await audit(
        db,
        user,
        action="marketplace_listing_suspend",
        resource_type="marketplace_listing",
        resource_id=listing_id,
        request=request,
        flush=False,
    )
    await db.commit()
    await db.refresh(row)
    return _to_read(row)
