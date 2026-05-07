from fastapi import APIRouter, HTTPException, status

from ...core.deps import CurrentUserDep, DbSession
from ...integrations.payment import (
    ChargeRequest,
    RefundRequest,
    driver_for,
    registered_drivers,
)
from ...models import Order, Payment

router = APIRouter(prefix="/payments", tags=["payments"])


@router.get("/drivers")
async def list_drivers(_: CurrentUserDep) -> list[dict]:
    return [{"name": name} for name in registered_drivers()]


@router.post("/charge")
async def charge(
    payload: dict, db: DbSession, _: CurrentUserDep
) -> dict:
    driver_name = payload["driver"]
    order_id = payload["order_id"]
    amount_cents = int(payload["amount_cents"])
    description = payload.get("description")
    return_url = payload.get("return_url")

    order = await db.get(Order, order_id)
    if not order:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "order not found")

    drv = driver_for(driver_name)
    res = await drv.charge(
        ChargeRequest(
            order_id=order_id,
            amount_cents=amount_cents,
            description=description,
            return_url=return_url,
        )
    )
    return {
        "gateway": res.gateway,
        "status": res.status,
        "gateway_ref": res.gateway_ref,
        "redirect_url": res.redirect_url,
        "qr_payload": res.qr_payload,
        "deep_link": res.deep_link,
        "raw": res.raw,
    }


@router.post("/refund")
async def refund(payload: dict, db: DbSession, _: CurrentUserDep) -> dict:
    payment_id = payload["payment_id"]
    amount_cents = int(payload["amount_cents"])

    payment = await db.get(Payment, payment_id)
    if not payment:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "payment not found")
    if not payment.gateway_ref:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "payment has no gateway_ref")

    drv = driver_for(payment.method.replace("credit_card", "newebpay"))
    res = await drv.refund(
        RefundRequest(
            payment_id=payment.id,
            gateway_ref=payment.gateway_ref,
            amount_cents=amount_cents,
            reason=payload.get("reason"),
        )
    )
    if res.status == "refunded":
        payment.status = "refunded"
        await db.commit()
    return {
        "gateway": res.gateway,
        "status": res.status,
        "gateway_ref": res.gateway_ref,
        "raw": res.raw,
    }


@router.post("/{driver}/confirm")
async def gateway_confirm(driver: str, payload: dict, db: DbSession, _: CurrentUserDep) -> dict:
    drv = driver_for(driver)
    gateway_ref = payload.pop("gateway_ref", "")
    res = await drv.confirm(gateway_ref, payload)
    if res.status == "captured":
        payment = (
            await db.execute(
                _select_payment_by_ref(res.gateway_ref or gateway_ref)
            )
        ).scalar_one_or_none()
        if payment:
            payment.status = "captured"
            await db.commit()
    return {
        "gateway": res.gateway,
        "status": res.status,
        "gateway_ref": res.gateway_ref,
        "raw": res.raw,
    }


def _select_payment_by_ref(ref: str):
    from sqlalchemy import select  # local import to avoid cycle
    return select(Payment).where(Payment.gateway_ref == ref)
