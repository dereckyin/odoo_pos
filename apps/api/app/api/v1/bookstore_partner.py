"""Server-to-server API for the TAAZE (讀冊) app's physical bookstore zone.

Only my_api calls this. It authenticates with a partner key (SHA-256 digest
configured on our side) from an allow-listed IP, and forwards the already
authenticated member as an opaque ``X-Customer-Ref``. The key is scoped to
one tenant, so it can never read another merchant's stores or orders.
"""
import hashlib
import hmac
import ipaddress
import re
from dataclasses import dataclass
from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from sqlalchemy import select

from ...core.audit import audit
from ...core.client_ip import request_client_ip
from ...core.config import get_settings
from ...core.deps import DbSession
from ...core.ratelimit import limiter
from ...models import BookstoreCheckout, Tenant
from ...schemas.bookstore import (
    BookstoreCategoryRead,
    BookstoreProductPage,
    BookstoreProductRead,
    BookstoreStoreRead,
    CheckoutCreate,
    CheckoutRead,
    DoorQrResolveRequest,
    DoorQrResolveResponse,
    PaymentStartRequest,
    PaymentStartResponse,
)
from ...services import bookstore_checkout as svc
from ...services.bookstore import (
    issue_presence_token,
    parse_door_qr,
    read_bookstore_settings,
    sign_token_until,
)
from ...services.tenant_modules import MODULE_PHYSICAL_BOOKSTORE, get_tenant_modules

router = APIRouter(prefix="/partner/bookstore", tags=["partner-bookstore"])

_CUSTOMER_REF = re.compile(r"^[A-Za-z0-9_\-]{8,64}$")


@dataclass
class PartnerContext:
    tenant_id: str
    customer_ref: str | None


def _client_ip(request: Request) -> str:
    return request_client_ip(request)


def _ip_allowed(ip: str, allowed: list[str]) -> bool:
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        return False
    for entry in allowed:
        try:
            if addr in ipaddress.ip_network(entry, strict=False):
                return True
        except ValueError:
            continue
    return False


async def partner_context(
    request: Request,
    db: DbSession,
    x_partner_key: Annotated[str | None, Header(alias="X-Partner-Key")] = None,
    x_customer_ref: Annotated[str | None, Header(alias="X-Customer-Ref")] = None,
) -> PartnerContext:
    s = get_settings()
    hashes = s.bookstore_partner_key_hashes
    if not hashes or not s.BOOKSTORE_PARTNER_TENANT_CODE:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    digest = hashlib.sha256((x_partner_key or "").encode("utf-8")).hexdigest()
    if not x_partner_key or not any(hmac.compare_digest(digest, h) for h in hashes):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid partner key")
    allowed = s.bookstore_allowed_ips
    if (allowed or s.is_production) and not _ip_allowed(_client_ip(request), allowed):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "source not allowed")

    tenant = (
        await db.execute(select(Tenant).where(Tenant.code == s.BOOKSTORE_PARTNER_TENANT_CODE))
    ).scalar_one_or_none()
    if tenant is None or tenant.status not in ("active", "trial"):
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    mods = await get_tenant_modules(db, tenant.id)
    if not mods.get(MODULE_PHYSICAL_BOOKSTORE):
        raise HTTPException(status.HTTP_404_NOT_FOUND)

    customer_ref = None
    if x_customer_ref is not None:
        if not _CUSTOMER_REF.match(x_customer_ref):
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid customer ref")
        customer_ref = x_customer_ref
    return PartnerContext(tenant_id=tenant.id, customer_ref=customer_ref)


Partner = Annotated[PartnerContext, Depends(partner_context)]


def _customer(ctx: PartnerContext) -> str:
    if not ctx.customer_ref:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "customer ref required")
    return ctx.customer_ref


def _customer_key(request: Request) -> str:
    return "bookstore-customer:" + request.headers.get("x-customer-ref", "anonymous")


per_customer = lambda limit: limiter.limit(limit, key_func=_customer_key)  # noqa: E731


@router.get("/stores", response_model=list[BookstoreStoreRead])
async def list_stores(db: DbSession, ctx: Partner):
    return [svc.store_read(s) for s in await svc.list_bookstores(db, ctx.tenant_id)]


@router.get("/stores/{store_id}", response_model=BookstoreStoreRead)
async def get_store(store_id: str, db: DbSession, ctx: Partner):
    return svc.store_read(await svc.load_bookstore(db, ctx.tenant_id, store_id))


@router.post("/door-qr/resolve", response_model=DoorQrResolveResponse)
@per_customer("20/minute")
async def resolve_door_qr(
    request: Request, payload: DoorQrResolveRequest, db: DbSession, ctx: Partner
):
    customer_ref = _customer(ctx)
    body = parse_door_qr(payload.content)
    if not body:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, {"code": "invalid_qr", "message": "這不是有效的書店 QR Code"}
        )
    store = await svc.load_bookstore(db, ctx.tenant_id, str(body.get("s", "")))
    if int(body.get("v", -1)) != read_bookstore_settings(store)["qr_version"]:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, {"code": "invalid_qr", "message": "這個 QR Code 已停用"}
        )
    token, expires = issue_presence_token(store.id, customer_ref)
    return DoorQrResolveResponse(
        store=svc.store_read(store), presence_token=token, presence_expires_at=expires
    )


@router.get("/stores/{store_id}/categories", response_model=list[BookstoreCategoryRead])
async def list_categories(store_id: str, db: DbSession, ctx: Partner):
    _customer(ctx)
    await svc.load_bookstore(db, ctx.tenant_id, store_id)
    rows = await svc.list_categories(db, ctx.tenant_id, store_id)
    return [BookstoreCategoryRead(id=i, name=n) for i, n in rows]


@router.get("/stores/{store_id}/products", response_model=BookstoreProductPage)
@per_customer("120/minute")
async def list_products(
    request: Request,
    store_id: str,
    db: DbSession,
    ctx: Partner,
    q: str | None = Query(None, max_length=64),
    category_id: str | None = Query(None, max_length=36),
    sort: str = Query("new", pattern="^(new|title)$"),
    page: int = Query(1, ge=1, le=500),
    page_size: int = Query(20, ge=1, le=50),
):
    _customer(ctx)
    await svc.load_bookstore(db, ctx.tenant_id, store_id)
    items, total = await svc.list_products(
        db,
        ctx.tenant_id,
        store_id,
        q=q,
        category_id=category_id,
        sort=sort,
        page=page,
        page_size=page_size,
    )
    return BookstoreProductPage(items=items, total=total, page=page, page_size=page_size)


@router.get("/stores/{store_id}/products/{product_id}", response_model=BookstoreProductRead)
async def get_product(store_id: str, product_id: str, db: DbSession, ctx: Partner):
    _customer(ctx)
    await svc.load_bookstore(db, ctx.tenant_id, store_id)
    return await svc.get_product(db, ctx.tenant_id, store_id, product_id)


@router.get("/stores/{store_id}/lookup", response_model=BookstoreProductRead)
@per_customer("60/minute")
async def lookup(
    request: Request,
    store_id: str,
    db: DbSession,
    ctx: Partner,
    code: str = Query(..., min_length=1, max_length=64),
):
    _customer(ctx)
    await svc.load_bookstore(db, ctx.tenant_id, store_id)
    return await svc.lookup_code(db, ctx.tenant_id, store_id, code)


@router.post("/checkouts", response_model=CheckoutRead, status_code=201)
@per_customer("10/minute")
async def create_checkout(request: Request, payload: CheckoutCreate, db: DbSession, ctx: Partner):
    customer_ref = _customer(ctx)
    checkout = await svc.create_checkout(db, ctx.tenant_id, customer_ref, payload)
    await audit(
        db,
        None,
        tenant_id=ctx.tenant_id,
        action="bookstore_checkout_create",
        resource_type="bookstore_checkout",
        resource_id=checkout.id,
        request=request,
        extra={"store_id": checkout.store_id, "total_cents": checkout.total_cents},
        flush=False,
    )
    await db.commit()
    return await svc.checkout_read(db, checkout)


@router.get("/checkouts", response_model=list[CheckoutRead])
async def list_checkouts(
    db: DbSession, ctx: Partner, limit: int = Query(20, ge=1, le=50)
):
    customer_ref = _customer(ctx)
    ids = (
        await db.execute(
            select(BookstoreCheckout.id)
            .where(
                BookstoreCheckout.tenant_id == ctx.tenant_id,
                BookstoreCheckout.customer_ref == customer_ref,
                BookstoreCheckout.status.in_(("paid", "refunded")),
            )
            .order_by(BookstoreCheckout.created_at.desc())
            .limit(limit)
        )
    ).scalars().all()
    out = []
    for cid in ids:
        out.append(await svc.checkout_read(db, await svc.load_checkout(db, cid)))
    return out


@router.get("/checkouts/{checkout_id}", response_model=CheckoutRead)
async def get_checkout(checkout_id: str, db: DbSession, ctx: Partner):
    checkout = await svc.get_customer_checkout(db, ctx.tenant_id, _customer(ctx), checkout_id)
    return await svc.checkout_read(db, checkout)


@router.post("/checkouts/{checkout_id}/cancel", response_model=CheckoutRead)
async def cancel_checkout(checkout_id: str, db: DbSession, ctx: Partner):
    checkout = await svc.get_customer_checkout(db, ctx.tenant_id, _customer(ctx), checkout_id)
    return await svc.checkout_read(db, await svc.cancel_checkout(db, checkout))


@router.post("/checkouts/{checkout_id}/cash", response_model=CheckoutRead)
@per_customer("10/minute")
async def choose_cash(request: Request, checkout_id: str, db: DbSession, ctx: Partner):
    checkout = await svc.get_customer_checkout(db, ctx.tenant_id, _customer(ctx), checkout_id)
    checkout = await svc.select_cash(db, checkout)
    await audit(
        db,
        None,
        tenant_id=ctx.tenant_id,
        action="bookstore_checkout_cash_select",
        resource_type="bookstore_checkout",
        resource_id=checkout.id,
        request=request,
        extra={"total_cents": checkout.total_cents, "discount_cents": checkout.discount_cents},
        flush=False,
    )
    await db.commit()
    return await svc.checkout_read(db, checkout)


@router.post("/checkouts/{checkout_id}/pay", response_model=PaymentStartResponse)
@per_customer("10/minute")
async def start_payment(
    request: Request,
    checkout_id: str,
    payload: PaymentStartRequest,
    db: DbSession,
    ctx: Partner,
):
    s = get_settings()
    checkout = await svc.get_customer_checkout(db, ctx.tenant_id, _customer(ctx), checkout_id)
    if checkout.status != "pending":
        raise HTTPException(
            status.HTTP_409_CONFLICT, {"code": "not_pending", "message": "這筆結帳已無法付款"}
        )
    if svc._aware(checkout.expires_at) < svc.utcnow():
        raise HTTPException(
            status.HTTP_409_CONFLICT, {"code": "expired", "message": "保留時間已過，請重新結帳"}
        )
    if checkout.payment_method == "cash":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            {"code": "cash_selected", "message": "這筆結帳已選擇現金付款，請至櫃台結帳"},
        )
    store = await svc.load_bookstore(db, ctx.tenant_id, checkout.store_id)
    if not read_bookstore_settings(store)["online_payment_enabled"]:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            {"code": "online_unavailable", "message": "線上付款準備中，請改用現金結帳"},
        )
    return_url = payload.return_url
    if return_url and not any(return_url.startswith(p) for p in s.bookstore_return_url_prefixes):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "return_url not allowed")

    claims = {"k": checkout.id}
    if return_url:
        claims["r"] = return_url
    expires_at = svc._aware(checkout.expires_at)
    token = sign_token_until("pay", claims, expires_at)
    base = (s.BOOKSTORE_PUBLIC_BASE_URL or str(request.base_url)).rstrip("/")
    return PaymentStartResponse(
        checkout_id=checkout.id,
        payment_url=f"{base}/public/bookstore/pay/{checkout.id}?t={token}",
        expires_at=expires_at,
    )
