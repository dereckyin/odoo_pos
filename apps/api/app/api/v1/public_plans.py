"""Read-only public list of available subscription plans (so the signup
form can render them)."""
from fastapi import APIRouter, Request
from sqlalchemy import select

from ...core.deps import DbSession
from ...core.ratelimit import per_ip
from ...models import SubscriptionPlan
from ...schemas.tenant import SubscriptionPlanRead

router = APIRouter(prefix="/public", tags=["public"])


@router.get("/plans", response_model=list[SubscriptionPlanRead])
@per_ip("60/minute")
async def list_public_plans(request: Request, db: DbSession):
    rows = (
        await db.execute(
            select(SubscriptionPlan)
            .where(SubscriptionPlan.is_active.is_(True))
            .order_by(SubscriptionPlan.price_cents)
        )
    ).scalars().all()
    return rows
