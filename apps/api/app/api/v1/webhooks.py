"""Webhook subscription management (Pro+)."""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import DbSession, StoreAdminDep, TenantScope, ensure_same_tenant
from ...core.usage import assert_plan_feature
from ...models import WebhookSubscription
from ...schemas._base import ORMModel

router = APIRouter(prefix="/webhooks", tags=["webhooks"])

ALLOWED_EVENTS = [
    "member.created",
    "points.earned",
    "level.upgraded",
    "order.paid",
]


class WebhookSubscriptionRead(ORMModel):
    id: str
    tenant_id: str
    url: str
    events: list
    is_active: bool


class WebhookSubscriptionCreate(BaseModel):
    url: str = Field(max_length=512)
    secret: str | None = Field(default=None, max_length=128)
    events: list[str] = Field(default_factory=list)


class WebhookSubscriptionUpdate(BaseModel):
    url: str | None = Field(default=None, max_length=512)
    secret: str | None = None
    events: list[str] | None = None
    is_active: bool | None = None


@router.get("", response_model=list[WebhookSubscriptionRead])
async def list_webhooks(db: DbSession, scope: TenantScope):
    await assert_plan_feature(db, scope.tenant_id, "webhooks")
    rows = (
        await db.execute(
            select(WebhookSubscription).where(WebhookSubscription.tenant_id == scope.tenant_id)
        )
    ).scalars().all()
    return rows


@router.post("", response_model=WebhookSubscriptionRead, status_code=201)
async def create_webhook(payload: WebhookSubscriptionCreate, db: DbSession, scope: StoreAdminDep):
    await assert_plan_feature(db, scope.tenant_id, "webhooks")
    for ev in payload.events:
        if ev not in ALLOWED_EVENTS:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"unknown event: {ev}")
    sub = WebhookSubscription(
        tenant_id=scope.tenant_id,
        url=payload.url,
        secret=payload.secret,
        events=payload.events,
    )
    db.add(sub)
    await audit(db, scope, action="webhook_create", resource_type="webhook", flush=False)
    await db.commit()
    await db.refresh(sub)
    return sub


@router.patch("/{wid}", response_model=WebhookSubscriptionRead)
async def update_webhook(wid: str, payload: WebhookSubscriptionUpdate, db: DbSession, scope: StoreAdminDep):
    await assert_plan_feature(db, scope.tenant_id, "webhooks")
    sub = await db.get(WebhookSubscription, wid)
    if not sub:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, sub)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(sub, k, v)
    await db.commit()
    await db.refresh(sub)
    return sub


@router.delete("/{wid}", status_code=204)
async def delete_webhook(wid: str, db: DbSession, scope: StoreAdminDep):
    sub = await db.get(WebhookSubscription, wid)
    if not sub:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, sub)
    await db.delete(sub)
    await db.commit()
