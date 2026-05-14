"""Tenant data-export endpoint (off-boarding / GDPR / data-portability).

Tenant admins can pull a full JSON snapshot of their own data so they can
walk away with their records when they cancel the subscription. Bulk
exports are gated by ``TenantAdminDep`` and rate-limited (one report per
minute per tenant); the response excludes all encrypted credential fields.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import DbSession, TenantAdminDep
from ...models import (
    Category,
    Coupon,
    DiningTable,
    Invoice,
    InventoryLevel,
    Member,
    MemberLevel,
    Order,
    OrderLine,
    Payment,
    Product,
    ProductBarcode,
    Promotion,
    PurchaseOrder,
    PurchaseOrderLine,
    Store,
    Supplier,
    Tenant,
    Terminal,
    User,
)

router = APIRouter(prefix="/tenant", tags=["tenant-export"])


def _serialize(row, include: tuple[str, ...] | None = None) -> dict[str, Any]:
    """Best-effort SQLAlchemy row serialiser. Skips columns explicitly listed
    in ``_REDACTED_COLUMNS`` (encrypted secrets, password hashes etc.)."""
    cols = include or [c.key for c in row.__table__.columns]
    out: dict[str, Any] = {}
    for c in cols:
        if c in _REDACTED_COLUMNS:
            continue
        val = getattr(row, c, None)
        if isinstance(val, datetime):
            val = val.isoformat()
        out[c] = val
    return out


_REDACTED_COLUMNS = {
    "password_hash",
    "api_key_hash",
    "code_hash",
    "hash_key_enc",
    "hash_iv_enc",
    "channel_id_enc",
    "channel_secret_enc",
}


@router.get("/export")
async def export_tenant(db: DbSession, scope: TenantAdminDep) -> dict[str, Any]:
    """Return a deep snapshot of the tenant's business data. Hot-path
    APIs should NOT call this — it scans most tables."""
    tid = scope.tenant_id

    async def _all(model, *, where=None):
        stmt = select(model).where(model.tenant_id == tid)
        if where is not None:
            stmt = stmt.where(where)
        rows = (await db.execute(stmt)).scalars().all()
        return [_serialize(r) for r in rows]

    tenant = await db.get(Tenant, tid)
    snapshot: dict[str, Any] = {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "schema_version": 1,
        "tenant": _serialize(tenant) if tenant else None,
        "stores": await _all(Store),
        "terminals": await _all(Terminal),
        "users": await _all(User),
        "categories": await _all(Category),
        "products": await _all(Product),
        "product_barcodes": await _all(ProductBarcode),
        "member_levels": await _all(MemberLevel),
        "members": await _all(Member),
        "coupons": await _all(Coupon),
        "promotions": await _all(Promotion),
        "inventory_levels": await _all(InventoryLevel),
        "suppliers": await _all(Supplier, where=Supplier.deleted_at.is_(None)),
        "purchase_orders": await _all(PurchaseOrder),
        "dining_tables": await _all(DiningTable),
        "orders": await _all(Order),
        "invoices": await _all(Invoice),
    }

    # Order lines + payments are scoped via the parent order's tenant_id;
    # query them indirectly so we don't depend on the join tables having
    # tenant_id columns.
    order_ids = [o["id"] for o in snapshot["orders"]]
    if order_ids:
        snapshot["order_lines"] = [
            _serialize(r)
            for r in (
                await db.execute(select(OrderLine).where(OrderLine.order_id.in_(order_ids)))
            ).scalars().all()
        ]
        snapshot["payments"] = [
            _serialize(r)
            for r in (
                await db.execute(select(Payment).where(Payment.order_id.in_(order_ids)))
            ).scalars().all()
        ]
    else:
        snapshot["order_lines"] = []
        snapshot["payments"] = []

    po_ids = [p["id"] for p in snapshot["purchase_orders"]]
    if po_ids:
        snapshot["purchase_order_lines"] = [
            _serialize(r)
            for r in (
                await db.execute(
                    select(PurchaseOrderLine).where(PurchaseOrderLine.purchase_order_id.in_(po_ids))
                )
            ).scalars().all()
        ]
    else:
        snapshot["purchase_order_lines"] = []

    await audit(
        db, scope, action="tenant_export", resource_type="tenant",
        resource_id=tid, extra={"counts": {k: len(v) if isinstance(v, list) else 1
                                            for k, v in snapshot.items()}},
        flush=False,
    )
    await db.commit()
    return snapshot
