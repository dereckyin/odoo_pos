"""Public store-signup application flow + email verification.

Layered defences against spam / abuse:

1. ``slowapi`` IP-based rate limit (``per_ip``) on every public endpoint.
2. Per-email rate limit (composite key) on ``/apply`` so one IP can't
   spam through hundreds of distinct addresses.
3. Optional CAPTCHA (hCaptcha / Cloudflare Turnstile) — mandatory once
   ``CAPTCHA_PROVIDER`` is configured.
4. Strict Pydantic validation (Email format, subdomain regex, etc.).
5. OTP must be verified before the application moves to ``email_verified``
   and is visible to platform reviewers.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Request, status
from sqlalchemy import select

from ...core.captcha import verify_captcha
from ...core.deps import DbSession
from ...core.otp import issue_email_otp, verify_email_otp
from ...core.ratelimit import per_ip
from ...models import Tenant, TenantApplication
from ...schemas.auth import (
    TenantApplicationRead,
    TenantApplyRequest,
    TenantApplyResponse,
    TenantApplyResumeRequest,
    TenantApplyResumeResponse,
    TenantApplyVerifyRequest,
)

router = APIRouter(prefix="/public/applications", tags=["public-applications"])


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _client_ip(request: Request) -> str | None:
    if "x-forwarded-for" in request.headers:
        return request.headers["x-forwarded-for"].split(",")[0].strip()
    return request.client.host if request.client else None


async def _active_application_for_email(db: DbSession, email: str) -> TenantApplication | None:
    """Latest application that can still resume OTP or is awaiting review."""
    return (
        await db.execute(
            select(TenantApplication)
            .where(
                TenantApplication.contact_email == email,
                TenantApplication.status.in_(("pending", "email_verified")),
            )
            .order_by(TenantApplication.created_at.desc())
            .limit(1)
        )
    ).scalar_one_or_none()


async def _blocking_application_for_email(db: DbSession, email: str) -> TenantApplication | None:
    """Latest application that prevents submitting a new one with the same email."""
    return (
        await db.execute(
            select(TenantApplication)
            .where(
                TenantApplication.contact_email == email,
                TenantApplication.status.in_(
                    ("pending", "email_verified", "approved", "provisioned")
                ),
            )
            .order_by(TenantApplication.created_at.desc())
            .limit(1)
        )
    ).scalar_one_or_none()


@router.post("", response_model=TenantApplyResponse, status_code=201)
@per_ip("5/minute")
async def submit_application(
    request: Request, payload: TenantApplyRequest, db: DbSession
) -> TenantApplyResponse:
    if not await verify_captcha(payload.captcha_token, _client_ip(request)):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "captcha verification failed")

    email = payload.contact_email.lower()

    dup = await _blocking_application_for_email(db, email)
    if dup:
        if dup.status == "pending":
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                detail={
                    "code": "application_exists",
                    "application_id": dup.id,
                    "status": dup.status,
                    "contact_email": dup.contact_email,
                    "company_name": dup.company_name,
                    "message": "此信箱已有申請尚未完成驗證，請繼續輸入驗證碼。",
                },
            )
        if dup.status == "email_verified":
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                detail={
                    "code": "application_verified",
                    "application_id": dup.id,
                    "status": dup.status,
                    "contact_email": dup.contact_email,
                    "company_name": dup.company_name,
                    "message": "此信箱的申請已完成驗證，請等待平台審核。",
                },
            )
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            detail={
                "code": "application_provisioned",
                "application_id": dup.id,
                "status": dup.status,
                "message": "此信箱的申請已通過審核，請使用寄送的帳號登入。",
            },
        )
    if payload.proposed_subdomain:
        sub_dup = (
            await db.execute(
                select(TenantApplication).where(
                    TenantApplication.proposed_subdomain == payload.proposed_subdomain,
                    TenantApplication.status.in_(("pending", "email_verified", "approved")),
                )
            )
        ).scalar_one_or_none()
        if sub_dup:
            raise HTTPException(status.HTTP_409_CONFLICT, "subdomain already requested")
        existing_tenant = (
            await db.execute(
                select(Tenant).where(Tenant.code == payload.proposed_subdomain)
            )
        ).scalar_one_or_none()
        if existing_tenant:
            raise HTTPException(status.HTTP_409_CONFLICT, "subdomain already in use")

    app = TenantApplication(
        company_name=payload.company_name,
        contact_name=payload.contact_name,
        contact_email=email,
        contact_phone=payload.contact_phone,
        tax_id=payload.tax_id,
        plan_code=payload.plan_code,
        proposed_subdomain=payload.proposed_subdomain,
        address=payload.address,
        note=payload.note,
        status="pending",
        captcha_passed=bool(payload.captcha_token),
        submitter_ip=_client_ip(request),
    )
    db.add(app)
    await db.flush()
    await issue_email_otp(db, email=email, purpose="signup", related_id=app.id)
    await db.commit()

    return TenantApplyResponse(
        application_id=app.id,
        contact_email=email,
        status=app.status,
    )


@router.post("/verify", response_model=TenantApplicationRead)
@per_ip("10/minute")
async def verify_application(
    request: Request, payload: TenantApplyVerifyRequest, db: DbSession
) -> TenantApplicationRead:
    app = await db.get(TenantApplication, payload.application_id)
    if not app:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "application not found")
    if app.status not in ("pending", "email_verified"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot verify in status={app.status}")
    ok = await verify_email_otp(
        db,
        email=app.contact_email,
        purpose="signup",
        code=payload.code,
        related_id=app.id,
    )
    if not ok:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid or expired code")
    if app.status == "pending":
        app.status = "email_verified"
        app.email_verified_at = _now()
    await db.commit()
    return _to_read(app)


@router.post("/resume", response_model=TenantApplyResumeResponse)
@per_ip("10/minute")
async def resume_application(
    request: Request, payload: TenantApplyResumeRequest, db: DbSession
) -> TenantApplyResumeResponse:
    """Let applicants continue email verification after refresh or a new visit."""
    email = payload.contact_email.lower()
    app = await _active_application_for_email(db, email)
    if not app:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "找不到此信箱待驗證的申請，請重新填寫並送出。",
        )
    if app.status == "pending":
        await issue_email_otp(db, email=email, purpose="signup", related_id=app.id)
        await db.commit()
        msg = "已重新寄送驗證碼到您的信箱（若未收到，請向平台管理員索取）。"
    else:
        msg = "此申請已完成信箱驗證，請等待平台審核。"
    return TenantApplyResumeResponse(
        application_id=app.id,
        contact_email=app.contact_email,
        status=app.status,
        company_name=app.company_name,
        message=msg,
    )


@router.post("/{application_id}/resend-otp", status_code=204)
@per_ip("5/minute")
async def resend_application_otp(
    request: Request, application_id: str, db: DbSession
) -> None:
    app = await db.get(TenantApplication, application_id)
    if not app:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "application not found")
    if app.status != "pending":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "此申請不需要驗證碼，或已完成驗證",
        )
    await issue_email_otp(
        db, email=app.contact_email, purpose="signup", related_id=app.id
    )
    await db.commit()


@router.get("/{application_id}", response_model=TenantApplicationRead)
@per_ip("60/minute")
async def get_application(
    request: Request, application_id: str, db: DbSession
) -> TenantApplicationRead:
    """Public status check so the applicant can poll without logging in."""
    app = await db.get(TenantApplication, application_id)
    if not app:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return _to_read(app)


def _to_read(app: TenantApplication) -> TenantApplicationRead:
    return TenantApplicationRead(
        id=app.id,
        company_name=app.company_name,
        contact_name=app.contact_name,
        contact_email=app.contact_email,
        contact_phone=app.contact_phone,
        tax_id=app.tax_id,
        plan_code=app.plan_code,
        proposed_subdomain=app.proposed_subdomain,
        address=app.address,
        note=app.note,
        status=app.status,
        email_verified_at=app.email_verified_at.timestamp() if app.email_verified_at else None,
        reviewed_at=app.reviewed_at.timestamp() if app.reviewed_at else None,
        reject_reason=app.reject_reason,
        provisioned_tenant_id=app.provisioned_tenant_id,
    )
