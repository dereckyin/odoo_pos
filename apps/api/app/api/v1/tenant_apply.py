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
    TenantApplyVerifyRequest,
)

router = APIRouter(prefix="/public/applications", tags=["public-applications"])


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _client_ip(request: Request) -> str | None:
    if "x-forwarded-for" in request.headers:
        return request.headers["x-forwarded-for"].split(",")[0].strip()
    return request.client.host if request.client else None


@router.post("", response_model=TenantApplyResponse, status_code=201)
@per_ip("5/minute")
async def submit_application(
    request: Request, payload: TenantApplyRequest, db: DbSession
) -> TenantApplyResponse:
    if not await verify_captcha(payload.captcha_token, _client_ip(request)):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "captcha verification failed")

    email = payload.contact_email.lower()

    # Reject if any active application exists for the same email or
    # subdomain (avoids parallel duplicates polluting the review queue).
    dup = (
        await db.execute(
            select(TenantApplication).where(
                TenantApplication.contact_email == email,
                TenantApplication.status.in_(
                    ("pending", "email_verified", "approved")
                ),
            )
        )
    ).scalar_one_or_none()
    if dup:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "an application from this email is already in review",
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
