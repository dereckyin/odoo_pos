"""Order list enrichment and filtering helpers."""

from __future__ import annotations

from datetime import datetime, time, timezone
from zoneinfo import ZoneInfo

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..models import BookstoreCheckout, Member, Order, Payment, Store, User
from ..schemas.order import OrderListItem, OrderRead
from .business_time import order_business_datetime, tenant_timezone


SALE_STATUSES = ("paid", "partiallyRefunded", "refunded")


def _order_to_read(order: Order) -> OrderRead:
    return OrderRead.model_validate(order)


def enrich_order_item(
    order: Order,
    *,
    store_name: str | None = None,
    cashier_name: str | None = None,
    member_name: str | None = None,
    redeem_bonus_cents: int = 0,
    redeem_acc_cents: int = 0,
    is_bookstore: bool = False,
) -> OrderListItem:
    base = _order_to_read(order)
    payment_methods = list({p.method for p in order.payments})
    if is_bookstore:
        source = "pos"
    else:
        source = "qr" if order.source_guest_order_id else "pos"
    data = base.model_dump()
    # Bookstore invoices are free-tax; never report the old 5% embedded tax.
    if is_bookstore:
        data["tax_cents"] = 0
    data.update(
        store_name=store_name,
        cashier_name=cashier_name,
        member_name=member_name,
        payment_methods=payment_methods,
        source=source,
        redeem_bonus_cents=int(redeem_bonus_cents or 0),
        redeem_acc_cents=int(redeem_acc_cents or 0),
    )
    return OrderListItem(**data)


def apply_order_filters(
    stmt,
    *,
    scope,
    since: datetime | None = None,
    until: datetime | None = None,
    status: str | None = None,
    store_id: str | None = None,
    member_id: str | None = None,
    terminal_id: str | None = None,
    payment_method: str | None = None,
    q: str | None = None,
    tz: ZoneInfo | None = None,
):
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        stmt = stmt.where(Order.store_id == store_id)
    if member_id:
        stmt = stmt.where(Order.member_id == member_id)
    if terminal_id:
        stmt = stmt.where(Order.terminal_id == terminal_id)
    if status:
        stmt = stmt.where(Order.status == status)
    if q:
        like = f"%{q.strip()}%"
        stmt = stmt.where(
            or_(Order.order_no.ilike(like), Order.invoice_number.ilike(like))
        )
    if payment_method:
        stmt = stmt.where(
            Order.id.in_(
                select(Payment.order_id).where(Payment.method == payment_method)
            )
        )

    # Date filters use business timestamp (client_created_at fallback created_at)
    biz_ts = func.coalesce(Order.client_created_at, Order.created_at)
    if since:
        stmt = stmt.where(biz_ts >= since)
    if until:
        stmt = stmt.where(biz_ts <= until)
    return stmt


async def load_order_display_maps(
    db: AsyncSession, orders: list[Order]
) -> tuple[dict[str, str], dict[str, str], dict[str, str], dict[str, tuple[int, int]]]:
    store_ids = {o.store_id for o in orders}
    cashier_ids = {o.cashier_id for o in orders}
    member_ids = {o.member_id for o in orders if o.member_id}
    order_ids = {o.id for o in orders}

    store_map: dict[str, str] = {}
    if store_ids:
        rows = (
            await db.execute(select(Store.id, Store.name).where(Store.id.in_(store_ids)))
        ).all()
        store_map = {r.id: r.name for r in rows}

    cashier_map: dict[str, str] = {}
    if cashier_ids:
        rows = (
            await db.execute(select(User.id, User.display_name, User.username).where(User.id.in_(cashier_ids)))
        ).all()
        cashier_map = {r.id: (r.display_name or r.username) for r in rows}

    member_map: dict[str, str] = {}
    if member_ids:
        rows = (
            await db.execute(select(Member.id, Member.name).where(Member.id.in_(member_ids)))
        ).all()
        member_map = {r.id: r.name for r in rows}

    redeem_map: dict[str, tuple[int, int]] = {}
    # Bookstore app orders have no 點餐趣 member; key their masked label by order id.
    if order_ids:
        rows = (
            await db.execute(
                select(
                    BookstoreCheckout.order_id,
                    BookstoreCheckout.member_label,
                    BookstoreCheckout.redeem_bonus_cents,
                    BookstoreCheckout.redeem_acc_cents,
                ).where(BookstoreCheckout.order_id.in_(order_ids))
            )
        ).all()
        for r in rows:
            if not r.order_id:
                continue
            redeem_map[r.order_id] = (
                int(r.redeem_bonus_cents or 0),
                int(r.redeem_acc_cents or 0),
            )
            if r.member_label and r.order_id not in member_map:
                member_map[r.order_id] = r.member_label

    return store_map, cashier_map, member_map, redeem_map


def order_member_name(order: Order, member_map: dict[str, str]) -> str | None:
    return member_map.get(order.member_id or order.id)


def enrich_from_maps(
    order: Order,
    *,
    store_map: dict[str, str],
    cashier_map: dict[str, str],
    member_map: dict[str, str],
    redeem_map: dict[str, tuple[int, int]],
) -> OrderListItem:
    bonus, acc = redeem_map.get(order.id, (0, 0))
    return enrich_order_item(
        order,
        store_name=store_map.get(order.store_id),
        cashier_name=cashier_map.get(order.cashier_id),
        member_name=order_member_name(order, member_map),
        redeem_bonus_cents=bonus,
        redeem_acc_cents=acc,
        is_bookstore=order.id in redeem_map,
    )


async def enrich_single_order(db: AsyncSession, order: Order) -> OrderListItem:
    store_map, cashier_map, member_map, redeem_map = await load_order_display_maps(db, [order])
    return enrich_from_maps(
        order,
        store_map=store_map,
        cashier_map=cashier_map,
        member_map=member_map,
        redeem_map=redeem_map,
    )
