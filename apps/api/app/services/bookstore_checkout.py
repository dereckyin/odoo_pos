"""Scan-and-go checkout for physical bookstore stores.

Prices, stock and payment state are decided here, never by the client:
the partner only sends (store, product, qty). Stock is reserved with a
conditional UPDATE so two buyers cannot both take the last copy.
"""
from __future__ import annotations

import logging
import re
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy import and_, case, func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..core.config import get_settings
from ..core.usage import assert_within_monthly_orders, bump_usage_counter
from ..integrations.invoice import InvoiceIssueRequest, InvoiceVoidRequest, tenant_invoice_driver_for
from ..integrations.invoice.base import InvoiceLine
from ..integrations.invoice.proof import extract_invoice_proof
from ..models import (
    BookDetail,
    BookstoreCheckout,
    BookstoreCheckoutLine,
    Category,
    InventoryLevel,
    InventoryMovement,
    Invoice,
    Order,
    OrderLine,
    Payment,
    Product,
    ProductBarcode,
    Refund,
    RefundLine,
    Store,
    TenantInvoiceSetting,
)
from ..schemas.bookstore import (
    BookstoreProductRead,
    BookstoreStoreRead,
    CashPaymentRead,
    CheckoutCreate,
    CheckoutLineRead,
    CheckoutRead,
    ExitPassRead,
    ExitVerifyResponse,
    StaffCheckoutRead,
)
from .bookstore import (
    STORE_KIND_BOOKSTORE,
    assert_presence,
    ensure_app_identity,
    read_bookstore_settings,
    sign_token_until,
    verify_token,
)
from .consignment_books import PRODUCT_KIND_CONSIGNMENT, calc_consignment_shares, get_consignment_settings
from .order_number import allocate_order_no

logger = logging.getLogger(__name__)

TRADE_PREFIX_LEN = 18
MAX_PAYMENT_ATTEMPTS = 20
_CODE_RE = re.compile(r"[^0-9A-Z]")


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _aware(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def _error(code: int, key: str, message: str) -> HTTPException:
    return HTTPException(code, {"code": key, "message": message})


def stock_status(available: int) -> str:
    if available <= 0:
        return "out_of_stock"
    if available == 1:
        return "last_one"
    return "in_stock"


def _available(level: InventoryLevel) -> int:
    return int(float(level.on_hand or 0) - float(level.reserved or 0))


def store_read(store: Store) -> BookstoreStoreRead:
    cfg = read_bookstore_settings(store)
    return BookstoreStoreRead(
        id=store.id,
        code=store.code,
        name=store.name,
        address=store.address,
        phone=store.phone,
        latitude=store.latitude,
        longitude=store.longitude,
        is_open=cfg["is_open"],
        cash_enabled=cfg["cash_enabled"],
        cash_price_pct=cfg["cash_price_pct"],
        online_payment_enabled=cfg["online_payment_enabled"],
    )


# --- stores ---------------------------------------------------------------


async def list_bookstores(db: AsyncSession, tenant_id: str) -> list[Store]:
    return list(
        (
            await db.execute(
                select(Store)
                .where(
                    Store.tenant_id == tenant_id,
                    Store.store_kind == STORE_KIND_BOOKSTORE,
                    Store.deleted_at.is_(None),
                )
                .order_by(Store.code)
            )
        ).scalars()
    )


async def load_bookstore(db: AsyncSession, tenant_id: str, store_id: str) -> Store:
    store = await db.get(Store, store_id)
    if (
        store is None
        or store.tenant_id != tenant_id
        or store.deleted_at is not None
        or store.store_kind != STORE_KIND_BOOKSTORE
    ):
        raise _error(status.HTTP_404_NOT_FOUND, "store_not_found", "找不到這家書店")
    return store


# --- catalog --------------------------------------------------------------


def _catalog_query(tenant_id: str, store_id: str):
    return (
        select(Product, BookDetail, InventoryLevel, Category.name)
        .join(BookDetail, BookDetail.product_id == Product.id)
        .join(
            InventoryLevel,
            and_(InventoryLevel.product_id == Product.id, InventoryLevel.store_id == store_id),
        )
        .outerjoin(Category, Category.id == Product.category_id)
        .where(
            Product.tenant_id == tenant_id,
            Product.deleted_at.is_(None),
            Product.is_active.is_(True),
        )
    )


def _product_read(row, *, detailed: bool = False) -> BookstoreProductRead:
    product, book, level, category_name = row
    available = _available(level)
    return BookstoreProductRead(
        id=product.id,
        name=product.name,
        author=book.author,
        publisher=book.publisher,
        isbn=book.isbn,
        image_url=product.image_url,
        description=product.description if detailed else None,
        category_id=product.category_id,
        category_name=category_name,
        price_cents=product.price_cents,
        list_price_cents=book.list_price_cents,
        stock_status=stock_status(available),
        max_qty=max(0, min(available, get_settings().BOOKSTORE_MAX_QTY_PER_LINE)),
    )


def _like(q: str) -> str:
    escaped = q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    return f"%{escaped}%"


async def list_products(
    db: AsyncSession,
    tenant_id: str,
    store_id: str,
    *,
    q: str | None,
    category_id: str | None,
    sort: str,
    page: int,
    page_size: int,
) -> tuple[list[BookstoreProductRead], int]:
    stmt = _catalog_query(tenant_id, store_id)
    if category_id:
        stmt = stmt.where(Product.category_id == category_id)
    if q:
        pattern = _like(q.strip()[:64])
        stmt = stmt.where(
            or_(
                Product.name.ilike(pattern, escape="\\"),
                BookDetail.author.ilike(pattern, escape="\\"),
                BookDetail.isbn.ilike(pattern, escape="\\"),
                BookDetail.barcode.ilike(pattern, escape="\\"),
            )
        )
    total = int(
        (await db.execute(select(func.count()).select_from(stmt.subquery()))).scalar_one()
    )
    if sort == "new":
        stmt = stmt.order_by(InventoryLevel.created_at.desc(), Product.name)
    else:
        stmt = stmt.order_by(Product.name)
    rows = (await db.execute(stmt.limit(page_size).offset((page - 1) * page_size))).all()
    return [_product_read(r) for r in rows], total


async def list_categories(db: AsyncSession, tenant_id: str, store_id: str) -> list[tuple[str, str]]:
    stmt = (
        select(Category.id, Category.name)
        .join(Product, Product.category_id == Category.id)
        .join(BookDetail, BookDetail.product_id == Product.id)
        .join(
            InventoryLevel,
            and_(InventoryLevel.product_id == Product.id, InventoryLevel.store_id == store_id),
        )
        .where(
            Product.tenant_id == tenant_id,
            Product.deleted_at.is_(None),
            Product.is_active.is_(True),
            Category.deleted_at.is_(None),
            (InventoryLevel.on_hand - InventoryLevel.reserved) > 0,
        )
        .group_by(Category.id, Category.name)
        .order_by(Category.name)
    )
    return [(r[0], r[1]) for r in (await db.execute(stmt)).all()]


async def get_product(db: AsyncSession, tenant_id: str, store_id: str, product_id: str) -> BookstoreProductRead:
    row = (
        await db.execute(_catalog_query(tenant_id, store_id).where(Product.id == product_id))
    ).first()
    if row is None:
        raise _error(status.HTTP_404_NOT_FOUND, "not_in_store", "這家店沒有這本書")
    return _product_read(row, detailed=True)


def normalize_code(code: str) -> str:
    return _CODE_RE.sub("", (code or "").upper())[:32]


async def lookup_code(db: AsyncSession, tenant_id: str, store_id: str, code: str) -> BookstoreProductRead:
    norm = normalize_code(code)
    if len(norm) < 8:
        raise _error(status.HTTP_404_NOT_FOUND, "not_in_store", "這家店沒有這本書")
    by_barcode = select(ProductBarcode.product_id).where(
        ProductBarcode.tenant_id == tenant_id, ProductBarcode.barcode == norm
    )
    by_book = select(BookDetail.product_id).where(
        BookDetail.tenant_id == tenant_id,
        or_(BookDetail.barcode == norm, func.replace(BookDetail.isbn, "-", "") == norm),
    )
    row = (
        await db.execute(
            _catalog_query(tenant_id, store_id)
            .where(or_(Product.id.in_(by_barcode), Product.id.in_(by_book)))
            .order_by((InventoryLevel.on_hand - InventoryLevel.reserved).desc())
            .limit(1)
        )
    ).first()
    if row is None:
        raise _error(status.HTTP_404_NOT_FOUND, "not_in_store", "這家店沒有這本書")
    return _product_read(row, detailed=True)


# --- reservations ---------------------------------------------------------


async def _reserve(db: AsyncSession, store_id: str, product_id: str, qty: int) -> bool:
    res = await db.execute(
        update(InventoryLevel)
        .where(
            InventoryLevel.store_id == store_id,
            InventoryLevel.product_id == product_id,
            (InventoryLevel.on_hand - InventoryLevel.reserved) >= qty,
        )
        .values(reserved=InventoryLevel.reserved + qty)
        .execution_options(synchronize_session=False)
    )
    return res.rowcount == 1


async def _unreserve(db: AsyncSession, store_id: str, product_id: str, qty: int) -> None:
    await db.execute(
        update(InventoryLevel)
        .where(InventoryLevel.store_id == store_id, InventoryLevel.product_id == product_id)
        .values(
            reserved=case(
                (InventoryLevel.reserved - qty < 0, 0),
                else_=InventoryLevel.reserved - qty,
            )
        )
        .execution_options(synchronize_session=False)
    )


async def _close_pending(db: AsyncSession, checkout_id: str, new_status: str, extra_where=None) -> bool:
    """Move a pending checkout to expired/cancelled and release its stock.
    Returns False when another request already changed its state."""
    stmt = update(BookstoreCheckout).where(
        BookstoreCheckout.id == checkout_id,
        BookstoreCheckout.status == "pending",
        BookstoreCheckout.reservation_active.is_(True),
    )
    if extra_where is not None:
        stmt = stmt.where(extra_where)
    res = await db.execute(
        stmt.values(status=new_status, reservation_active=False).execution_options(
            synchronize_session=False
        )
    )
    if res.rowcount != 1:
        return False
    checkout = (
        await db.execute(
            select(BookstoreCheckout)
            .where(BookstoreCheckout.id == checkout_id)
            .options(selectinload(BookstoreCheckout.lines))
            .execution_options(populate_existing=True)
        )
    ).scalar_one()
    for ln in checkout.lines:
        await _unreserve(db, checkout.store_id, ln.product_id, ln.qty)
    return True


async def release_expired(db: AsyncSession, tenant_id: str) -> int:
    now = utcnow()
    ids = (
        await db.execute(
            select(BookstoreCheckout.id).where(
                BookstoreCheckout.tenant_id == tenant_id,
                BookstoreCheckout.status == "pending",
                BookstoreCheckout.expires_at < now,
            )
        )
    ).scalars().all()
    released = 0
    for cid in ids:
        if await _close_pending(db, cid, "expired", BookstoreCheckout.expires_at < now):
            released += 1
    if released:
        await db.commit()
    return released


# --- checkout -------------------------------------------------------------


def _line_tax(line_total: int, rate: float) -> int:
    if rate <= 0:
        return 0
    return line_total - round(line_total / (1 + rate))


def allocate_discount(amounts: list[int], discount: int) -> list[int]:
    """Split ``discount`` over line amounts proportionally (largest remainder),
    so per-line figures always add back up to the discounted total."""
    total = sum(amounts)
    if discount <= 0 or total <= 0:
        return [0] * len(amounts)
    discount = min(discount, total)
    shares = [a * discount // total for a in amounts]
    by_remainder = sorted(
        range(len(amounts)), key=lambda i: (amounts[i] * discount % total, amounts[i]), reverse=True
    )
    for i in by_remainder[: discount - sum(shares)]:
        shares[i] += 1
    return shares


def discounted_tax(lines: list[BookstoreCheckoutLine], discount: int) -> int:
    shares = allocate_discount([ln.line_total_cents for ln in lines], discount)
    return sum(
        _line_tax(ln.line_total_cents - share, float(ln.tax_rate or 0)) for ln, share in zip(lines, shares)
    )


def invoice_lines(order_lines: list[OrderLine], discount: int) -> list[InvoiceLine]:
    """Invoice items must satisfy price x qty = amount exactly. A discounted
    line that no longer divides evenly is split into (qty-1) x p and 1 x rest."""
    shares = allocate_discount([ln.line_total_cents for ln in order_lines], discount)
    out: list[InvoiceLine] = []
    for ln, share in zip(order_lines, shares):
        qty = int(ln.qty)
        amount = ln.line_total_cents - share
        if qty <= 1 or amount % qty == 0:
            parts = [(qty, amount // max(qty, 1))]
        else:
            unit = amount // qty
            parts = [(qty - 1, unit), (1, amount - unit * (qty - 1))]
        for n, price in parts:
            out.append(
                InvoiceLine(
                    name=ln.product_name, qty=float(n), unit_price_cents=price, amount_cents=price * n
                )
            )
    return out


async def load_checkout(db: AsyncSession, checkout_id: str) -> BookstoreCheckout | None:
    return (
        await db.execute(
            select(BookstoreCheckout)
            .where(BookstoreCheckout.id == checkout_id)
            .options(selectinload(BookstoreCheckout.lines))
            .execution_options(populate_existing=True)
        )
    ).scalar_one_or_none()


async def get_customer_checkout(
    db: AsyncSession, tenant_id: str, customer_ref: str, checkout_id: str
) -> BookstoreCheckout:
    checkout = await load_checkout(db, checkout_id)
    if checkout is None or checkout.tenant_id != tenant_id or checkout.customer_ref != customer_ref:
        raise _error(status.HTTP_404_NOT_FOUND, "checkout_not_found", "找不到這筆結帳")
    return checkout


async def create_checkout(
    db: AsyncSession, tenant_id: str, customer_ref: str, payload: CheckoutCreate
) -> BookstoreCheckout:
    s = get_settings()
    existing = (
        await db.execute(
            select(BookstoreCheckout.id).where(
                BookstoreCheckout.tenant_id == tenant_id,
                BookstoreCheckout.customer_ref == customer_ref,
                BookstoreCheckout.client_request_id == payload.client_request_id,
            )
        )
    ).scalar_one_or_none()
    if existing:
        return await get_customer_checkout(db, tenant_id, customer_ref, existing)

    store = await load_bookstore(db, tenant_id, payload.store_id)
    if not read_bookstore_settings(store)["is_open"]:
        raise _error(status.HTTP_409_CONFLICT, "store_closed", "這家店目前暫停營業")
    assert_presence(payload.presence_token, store.id, customer_ref)

    if len(payload.lines) > s.BOOKSTORE_MAX_LINES:
        raise _error(status.HTTP_400_BAD_REQUEST, "too_many_lines", "一次結帳的書太多了")
    for ln in payload.lines:
        if ln.qty > s.BOOKSTORE_MAX_QTY_PER_LINE:
            raise _error(
                status.HTTP_400_BAD_REQUEST,
                "qty_limit",
                f"每本書一次最多 {s.BOOKSTORE_MAX_QTY_PER_LINE} 本",
            )

    await release_expired(db, tenant_id)
    pending = int(
        (
            await db.execute(
                select(func.count()).where(
                    BookstoreCheckout.tenant_id == tenant_id,
                    BookstoreCheckout.customer_ref == customer_ref,
                    BookstoreCheckout.status == "pending",
                )
            )
        ).scalar_one()
    )
    if pending >= s.BOOKSTORE_MAX_PENDING_PER_CUSTOMER:
        raise _error(
            status.HTTP_429_TOO_MANY_REQUESTS,
            "too_many_pending",
            "你有尚未付款的結帳，請先完成或取消",
        )
    await assert_within_monthly_orders(db, tenant_id)

    product_ids = [ln.product_id for ln in payload.lines]
    rows = (
        await db.execute(_catalog_query(tenant_id, store.id).where(Product.id.in_(product_ids)))
    ).all()
    by_id = {r[0].id: r for r in rows}
    missing = [pid for pid in product_ids if pid not in by_id]
    if missing:
        raise _error(status.HTTP_404_NOT_FOUND, "not_in_store", "有書不在這家店")

    now = utcnow()
    checkout = BookstoreCheckout(
        tenant_id=tenant_id,
        store_id=store.id,
        customer_ref=customer_ref,
        client_request_id=payload.client_request_id,
        status="pending",
        reservation_active=True,
        expires_at=now + timedelta(minutes=s.BOOKSTORE_RESERVATION_MINUTES),
    )
    if payload.invoice:
        checkout.invoice_carrier_type = payload.invoice.carrier_type
        checkout.invoice_carrier_code = payload.invoice.carrier_code
        checkout.invoice_tax_id = payload.invoice.tax_id
        checkout.invoice_donation_code = payload.invoice.donation_code
    db.add(checkout)
    await db.flush()

    subtotal = 0
    tax = 0
    for ln in payload.lines:
        product, book, _level, _cat = by_id[ln.product_id]
        unit = int(product.price_cents)
        line_total = unit * ln.qty
        subtotal += line_total
        tax += _line_tax(line_total, float(product.tax_rate or 0))
        db.add(
            BookstoreCheckoutLine(
                checkout_id=checkout.id,
                product_id=product.id,
                product_name=product.name,
                sku=product.sku,
                isbn=book.isbn,
                qty=ln.qty,
                unit_price_cents=unit,
                line_total_cents=line_total,
                tax_rate=float(product.tax_rate or 0),
            )
        )
        if not await _reserve(db, store.id, product.id, ln.qty):
            product_id, product_name = product.id, product.name
            await db.rollback()
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                {
                    "code": "insufficient_stock",
                    "message": f"《{product_name}》剛被買走或數量不足",
                    "product_id": product_id,
                },
            )
    if subtotal <= 0:
        await db.rollback()
        raise _error(status.HTTP_400_BAD_REQUEST, "invalid_amount", "結帳金額不正確")

    checkout.subtotal_cents = subtotal
    checkout.tax_cents = tax
    checkout.total_cents = subtotal
    await db.commit()
    return await get_customer_checkout(db, tenant_id, customer_ref, checkout.id)


async def cancel_checkout(db: AsyncSession, checkout: BookstoreCheckout) -> BookstoreCheckout:
    if checkout.status != "pending":
        raise _error(status.HTTP_409_CONFLICT, "not_pending", "這筆結帳已無法取消")
    await _close_pending(db, checkout.id, "cancelled")
    await db.commit()
    return await load_checkout(db, checkout.id)


async def _unique_cash_code(db: AsyncSession, store_id: str) -> str:
    for _ in range(20):
        code = f"{secrets.randbelow(10**6):06d}"
        taken = (
            await db.execute(
                select(BookstoreCheckout.id).where(
                    BookstoreCheckout.store_id == store_id,
                    BookstoreCheckout.cash_code == code,
                    BookstoreCheckout.status == "pending",
                )
            )
        ).first()
        if taken is None:
            return code
    raise _error(status.HTTP_503_SERVICE_UNAVAILABLE, "busy", "系統忙碌，請稍後再試")


async def select_cash(db: AsyncSession, checkout: BookstoreCheckout) -> BookstoreCheckout:
    """Lock the checkout to cash-at-counter, apply the store's cash price and
    give the customer a little more time to walk to the counter."""
    if checkout.status != "pending":
        raise _error(status.HTTP_409_CONFLICT, "not_pending", "這筆結帳已無法付款")
    now = utcnow()
    if _aware(checkout.expires_at) < now:
        raise _error(status.HTTP_409_CONFLICT, "expired", "保留時間已過，請重新結帳")
    if checkout.payment_method == "cash":
        return checkout
    if checkout.payment_attempts:
        raise _error(status.HTTP_409_CONFLICT, "online_started", "已開始線上付款，請取消後重新結帳")
    store = await db.get(Store, checkout.store_id)
    cfg = read_bookstore_settings(store)
    if not cfg["cash_enabled"]:
        raise _error(status.HTTP_409_CONFLICT, "cash_unavailable", "這家店目前不接受現金結帳")

    total = checkout.subtotal_cents * cfg["cash_price_pct"] // 100
    discount = checkout.subtotal_cents - total
    expires = max(
        _aware(checkout.expires_at),
        now + timedelta(minutes=get_settings().BOOKSTORE_CASH_RESERVATION_MINUTES),
    )
    res = await db.execute(
        update(BookstoreCheckout)
        .where(
            BookstoreCheckout.id == checkout.id,
            BookstoreCheckout.status == "pending",
            BookstoreCheckout.payment_method.is_(None),
            BookstoreCheckout.payment_attempts == 0,
            BookstoreCheckout.expires_at >= now,
        )
        .values(
            payment_method="cash",
            discount_cents=discount,
            total_cents=total,
            tax_cents=discounted_tax(checkout.lines, discount),
            cash_code=await _unique_cash_code(db, checkout.store_id),
            expires_at=expires,
        )
        .execution_options(synchronize_session=False)
    )
    if res.rowcount != 1:
        await db.rollback()
        fresh = await load_checkout(db, checkout.id)
        if fresh is not None and fresh.payment_method == "cash" and fresh.status == "pending":
            return fresh
        raise _error(status.HTTP_409_CONFLICT, "not_pending", "這筆結帳已無法付款")
    await db.commit()
    return await load_checkout(db, checkout.id)


async def next_payment_trade_no(db: AsyncSession, checkout: BookstoreCheckout) -> str:
    if checkout.status != "pending":
        raise _error(status.HTTP_409_CONFLICT, "not_pending", "這筆結帳已無法付款")
    if checkout.payment_method == "cash":
        raise _error(status.HTTP_409_CONFLICT, "cash_selected", "這筆結帳已選擇現金付款，請至櫃台結帳")
    store = await db.get(Store, checkout.store_id)
    if not read_bookstore_settings(store)["online_payment_enabled"]:
        raise _error(status.HTTP_409_CONFLICT, "online_unavailable", "線上付款準備中，請改用現金結帳")
    if _aware(checkout.expires_at) < utcnow():
        raise _error(status.HTTP_409_CONFLICT, "expired", "保留時間已過，請重新結帳")
    if checkout.payment_attempts >= MAX_PAYMENT_ATTEMPTS:
        raise _error(status.HTTP_429_TOO_MANY_REQUESTS, "too_many_attempts", "付款嘗試次數過多，請重新結帳")
    if not checkout.payment_trade_no:
        checkout.payment_trade_no = "B" + checkout.id.replace("-", "")[: TRADE_PREFIX_LEN - 1].upper()
    checkout.payment_attempts += 1
    await db.flush()
    return f"{checkout.payment_trade_no}{checkout.payment_attempts:02d}"


async def find_by_trade_no(db: AsyncSession, merchant_trade_no: str) -> BookstoreCheckout | None:
    if len(merchant_trade_no) != TRADE_PREFIX_LEN + 2:
        return None
    cid = (
        await db.execute(
            select(BookstoreCheckout.id).where(
                BookstoreCheckout.payment_trade_no == merchant_trade_no[:TRADE_PREFIX_LEN]
            )
        )
    ).scalar_one_or_none()
    return await load_checkout(db, cid) if cid else None


def _new_exit_pass(checkout: BookstoreCheckout, now: datetime) -> None:
    checkout.exit_nonce = secrets.token_hex(8)
    checkout.exit_code = f"{secrets.randbelow(10**6):06d}"
    checkout.exit_expires_at = now + timedelta(minutes=get_settings().BOOKSTORE_EXIT_PASS_MINUTES)


async def mark_paid(
    db: AsyncSession,
    checkout: BookstoreCheckout,
    *,
    merchant_trade_no: str,
    gateway_trade_no: str,
    gateway: str,
    confirmed_by: str | None = None,
    allowed_from: tuple[str, ...] = ("pending", "expired", "cancelled"),
) -> bool:
    """Idempotent settlement. Returns True only for the call that performed
    the transition; replays of the same notification are no-ops."""
    now = utcnow()
    values = {
        "status": "paid",
        "paid_at": now,
        "payment_gateway": gateway,
        "gateway_ref": f"{merchant_trade_no}/{gateway_trade_no}"[:128],
    }
    if confirmed_by:
        values["cash_confirmed_by"] = confirmed_by
    res = await db.execute(
        update(BookstoreCheckout)
        .where(
            BookstoreCheckout.id == checkout.id,
            BookstoreCheckout.status.in_(allowed_from),
        )
        .values(**values)
        .execution_options(synchronize_session=False)
    )
    if res.rowcount != 1:
        return False
    checkout = await load_checkout(db, checkout.id)
    store = await db.get(Store, checkout.store_id)
    terminal_id, user_id = await ensure_app_identity(db, store)

    had_reservation = checkout.reservation_active
    checkout.reservation_active = False
    checkout.paid_after_expiry = not had_reservation

    order_no = await allocate_order_no(
        db, tenant_id=checkout.tenant_id, store_id=checkout.store_id, client_created_at=now
    )
    order = Order(
        order_no=order_no,
        tenant_id=checkout.tenant_id,
        store_id=checkout.store_id,
        terminal_id=terminal_id,
        cashier_id=user_id,
        status="paid",
        subtotal_cents=checkout.subtotal_cents,
        discount_cents=checkout.discount_cents or 0,
        tax_cents=checkout.tax_cents,
        total_cents=checkout.total_cents,
        invoice_carrier=checkout.invoice_carrier_code,
        note=f"讀冊 App 實體書店{'（現金）' if gateway == 'cash' else ''} {checkout.id}",
        client_created_at=now,
    )
    db.add(order)
    await db.flush()

    products = {
        p.id: p
        for p in (
            await db.execute(
                select(Product).where(Product.id.in_([ln.product_id for ln in checkout.lines]))
            )
        ).scalars()
    }
    book_share_pct = (await get_consignment_settings(db, checkout.tenant_id))["book_share_pct"]
    for ln in checkout.lines:
        product = products.get(ln.product_id)
        kind = getattr(product, "product_kind", "regular") if product else "regular"
        book_share, host_share = (
            calc_consignment_shares(ln.line_total_cents, book_share_pct)
            if kind == PRODUCT_KIND_CONSIGNMENT
            else (0, 0)
        )
        db.add(
            OrderLine(
                order_id=order.id,
                product_id=ln.product_id,
                product_name=ln.product_name,
                sku=ln.sku,
                qty=ln.qty,
                unit_price_cents=ln.unit_price_cents,
                line_discount_cents=0,
                line_total_cents=ln.line_total_cents,
                tax_rate=ln.tax_rate,
                product_kind=kind,
                consignment_book_share_cents=book_share,
                consignment_restaurant_share_cents=host_share,
            )
        )
        if had_reservation:
            await _unreserve(db, checkout.store_id, ln.product_id, ln.qty)
        level = (
            await db.execute(
                select(InventoryLevel).where(
                    InventoryLevel.store_id == checkout.store_id,
                    InventoryLevel.product_id == ln.product_id,
                )
            )
        ).scalar_one_or_none()
        if level is None:
            db.add(
                InventoryLevel(
                    tenant_id=checkout.tenant_id,
                    store_id=checkout.store_id,
                    product_id=ln.product_id,
                    on_hand=-ln.qty,
                )
            )
        else:
            await db.execute(
                update(InventoryLevel)
                .where(InventoryLevel.id == level.id)
                .values(on_hand=InventoryLevel.on_hand - ln.qty)
                .execution_options(synchronize_session=False)
            )
        db.add(
            InventoryMovement(
                tenant_id=checkout.tenant_id,
                store_id=checkout.store_id,
                product_id=ln.product_id,
                qty_delta=-float(ln.qty),
                reason="sale",
                ref_type="order",
                ref_id=order.id,
                terminal_id=terminal_id,
                user_id=user_id,
                note="bookstore_app",
                client_created_at=now,
            )
        )
    db.add(
        Payment(
            order_id=order.id,
            method=gateway,
            amount_cents=checkout.total_cents,
            status="captured",
            gateway_ref=gateway_trade_no[:128] or merchant_trade_no,
        )
    )
    checkout.order_id = order.id
    _new_exit_pass(checkout, now)
    await bump_usage_counter(db, tenant_id=checkout.tenant_id, metric="orders", delta=1)
    await db.commit()
    return True


async def issue_invoice_for_checkout(db: AsyncSession, checkout_id: str) -> None:
    """Best effort: a gateway failure leaves the sale intact and marks the
    checkout so staff can re-issue from the invoices screen."""
    checkout = await load_checkout(db, checkout_id)
    if checkout is None or checkout.order_id is None or checkout.invoice_status == "issued":
        return
    order = (
        await db.execute(select(Order).where(Order.id == checkout.order_id).options(selectinload(Order.lines)))
    ).scalar_one()
    setting = (
        await db.execute(
            select(TenantInvoiceSetting).where(
                TenantInvoiceSetting.tenant_id == checkout.tenant_id,
                TenantInvoiceSetting.is_enabled.is_(True),
            )
        )
    ).scalars().first()
    if setting is None:
        checkout.invoice_status = "skipped"
        await db.commit()
        return

    invoice = (
        await db.execute(select(Invoice).where(Invoice.order_id == order.id))
    ).scalar_one_or_none()
    if invoice is None:
        invoice = Invoice(
            tenant_id=order.tenant_id,
            order_id=order.id,
            total_cents=order.total_cents,
            tax_cents=order.tax_cents,
            tax_type=1,
            carrier_type=checkout.invoice_carrier_type,
            carrier_code=checkout.invoice_carrier_code,
            tax_id=checkout.invoice_tax_id,
            donation_code=checkout.invoice_donation_code,
            gateway=setting.driver,
        )
        db.add(invoice)
        await db.flush()
    try:
        drv = await tenant_invoice_driver_for(db, checkout.tenant_id, setting.driver)
        res = await drv.issue(
            InvoiceIssueRequest(
                order_id=order.id,
                total_cents=order.total_cents,
                tax_cents=order.tax_cents,
                carrier_type=checkout.invoice_carrier_type,
                carrier_code=checkout.invoice_carrier_code,
                tax_id=checkout.invoice_tax_id,
                donation_code=checkout.invoice_donation_code,
                lines=invoice_lines(list(order.lines), checkout.discount_cents or 0),
            )
        )
    except Exception:  # noqa: BLE001 - never lose a paid sale over invoicing
        logger.exception("bookstore invoice issue failed checkout=%s", checkout.id)
        res = None
    if res is not None and res.status == "issued":
        proof = extract_invoice_proof(res)
        invoice.status = "issued"
        invoice.invoice_number = res.invoice_number
        invoice.invoice_date = res.invoice_date or utcnow()
        invoice.gateway_response = res.raw
        invoice.random_code = proof.random_code or res.random_code
        invoice.barcode = proof.barcode or res.barcode
        invoice.qr_left = proof.qr_left or res.qr_left
        invoice.qr_right = proof.qr_right or res.qr_right
        order.invoice_number = res.invoice_number
        checkout.invoice_status = "issued"
        checkout.invoice_number = res.invoice_number
    else:
        invoice.status = "failed"
        invoice.last_error = str(res.raw) if res is not None else "gateway error"
        checkout.invoice_status = "failed"
    await db.commit()


async def rotate_exit_pass(db: AsyncSession, checkout: BookstoreCheckout) -> BookstoreCheckout:
    if checkout.status != "paid" or checkout.exit_verified_at is not None:
        raise _error(status.HTTP_409_CONFLICT, "exit_pass_unavailable", "這筆結帳沒有可用的出門憑證")
    _new_exit_pass(checkout, utcnow())
    await db.commit()
    return await load_checkout(db, checkout.id)


def exit_pass_for(checkout: BookstoreCheckout) -> ExitPassRead | None:
    expires = _aware(checkout.exit_expires_at)
    if (
        checkout.status != "paid"
        or checkout.exit_verified_at is not None
        or not checkout.exit_nonce
        or expires is None
        or expires <= utcnow()
    ):
        return None
    token = sign_token_until("exit", {"k": checkout.id, "n": checkout.exit_nonce}, expires)
    return ExitPassRead(token=token, code=checkout.exit_code or "", expires_at=expires)


def _lines(checkout: BookstoreCheckout) -> list[CheckoutLineRead]:
    return [
        CheckoutLineRead(
            product_id=ln.product_id,
            product_name=ln.product_name,
            isbn=ln.isbn,
            qty=ln.qty,
            unit_price_cents=ln.unit_price_cents,
            line_total_cents=ln.line_total_cents,
        )
        for ln in checkout.lines
    ]


async def _order_no(db: AsyncSession, checkout: BookstoreCheckout) -> str | None:
    if not checkout.order_id:
        return None
    return (await db.execute(select(Order.order_no).where(Order.id == checkout.order_id))).scalar_one_or_none()


CASH_QR_PREFIX = "TAAZECASH1:"


def cash_payment_for(checkout: BookstoreCheckout, effective_status: str) -> CashPaymentRead | None:
    if checkout.payment_method != "cash" or effective_status != "pending" or not checkout.cash_code:
        return None
    expires = _aware(checkout.expires_at)
    token = sign_token_until("cash", {"k": checkout.id, "c": checkout.cash_code}, expires)
    return CashPaymentRead(token=CASH_QR_PREFIX + token, code=checkout.cash_code, expires_at=expires)


async def checkout_read(db: AsyncSession, checkout: BookstoreCheckout) -> CheckoutRead:
    store = await db.get(Store, checkout.store_id)
    effective_status = checkout.status
    if effective_status == "pending" and _aware(checkout.expires_at) < utcnow():
        effective_status = "expired"
    return CheckoutRead(
        id=checkout.id,
        store_id=checkout.store_id,
        store_name=store.name if store else "",
        status=effective_status,
        subtotal_cents=checkout.subtotal_cents,
        discount_cents=checkout.discount_cents or 0,
        tax_cents=checkout.tax_cents,
        total_cents=checkout.total_cents,
        payment_method=checkout.payment_method,
        cash_payment=cash_payment_for(checkout, effective_status),
        expires_at=_aware(checkout.expires_at),
        paid_at=_aware(checkout.paid_at),
        invoice_status=checkout.invoice_status,
        invoice_number=checkout.invoice_number,
        order_no=await _order_no(db, checkout),
        exit_verified_at=_aware(checkout.exit_verified_at),
        exit_pass=exit_pass_for(checkout),
        lines=_lines(checkout),
        created_at=_aware(checkout.created_at),
    )


async def staff_checkout_read(db: AsyncSession, checkout: BookstoreCheckout) -> StaffCheckoutRead:
    return StaffCheckoutRead(
        id=checkout.id,
        store_id=checkout.store_id,
        status=checkout.status,
        subtotal_cents=checkout.subtotal_cents,
        discount_cents=checkout.discount_cents or 0,
        total_cents=checkout.total_cents,
        payment_method=checkout.payment_method,
        expires_at=_aware(checkout.expires_at),
        order_no=await _order_no(db, checkout),
        invoice_status=checkout.invoice_status,
        invoice_number=checkout.invoice_number,
        paid_at=_aware(checkout.paid_at),
        paid_after_expiry=checkout.paid_after_expiry,
        exit_verified_at=_aware(checkout.exit_verified_at),
        refunded_at=_aware(checkout.refunded_at),
        created_at=_aware(checkout.created_at),
        lines=_lines(checkout),
    )


# --- staff ----------------------------------------------------------------


async def find_cash_checkout(
    db: AsyncSession, *, tenant_id: str, store_id: str, token: str | None, code: str | None
) -> BookstoreCheckout | None:
    checkout: BookstoreCheckout | None = None
    if token:
        raw = token.strip()
        if raw.startswith(CASH_QR_PREFIX):
            raw = raw[len(CASH_QR_PREFIX):]
        body = verify_token("cash", raw, check_exp=False)
        if body:
            checkout = await load_checkout(db, str(body.get("k", "")))
            if checkout is not None and checkout.cash_code != body.get("c"):
                checkout = None
    else:
        norm = re.sub(r"\D", "", code or "")
        if len(norm) == 6:
            cid = (
                await db.execute(
                    select(BookstoreCheckout.id)
                    .where(
                        BookstoreCheckout.tenant_id == tenant_id,
                        BookstoreCheckout.store_id == store_id,
                        BookstoreCheckout.cash_code == norm,
                    )
                    .order_by(
                        (BookstoreCheckout.status == "pending").desc(),
                        BookstoreCheckout.created_at.desc(),
                    )
                    .limit(1)
                )
            ).scalars().first()
            checkout = await load_checkout(db, cid) if cid else None
    if (
        checkout is None
        or checkout.tenant_id != tenant_id
        or checkout.store_id != store_id
        or checkout.payment_method != "cash"
    ):
        return None
    return checkout


async def confirm_cash(
    db: AsyncSession, checkout: BookstoreCheckout, *, user_id: str, expected_total_cents: int
) -> BookstoreCheckout:
    """Staff took the cash at the counter. Expired checkouts are still
    accepted because the customer is standing there with the books."""
    if checkout.payment_method != "cash":
        raise _error(status.HTTP_409_CONFLICT, "not_cash", "這筆結帳不是現金付款")
    if checkout.status == "paid":
        raise _error(status.HTTP_409_CONFLICT, "already_paid", "這筆已經收過款了")
    if checkout.status not in ("pending", "expired"):
        raise _error(status.HTTP_409_CONFLICT, "closed", "這筆結帳已取消或退貨，請顧客重新結帳")
    if checkout.total_cents != expected_total_cents:
        raise _error(status.HTTP_409_CONFLICT, "amount_changed", "金額與畫面不符，請重新查詢")
    done = await mark_paid(
        db,
        checkout,
        merchant_trade_no=f"CASH{checkout.cash_code}",
        gateway_trade_no="",
        gateway="cash",
        confirmed_by=user_id,
        allowed_from=("pending", "expired"),
    )
    if not done:
        await db.rollback()
        raise _error(status.HTTP_409_CONFLICT, "already_paid", "這筆已經收過款了")
    return await load_checkout(db, checkout.id)


async def verify_exit(
    db: AsyncSession,
    *,
    tenant_id: str,
    store_id: str,
    user_id: str,
    token: str | None,
    code: str | None,
) -> ExitVerifyResponse:
    checkout: BookstoreCheckout | None = None
    if token:
        body = verify_token("exit", token.strip(), check_exp=False)
        if body:
            checkout = await load_checkout(db, str(body.get("k", "")))
            if checkout is not None and checkout.exit_nonce != body.get("n"):
                checkout = None
    else:
        norm = re.sub(r"\D", "", code or "")
        if len(norm) == 6:
            candidates = (
                await db.execute(
                    select(BookstoreCheckout.id)
                    .where(
                        BookstoreCheckout.tenant_id == tenant_id,
                        BookstoreCheckout.store_id == store_id,
                        BookstoreCheckout.exit_code == norm,
                    )
                    .order_by(
                        BookstoreCheckout.exit_verified_at.is_(None).desc(),
                        BookstoreCheckout.paid_at.desc(),
                    )
                    .limit(1)
                )
            ).scalars().first()
            checkout = await load_checkout(db, candidates) if candidates else None

    if checkout is None or checkout.tenant_id != tenant_id or checkout.store_id != store_id:
        return ExitVerifyResponse(result="invalid")

    base = {
        "checkout_id": checkout.id,
        "order_no": await _order_no(db, checkout),
        "total_cents": checkout.total_cents,
        "paid_at": _aware(checkout.paid_at),
        "lines": _lines(checkout),
    }
    if checkout.status != "paid":
        return ExitVerifyResponse(result="not_paid", **base)
    if checkout.exit_verified_at is not None:
        return ExitVerifyResponse(
            result="already_used", verified_at=_aware(checkout.exit_verified_at), **base
        )
    if _aware(checkout.exit_expires_at) is None or _aware(checkout.exit_expires_at) <= utcnow():
        return ExitVerifyResponse(result="expired", **base)

    now = utcnow()
    res = await db.execute(
        update(BookstoreCheckout)
        .where(BookstoreCheckout.id == checkout.id, BookstoreCheckout.exit_verified_at.is_(None))
        .values(exit_verified_at=now, exit_verified_by=user_id)
        .execution_options(synchronize_session=False)
    )
    if res.rowcount != 1:
        await db.rollback()
        fresh = await load_checkout(db, checkout.id)
        return ExitVerifyResponse(
            result="already_used", verified_at=_aware(fresh.exit_verified_at), **base
        )
    await db.commit()
    return ExitVerifyResponse(result="valid", verified_at=now, **base)


async def refund_checkout(
    db: AsyncSession, checkout: BookstoreCheckout, *, user_id: str, reason: str
) -> bool:
    """Restock and mark the sale refunded. Returns whether an issued invoice
    was voided. The card refund itself is done in the gateway back office."""
    now = utcnow()
    res = await db.execute(
        update(BookstoreCheckout)
        .where(BookstoreCheckout.id == checkout.id, BookstoreCheckout.status == "paid")
        .values(status="refunded", refunded_at=now, refunded_by=user_id)
        .execution_options(synchronize_session=False)
    )
    if res.rowcount != 1:
        raise _error(status.HTTP_409_CONFLICT, "not_refundable", "只有已付款的結帳可以退貨")
    checkout = await load_checkout(db, checkout.id)
    order = (
        await db.execute(select(Order).where(Order.id == checkout.order_id).options(selectinload(Order.lines)))
    ).scalar_one_or_none()

    for ln in checkout.lines:
        await db.execute(
            update(InventoryLevel)
            .where(
                InventoryLevel.store_id == checkout.store_id,
                InventoryLevel.product_id == ln.product_id,
            )
            .values(on_hand=InventoryLevel.on_hand + ln.qty)
            .execution_options(synchronize_session=False)
        )
        db.add(
            InventoryMovement(
                tenant_id=checkout.tenant_id,
                store_id=checkout.store_id,
                product_id=ln.product_id,
                qty_delta=float(ln.qty),
                reason="refund",
                ref_type="order",
                ref_id=checkout.order_id,
                user_id=user_id,
                note="bookstore_app",
                client_created_at=now,
            )
        )

    if order is not None:
        order.status = "refunded"
        order.refunded_cents = order.total_cents
        refund = Refund(
            order_id=order.id,
            user_id=user_id,
            method=checkout.payment_gateway or "ecpay",
            total_amount_cents=order.total_cents,
            reason=reason,
            status="approved",
            approver_id=user_id,
            decided_at=now,
        )
        db.add(refund)
        await db.flush()
        for ol in order.lines:
            db.add(
                RefundLine(
                    refund_id=refund.id,
                    order_line_id=ol.id,
                    qty=ol.qty,
                    amount_cents=ol.line_total_cents,
                )
            )
    await db.commit()

    voided = False
    invoice = (
        await db.execute(select(Invoice).where(Invoice.order_id == checkout.order_id))
    ).scalar_one_or_none() if checkout.order_id else None
    if invoice is not None and invoice.status == "issued" and invoice.gateway and invoice.invoice_number:
        try:
            drv = await tenant_invoice_driver_for(db, checkout.tenant_id, invoice.gateway)
            vres = await drv.void(InvoiceVoidRequest(invoice_number=invoice.invoice_number, reason=reason))
            if vres.status == "voided":
                invoice.status = "voided"
                invoice.gateway_response = vres.raw
                voided = True
            else:
                invoice.last_error = str(vres.raw)
        except Exception:  # noqa: BLE001
            logger.exception("bookstore invoice void failed checkout=%s", checkout.id)
        await db.commit()
    return voided
