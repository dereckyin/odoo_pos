"""Consignment books tenant settings and access helpers."""
from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Supplier, Tenant
from .tenant_modules import (
    MODULE_CONSIGNMENT_BOOKS,
    assert_tenant_module,
    get_tenant_modules,
)

CONSIGNMENT_CATEGORY_NAME = "寄賣書籍"
PRODUCT_KIND_CONSIGNMENT = "consignment_book"

SUPPLIER_INTERNAL_CODE = "BOOK-INTERNAL"
SUPPLIER_EXTERNAL_CODE = "BOOK-EXTERNAL"

DEFAULT_DISCOUNT_PRESETS: list[dict] = [
    {"label": "9折", "pct_off": 10},
    {"label": "8折", "pct_off": 20},
    {"label": "7折", "pct_off": 30},
    {"label": "5折", "pct_off": 50},
]


def read_consignment_settings(settings: dict | None) -> dict:
    raw = (settings or {}).get("consignment_books") or {}
    store_ids = raw.get("store_ids") or []
    presets = raw.get("discount_presets") or DEFAULT_DISCOUNT_PRESETS
    return {
        "book_share_pct": int(raw.get("book_share_pct", 60)),
        "store_ids": [str(s) for s in store_ids],
        "discount_presets": presets,
    }


def write_consignment_settings(settings: dict | None, patch: dict) -> dict:
    merged = dict(settings or {})
    current = read_consignment_settings(merged)
    if patch.get("book_share_pct") is not None:
        pct = int(patch["book_share_pct"])
        if pct < 0 or pct > 100:
            raise ValueError("book_share_pct must be 0-100")
        current["book_share_pct"] = pct
    if patch.get("store_ids") is not None:
        current["store_ids"] = [str(s) for s in patch["store_ids"]]
    if patch.get("discount_presets") is not None:
        current["discount_presets"] = patch["discount_presets"]
    merged["consignment_books"] = current
    return merged


async def get_consignment_settings(db: AsyncSession, tenant_id: str) -> dict:
    tenant = await db.get(Tenant, tenant_id)
    if tenant is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "tenant not found")
    return read_consignment_settings(tenant.settings)


async def assert_consignment_module(db: AsyncSession, tenant_id: str) -> None:
    await assert_tenant_module(db, tenant_id, MODULE_CONSIGNMENT_BOOKS)


async def assert_store_allowed(
    db: AsyncSession, tenant_id: str, store_id: str | None
) -> None:
    await assert_consignment_module(db, tenant_id)
    if not store_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "store_id required")
    cfg = await get_consignment_settings(db, tenant_id)
    allowed = cfg["store_ids"]
    if allowed and store_id not in allowed:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "此門店未開放寄賣書籍")


async def is_consignment_enabled_for_store(
    db: AsyncSession, tenant_id: str, store_id: str | None
) -> bool:
    mods = await get_tenant_modules(db, tenant_id)
    if not mods.get(MODULE_CONSIGNMENT_BOOKS):
        return False
    if not store_id:
        return False
    cfg = await get_consignment_settings(db, tenant_id)
    allowed = cfg["store_ids"]
    return not allowed or store_id in allowed


def calc_consignment_shares(line_total_cents: int, book_share_pct: int) -> tuple[int, int]:
    book_share = round(line_total_cents * book_share_pct / 100)
    restaurant_share = line_total_cents - book_share
    return book_share, restaurant_share


async def ensure_consignment_suppliers(db: AsyncSession, tenant_id: str) -> dict[str, Supplier]:
    """Return internal/external consignment suppliers, creating if missing."""
    rows = (
        await db.execute(
            select(Supplier).where(
                Supplier.tenant_id == tenant_id,
                Supplier.supplier_kind.in_(("consignment_internal", "consignment_external")),
                Supplier.deleted_at.is_(None),
            )
        )
    ).scalars().all()
    by_kind = {r.supplier_kind: r for r in rows}
    result: dict[str, Supplier] = {}
    specs = [
        ("consignment_internal", SUPPLIER_INTERNAL_CODE, "自有書籍（11碼）"),
        ("consignment_external", SUPPLIER_EXTERNAL_CODE, "他社書籍（8碼）"),
    ]
    for kind, code, name in specs:
        if kind in by_kind:
            result[kind] = by_kind[kind]
            continue
        sup = Supplier(
            tenant_id=tenant_id,
            code=code,
            name=name,
            supplier_kind=kind,
        )
        db.add(sup)
        await db.flush()
        result[kind] = sup
    return result
