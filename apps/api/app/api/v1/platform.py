"""Platform-super-admin endpoints.

Used by the SaaS operator to review applications, suspend tenants, and
manage subscription plans. None of these endpoints should be exposed to
tenant users — guarded by ``PlatformSuperDep``.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, Request, status
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    PlatformSuperDep,
    current_user,
)
from ...core.notify import send_email
from ...core.security import generate_secret, hash_password
from ...models import (
    Store,
    SubscriptionPlan,
    Tenant,
    TenantApplication,
    TenantSubscription,
    User,
)
from ...schemas.auth import (
    TenantApplicationApprove,
    TenantApplicationRead,
    TenantApplicationReject,
)
from ...schemas.tenant import (
    SubscriptionPlanRead,
    TenantRead,
    TenantUpdate,
)
from .tenant_apply import _to_read as _app_to_read

router = APIRouter(prefix="/platform", tags=["platform"])


def _now() -> datetime:
    return datetime.now(timezone.utc)


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
