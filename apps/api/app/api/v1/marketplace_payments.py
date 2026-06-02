"""Marketplace payment initiation and webhooks."""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.deps import DbSession
from ...core.ratelimit import per_ip
from ...integrations.payments.provider import get_payment_provider
from ...models import GuestOrder, MarketplaceListing, Store
from ...schemas.marketplace import PaymentInitiateResponse
from ...services.tenant_modules import assert_tenant_module, MODULE_MARKETPLACE
from .public_marketplace import _order_access_token

router = APIRouter(prefix="/public/marketplace/payments", tags=["public-marketplace-payments"])


@router.post("/{order_id}/initiate", response_model=PaymentInitiateResponse)
@per_ip("20/minute")
async def initiate_payment(
    request: Request,
    order_id: str,
    db: DbSession,
    access_token: str = Query(...),
    return_url: str = Query(...),
):
    g = (
        await db.execute(
            select(GuestOrder)
            .where(GuestOrder.id == order_id, GuestOrder.channel == "marketplace")
            .options(selectinload(GuestOrder.lines))
        )
    ).scalar_one_or_none()
    if not g or _order_access_token(g) != access_token:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    await assert_tenant_module(db, g.tenant_id, MODULE_MARKETPLACE)
    if g.payment_method != "online":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "order is not online payment")
    if g.payment_status == "paid":
        raise HTTPException(status.HTTP_409_CONFLICT, "already paid")

    listing = (
        await db.execute(select(MarketplaceListing).where(MarketplaceListing.store_id == g.store_id))
    ).scalar_one_or_none()
    store = await db.get(Store, g.store_id)
    name = listing.display_name if listing else (store.name if store else "Order")

    provider = get_payment_provider()
    base = str(request.base_url).rstrip("/")
    result = await provider.initiate(
        order_id=g.id,
        amount_cents=g.estimated_subtotal_cents,
        description=f"{name} 網路訂單",
        customer_name=g.customer_name or "",
        customer_phone=g.customer_phone or "",
        return_url=return_url,
        notify_url=f"{base}/public/marketplace/payments/webhook/ecpay",
    )
    if result.provider_ref:
        g.online_payment_ref = result.provider_ref
        await db.commit()
    return PaymentInitiateResponse(
        order_id=g.id,
        payment_url=result.payment_url,
        payment_form_html=result.payment_form_html,
        message=result.message,
    )


@router.post("/webhook/ecpay")
async def ecpay_webhook(request: Request, db: DbSession):
    form = await request.form()
    payload = dict(form)
    provider = get_payment_provider()
    verified = await provider.verify_webhook(payload)
    if not verified:
        return "0|FAIL"

    trade_no, provider_ref, amount_cents = verified
    g = (
        await db.execute(
            select(GuestOrder).where(
                GuestOrder.channel == "marketplace",
                GuestOrder.online_payment_ref == trade_no,
            )
        )
    ).scalar_one_or_none()
    if not g:
        g = await db.get(GuestOrder, trade_no)
    if not g:
        return "0|FAIL"
    if g.estimated_subtotal_cents != amount_cents:
        return "0|FAIL"

    g.payment_status = "paid"
    g.online_payment_ref = provider_ref
    if g.extras is None:
        g.extras = {}
    g.extras["paid_at"] = datetime.now(timezone.utc).isoformat()
    await db.commit()
    return "1|OK"
