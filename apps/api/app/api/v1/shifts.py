"""Cashier shift open / close (交班結帳).

A shift is opened at clock-in and closed at handover. On close we tally sales
and refunds rung up by this cashier on this terminal during the shift, compute
the expected cash drawer, and store the per-method breakdown for the Z report.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select

from ...core.audit import audit
from ...core.deps import DbSession, TenantScope, apply_tenant, ensure_same_tenant
from ...models import Order, Payment, PosShift, Refund
from ...schemas.shift import (
    ShiftCloseRequest,
    ShiftOpenRequest,
    ShiftRead,
    ShiftSummary,
)

router = APIRouter(prefix="/shifts", tags=["shifts"])


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def _current_open_shift(db, scope) -> PosShift | None:
    stmt = select(PosShift).where(
        PosShift.tenant_id == scope.tenant_id,
        PosShift.user_id == scope.user_id,
        PosShift.status == "open",
    )
    if scope.terminal_id:
        stmt = stmt.where(PosShift.terminal_id == scope.terminal_id)
    stmt = stmt.order_by(PosShift.opened_at.desc())
    return (await db.execute(stmt)).scalars().first()


async def _compute_summary(db, shift: PosShift) -> ShiftSummary:
    """Tally orders / refunds attributed to this shift.

    Orders are matched by ``shift_id`` when the POS tagged them, otherwise by
    (store, terminal, cashier) within the shift's open window so legacy clients
    still reconcile."""
    upper = shift.closed_at or _now()
    order_match = Order.shift_id == shift.id
    window_match = (
        (Order.shift_id.is_(None))
        & (Order.store_id == shift.store_id)
        & (Order.cashier_id == shift.user_id)
        & (Order.created_at >= shift.opened_at)
        & (Order.created_at <= upper)
    )
    if shift.terminal_id:
        window_match = window_match & (Order.terminal_id == shift.terminal_id)
    cond = order_match | window_match

    order_rows = (
        await db.execute(
            select(Order.id, Order.total_cents, Order.refunded_cents).where(
                Order.tenant_id == shift.tenant_id, cond
            )
        )
    ).all()
    order_ids = [r[0] for r in order_rows]
    order_count = len(order_ids)
    sales_total = sum(int(r[1]) for r in order_rows)
    refund_total = sum(int(r[2] or 0) for r in order_rows)

    by_method: dict[str, int] = {}
    cash_sales = 0
    if order_ids:
        pay_rows = (
            await db.execute(
                select(Payment.method, func.coalesce(func.sum(Payment.amount_cents), 0))
                .where(Payment.order_id.in_(order_ids))
                .group_by(Payment.method)
            )
        ).all()
        for method, amount in pay_rows:
            by_method[method] = int(amount or 0)
        cash_sales = by_method.get("cash", 0)

    cash_refunds = 0
    if order_ids:
        cash_refunds = int(
            (
                await db.execute(
                    select(func.coalesce(func.sum(Refund.total_amount_cents), 0)).where(
                        Refund.order_id.in_(order_ids),
                        Refund.method == "cash",
                        Refund.status == "approved",
                    )
                )
            ).scalar_one()
            or 0
        )

    expected_cash = shift.opening_cash_cents + cash_sales - cash_refunds
    return ShiftSummary(
        shift_id=shift.id,
        order_count=order_count,
        sales_total_cents=sales_total,
        refund_total_cents=refund_total,
        by_method_cents=by_method,
        cash_sales_cents=cash_sales,
        cash_refunds_cents=cash_refunds,
        expected_cash_cents=expected_cash,
    )


@router.post("/open", response_model=ShiftRead, status_code=201)
async def open_shift(payload: ShiftOpenRequest, db: DbSession, scope: TenantScope) -> PosShift:
    scope.require_tenant()
    if not scope.store_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "shift requires a store-bound POS session")
    existing = await _current_open_shift(db, scope)
    if existing:
        return existing
    shift = PosShift(
        id=payload.id,
        tenant_id=scope.tenant_id,
        store_id=scope.store_id,
        terminal_id=scope.terminal_id,
        user_id=scope.user_id,
        status="open",
        opened_at=_now(),
        opening_cash_cents=payload.opening_cash_cents,
        note=payload.note,
    )
    db.add(shift)
    await audit(db, scope, action="shift_open", resource_type="pos_shift",
                resource_id=shift.id, flush=False)
    await db.commit()
    await db.refresh(shift)
    return shift


@router.get("/current", response_model=ShiftRead | None)
async def current_shift(db: DbSession, scope: TenantScope):
    scope.require_tenant()
    return await _current_open_shift(db, scope)


@router.get("/current/summary", response_model=ShiftSummary | None)
async def current_shift_summary(db: DbSession, scope: TenantScope):
    scope.require_tenant()
    shift = await _current_open_shift(db, scope)
    if not shift:
        return None
    return await _compute_summary(db, shift)


@router.post("/close", response_model=ShiftRead)
async def close_shift(payload: ShiftCloseRequest, db: DbSession, scope: TenantScope) -> PosShift:
    scope.require_tenant()
    shift = await _current_open_shift(db, scope)
    if not shift:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "no open shift")
    shift.closed_at = _now()
    summary = await _compute_summary(db, shift)
    shift.counted_cash_cents = payload.counted_cash_cents
    shift.expected_cash_cents = summary.expected_cash_cents
    shift.diff_cents = payload.counted_cash_cents - summary.expected_cash_cents
    shift.totals_json = {
        "by_method": summary.by_method_cents,
        "order_count": summary.order_count,
        "sales_total": summary.sales_total_cents,
        "refund_total": summary.refund_total_cents,
        "cash_sales": summary.cash_sales_cents,
        "cash_refunds": summary.cash_refunds_cents,
    }
    if payload.note:
        shift.note = payload.note
    shift.status = "closed"
    await audit(db, scope, action="shift_close", resource_type="pos_shift",
                resource_id=shift.id, extra={"diff_cents": shift.diff_cents}, flush=False)
    await db.commit()
    await db.refresh(shift)
    return shift


@router.get("", response_model=list[ShiftRead])
async def list_shifts(
    db: DbSession,
    scope: TenantScope,
    status_filter: str | None = Query(default=None, alias="status"),
    limit: int = Query(default=100, le=500),
):
    scope.require_tenant()
    stmt = apply_tenant(select(PosShift), PosShift, scope)
    if scope.store_id and not scope.is_tenant_admin:
        stmt = stmt.where(PosShift.store_id == scope.store_id)
    if status_filter:
        stmt = stmt.where(PosShift.status == status_filter)
    stmt = stmt.order_by(PosShift.opened_at.desc()).limit(limit)
    return (await db.execute(stmt)).scalars().all()


@router.get("/{sid}", response_model=ShiftRead)
async def get_shift(sid: str, db: DbSession, scope: TenantScope) -> PosShift:
    scope.require_tenant()
    shift = await db.get(PosShift, sid)
    if not shift:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "shift not found")
    ensure_same_tenant(scope, shift)
    return shift
