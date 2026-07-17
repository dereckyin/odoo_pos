"""Consignment book settlement with refund reversal."""
from __future__ import annotations

from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.deps import TenantScope
from ..models import Order, OrderLine, Refund, RefundLine, Store
from ..schemas.book import ConsignmentSettlementReport, ConsignmentSettlementRow
from .consignment_books import PRODUCT_KIND_CONSIGNMENT, get_consignment_settings
from .reporting import SALE_STATUSES, apply_date_range


def refund_share_cents(order_line: OrderLine, refund_amount_cents: int) -> tuple[int, int]:
    """Proportional book/restaurant reversal for a partial or full line refund."""
    if refund_amount_cents <= 0:
        return 0, 0
    line_total = int(order_line.line_total_cents)
    if line_total <= 0:
        return 0, refund_amount_cents
    book_orig = int(order_line.consignment_book_share_cents)
    restaurant_orig = int(order_line.consignment_restaurant_share_cents)
    book = round(book_orig * refund_amount_cents / line_total)
    restaurant = round(restaurant_orig * refund_amount_cents / line_total)
    # Keep book + restaurant aligned with refund amount (rounding drift).
    drift = refund_amount_cents - (book + restaurant)
    if drift != 0:
        restaurant += drift
    return book, restaurant


def refund_list_price_cents(order_line: OrderLine, refund_qty: float) -> int:
    """定價沖銷：unit_price × refund qty（與折扣前定價一致）。"""
    if refund_qty <= 0:
        return 0
    return int(round(int(order_line.unit_price_cents) * float(refund_qty)))


async def build_consignment_settlement(
    db: AsyncSession,
    scope: TenantScope,
    since: datetime | None = None,
    until: datetime | None = None,
    store_id: str | None = None,
) -> ConsignmentSettlementReport:
    cfg = await get_consignment_settings(db, scope.tenant_id)

    sales_stmt = (
        select(
            Order.store_id,
            Store.name,
            func.coalesce(func.sum(OrderLine.qty), 0),
            func.coalesce(func.sum(OrderLine.unit_price_cents * OrderLine.qty), 0),
            func.coalesce(func.sum(OrderLine.line_total_cents), 0),
            func.coalesce(func.sum(OrderLine.consignment_book_share_cents), 0),
            func.coalesce(func.sum(OrderLine.consignment_restaurant_share_cents), 0),
        )
        .join(Order, Order.id == OrderLine.order_id)
        .join(Store, Store.id == Order.store_id)
        .where(
            Order.tenant_id == scope.tenant_id,
            Order.status.in_(SALE_STATUSES),
            OrderLine.product_kind == PRODUCT_KIND_CONSIGNMENT,
        )
        .group_by(Order.store_id, Store.name)
    )
    if scope.store_id and not scope.is_tenant_admin:
        sales_stmt = sales_stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        sales_stmt = sales_stmt.where(Order.store_id == store_id)
    sales_stmt = apply_date_range(sales_stmt, since, until)

    sales_rows = (await db.execute(sales_stmt)).all()
    sales_by_store: dict[str, dict] = {}
    for r in sales_rows:
        sales_by_store[r[0]] = {
            "store_name": r[1] or "",
            "qty": float(r[2]),
            "list_price_cents": int(r[3]),
            "revenue_cents": int(r[4]),
            "book_share_cents": int(r[5]),
            "restaurant_share_cents": int(r[6]),
        }

    refund_stmt = (
        select(RefundLine, OrderLine, Order)
        .join(OrderLine, OrderLine.id == RefundLine.order_line_id)
        .join(Refund, Refund.id == RefundLine.refund_id)
        .join(Order, Order.id == Refund.order_id)
        .where(
            Order.tenant_id == scope.tenant_id,
            OrderLine.product_kind == PRODUCT_KIND_CONSIGNMENT,
        )
    )
    if scope.store_id and not scope.is_tenant_admin:
        refund_stmt = refund_stmt.where(Order.store_id == scope.store_id)
    elif store_id:
        refund_stmt = refund_stmt.where(Order.store_id == store_id)
    if since:
        refund_stmt = refund_stmt.where(Refund.created_at >= since)
    if until:
        refund_stmt = refund_stmt.where(Refund.created_at <= until)

    refund_rows = (await db.execute(refund_stmt)).all()
    refunds_by_store: dict[str, dict] = {}
    for refund_line, order_line, order in refund_rows:
        sid = order.store_id
        bucket = refunds_by_store.setdefault(
            sid,
            {
                "qty": 0.0,
                "list_price_cents": 0,
                "refund_cents": 0,
                "book_share_cents": 0,
                "restaurant_share_cents": 0,
            },
        )
        bucket["qty"] += float(refund_line.qty)
        amt = int(refund_line.amount_cents)
        book, restaurant = refund_share_cents(order_line, amt)
        bucket["refund_cents"] += amt
        bucket["list_price_cents"] += refund_list_price_cents(order_line, float(refund_line.qty))
        bucket["book_share_cents"] += book
        bucket["restaurant_share_cents"] += restaurant

    all_store_ids = set(sales_by_store) | set(refunds_by_store)

    def _net_revenue(sid: str) -> int:
        gross = sales_by_store.get(sid, {}).get("revenue_cents", 0)
        refunded = refunds_by_store.get(sid, {}).get("refund_cents", 0)
        return gross - refunded

    result_rows: list[ConsignmentSettlementRow] = []
    for sid in sorted(all_store_ids, key=_net_revenue, reverse=True):
        sales = sales_by_store.get(sid, {})
        refunds = refunds_by_store.get(sid, {})
        gross_list = sales.get("list_price_cents", 0)
        list_refund = refunds.get("list_price_cents", 0)
        gross_rev = sales.get("revenue_cents", 0)
        refund_cents = refunds.get("refund_cents", 0)
        gross_book = sales.get("book_share_cents", 0)
        refund_book = refunds.get("book_share_cents", 0)
        gross_restaurant = sales.get("restaurant_share_cents", 0)
        refund_restaurant = refunds.get("restaurant_share_cents", 0)
        store_name = sales.get("store_name") or ""
        if not store_name and sid in refunds_by_store:
            store_row = await db.get(Store, sid)
            store_name = store_row.name if store_row else ""
        result_rows.append(
            ConsignmentSettlementRow(
                store_id=sid,
                store_name=store_name,
                qty=max(0.0, sales.get("qty", 0.0) - refunds.get("qty", 0.0)),
                gross_list_price_cents=gross_list,
                list_price_refund_cents=list_refund,
                list_price_cents=gross_list - list_refund,
                gross_revenue_cents=gross_rev,
                refund_cents=refund_cents,
                revenue_cents=gross_rev - refund_cents,
                gross_book_share_cents=gross_book,
                refund_book_share_cents=refund_book,
                book_share_cents=gross_book - refund_book,
                gross_restaurant_share_cents=gross_restaurant,
                refund_restaurant_share_cents=refund_restaurant,
                restaurant_share_cents=gross_restaurant - refund_restaurant,
            )
        )

    return ConsignmentSettlementReport(
        book_share_pct=cfg["book_share_pct"],
        rows=result_rows,
        total_qty=sum(x.qty for x in result_rows),
        gross_list_price_cents=sum(x.gross_list_price_cents for x in result_rows),
        list_price_refund_cents=sum(x.list_price_refund_cents for x in result_rows),
        total_list_price_cents=sum(x.list_price_cents for x in result_rows),
        gross_revenue_cents=sum(x.gross_revenue_cents for x in result_rows),
        refund_cents=sum(x.refund_cents for x in result_rows),
        total_revenue_cents=sum(x.revenue_cents for x in result_rows),
        gross_book_share_cents=sum(x.gross_book_share_cents for x in result_rows),
        refund_book_share_cents=sum(x.refund_book_share_cents for x in result_rows),
        total_book_share_cents=sum(x.book_share_cents for x in result_rows),
        gross_restaurant_share_cents=sum(x.gross_restaurant_share_cents for x in result_rows),
        refund_restaurant_share_cents=sum(x.refund_restaurant_share_cents for x in result_rows),
        total_restaurant_share_cents=sum(x.restaurant_share_cents for x in result_rows),
    )
