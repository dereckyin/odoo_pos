"""Staff / admin side of physical bookstore stores: exit-pass verification
at the door, app checkout list, refunds and door QR management."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import DbSession, NonKitchenScope, StoreAdminDep, TenantAdminDep, ensure_same_tenant
from ...models import BookstoreCheckout
from ...schemas.bookstore import (
    BookstoreSettingsUpdate,
    CashConfirmRequest,
    CashLookupRequest,
    CashLookupResponse,
    DoorQrRead,
    ExitVerifyRequest,
    ExitVerifyResponse,
    RefundRequest,
    RefundResponse,
    StaffCheckoutRead,
)
from ...schemas.store import StoreRead
from ...services import bookstore_checkout as svc
from ...services.bookstore import issue_door_qr, read_bookstore_settings, write_bookstore_settings
from ...services.taaze_settle import notify_paid
from ...services.tenant_modules import require_physical_bookstore

router = APIRouter(
    prefix="/bookstore",
    tags=["bookstore"],
    dependencies=[Depends(require_physical_bookstore)],
)


def _resolve_store_id(scope, requested: str | None) -> str:
    if scope.store_id and not scope.is_tenant_admin:
        if requested and requested != scope.store_id:
            raise HTTPException(status.HTTP_404_NOT_FOUND)
        return scope.store_id
    store_id = requested or scope.store_id
    if not store_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "store_id required")
    return store_id


@router.post("/exit-pass/verify", response_model=ExitVerifyResponse)
async def verify_exit_pass(
    payload: ExitVerifyRequest, request: Request, db: DbSession, scope: NonKitchenScope
):
    store_id = _resolve_store_id(scope, payload.store_id)
    store = await svc.load_bookstore(db, scope.tenant_id, store_id)
    result = await svc.verify_exit(
        db,
        tenant_id=scope.tenant_id,
        store_id=store.id,
        user_id=scope.user_id,
        token=payload.token,
        code=payload.code,
    )
    await audit(
        db,
        scope,
        action="bookstore_exit_verify",
        resource_type="bookstore_checkout",
        resource_id=result.checkout_id,
        request=request,
        extra={"result": result.result},
        flush=False,
    )
    await db.commit()
    return result


@router.post("/cash/lookup", response_model=CashLookupResponse)
async def lookup_cash(payload: CashLookupRequest, db: DbSession, scope: NonKitchenScope):
    store_id = _resolve_store_id(scope, payload.store_id)
    store = await svc.load_bookstore(db, scope.tenant_id, store_id)
    checkout = await svc.find_cash_checkout(
        db, tenant_id=scope.tenant_id, store_id=store.id, token=payload.token, code=payload.code
    )
    if checkout is None:
        return CashLookupResponse(result="invalid")
    read = await svc.staff_checkout_read(db, checkout)
    if checkout.status == "paid":
        return CashLookupResponse(result="already_paid", checkout=read)
    if checkout.status not in ("pending", "expired"):
        return CashLookupResponse(result="closed", checkout=read)
    return CashLookupResponse(result="found", checkout=read)


@router.post("/checkouts/{checkout_id}/cash-confirm", response_model=StaffCheckoutRead)
async def confirm_cash(
    checkout_id: str,
    payload: CashConfirmRequest,
    request: Request,
    db: DbSession,
    scope: NonKitchenScope,
):
    checkout = await svc.load_checkout(db, checkout_id)
    if checkout is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, checkout)
    _resolve_store_id(scope, checkout.store_id)
    checkout = await svc.confirm_cash(
        db, checkout, user_id=scope.user_id, expected_total_cents=payload.expected_total_cents
    )
    await audit(
        db,
        scope,
        action="bookstore_cash_confirm",
        resource_type="bookstore_checkout",
        resource_id=checkout.id,
        request=request,
        extra={"total_cents": checkout.total_cents, "discount_cents": checkout.discount_cents},
        flush=False,
    )
    await db.commit()
    await svc.issue_invoice_for_checkout(db, checkout.id)
    await notify_paid(checkout.id, checkout.total_cents)
    return await svc.staff_checkout_read(db, await svc.load_checkout(db, checkout.id))


@router.get("/checkouts", response_model=list[StaffCheckoutRead])
async def list_checkouts(
    db: DbSession,
    scope: NonKitchenScope,
    store_id: str | None = None,
    status_filter: str | None = Query(None, alias="status", pattern="^(pending|paid|expired|cancelled|refunded)$"),
    limit: int = Query(50, ge=1, le=200),
):
    sid = _resolve_store_id(scope, store_id)
    await svc.load_bookstore(db, scope.tenant_id, sid)
    stmt = select(BookstoreCheckout.id).where(
        BookstoreCheckout.tenant_id == scope.tenant_id, BookstoreCheckout.store_id == sid
    )
    if status_filter:
        stmt = stmt.where(BookstoreCheckout.status == status_filter)
    ids = (
        await db.execute(stmt.order_by(BookstoreCheckout.created_at.desc()).limit(limit))
    ).scalars().all()
    return [await svc.staff_checkout_read(db, await svc.load_checkout(db, cid)) for cid in ids]


@router.post("/checkouts/{checkout_id}/refund", response_model=RefundResponse)
async def refund_checkout(
    checkout_id: str,
    payload: RefundRequest,
    request: Request,
    db: DbSession,
    scope: StoreAdminDep,
):
    checkout = await svc.load_checkout(db, checkout_id)
    if checkout is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, checkout)
    _resolve_store_id(scope, checkout.store_id)
    voided = await svc.refund_checkout(db, checkout, user_id=scope.user_id, reason=payload.reason)
    await audit(
        db,
        scope,
        action="bookstore_checkout_refund",
        resource_type="bookstore_checkout",
        resource_id=checkout_id,
        request=request,
        extra={"invoice_voided": voided},
        flush=False,
    )
    await db.commit()
    fresh = await svc.load_checkout(db, checkout_id)
    if fresh.payment_gateway == "cash":
        message = f"已退貨並回補庫存。請退還顧客現金 NT$ {fresh.total_cents}。"
    else:
        message = "已退貨並回補庫存。刷卡款項請至金流後台辦理退刷。"
    return RefundResponse(
        checkout=await svc.staff_checkout_read(db, fresh),
        invoice_voided=voided,
        gateway_refund="manual",
        message=message,
    )


def _store_door_qr(store, content: str, expires) -> DoorQrRead:
    write_bookstore_settings(
        store,
        {"door_qr_content": content, "door_qr_expires_at": expires.isoformat()},
    )
    return DoorQrRead(content=content, expires_at=expires)


@router.get("/stores/{store_id}/door-qr", response_model=DoorQrRead)
async def get_door_qr(store_id: str, db: DbSession, scope: StoreAdminDep):
    """Return the currently posted door QR without rotating it."""
    _resolve_store_id(scope, store_id)
    store = await svc.load_bookstore(db, scope.tenant_id, store_id)
    cfg = read_bookstore_settings(store)
    content = cfg.get("door_qr_content")
    expires_raw = cfg.get("door_qr_expires_at")
    if content and expires_raw:
        expires = (
            expires_raw
            if isinstance(expires_raw, datetime)
            else datetime.fromisoformat(str(expires_raw).replace("Z", "+00:00"))
        )
        return DoorQrRead(content=content, expires_at=expires)
    if int(cfg.get("qr_version") or 0) > 0:
        content, expires = issue_door_qr(store)
        read = _store_door_qr(store, content, expires)
        await db.commit()
        return read
    raise HTTPException(status.HTTP_404_NOT_FOUND)


@router.post("/stores/{store_id}/door-qr", response_model=DoorQrRead)
async def rotate_door_qr(store_id: str, request: Request, db: DbSession, scope: TenantAdminDep):
    store = await svc.load_bookstore(db, scope.tenant_id, store_id)
    write_bookstore_settings(store, {"qr_version": read_bookstore_settings(store)["qr_version"] + 1})
    content, expires = issue_door_qr(store)
    read = _store_door_qr(store, content, expires)
    await audit(
        db, scope, action="bookstore_door_qr_rotate", resource_type="store",
        resource_id=store.id, request=request, flush=False,
    )
    await db.commit()
    return read


@router.patch("/stores/{store_id}/settings", response_model=StoreRead)
async def update_settings(
    store_id: str, payload: BookstoreSettingsUpdate, db: DbSession, scope: StoreAdminDep
):
    _resolve_store_id(scope, store_id)
    store = await svc.load_bookstore(db, scope.tenant_id, store_id)
    write_bookstore_settings(store, payload.model_dump(exclude_unset=True))
    await audit(db, scope, action="bookstore_settings_update", resource_type="store",
                resource_id=store.id, flush=False)
    await db.commit()
    await db.refresh(store)
    return store
