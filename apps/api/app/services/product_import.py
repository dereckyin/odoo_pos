"""Product CSV import helpers."""

from __future__ import annotations

import csv
import re
from dataclasses import dataclass, field
from io import StringIO

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..core.usage import assert_can_add_product
from ..models import Category, Product, ProductBarcode
from .category_tree import build_category_maps, compute_path, load_tenant_categories

IMPORT_CSV_COLUMNS = [
    "sku",
    "name",
    "price_cents",
    "category_path",
    "barcode",
    "is_weighted",
    "unit",
]

IMPORT_CSV_SAMPLE_ROWS = [
    {
        "sku": "4710001000017",
        "name": "可口可樂 350ml",
        "price_cents": "25",
        "category_path": "飲料",
        "barcode": "4710001000017",
        "is_weighted": "0",
        "unit": "個",
    },
    {
        "sku": "DRINK-BT-001",
        "name": "珍珠奶茶",
        "price_cents": "55",
        "category_path": "飲料 / 手搖 / 奶茶",
        "barcode": "DRINK-BT-001",
        "is_weighted": "0",
        "unit": "杯",
    },
    {
        "sku": "4710003000015",
        "name": "御便當-雞腿",
        "price_cents": "95",
        "category_path": "便當/熟食",
        "barcode": "4710003000015",
        "is_weighted": "0",
        "unit": "個",
    },
]


@dataclass
class ImportRowError:
    row: int
    sku: str
    message: str


@dataclass
class ImportResult:
    created: int = 0
    updated: int = 0
    skipped: int = 0
    errors: list[ImportRowError] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "created": self.created,
            "updated": self.updated,
            "skipped": self.skipped,
            "errors": [
                {"row": e.row, "sku": e.sku, "message": e.message} for e in self.errors
            ],
        }


def normalize_category_path(raw: str) -> str:
    parts = [p.strip() for p in re.split(r"\s*/\s*", raw.strip()) if p.strip()]
    return " / ".join(parts)


def match_category_path(raw: str, path_lookup: dict[str, str]) -> str | None:
    text = raw.strip()
    if not text:
        return None
    if text in path_lookup:
        return text
    normalized = normalize_category_path(text)
    return normalized if normalized in path_lookup else None


def build_path_lookup(categories: list[Category]) -> dict[str, str]:
    by_id, _ = build_category_maps(categories)
    lookup: dict[str, str] = {}
    for cid in by_id:
        _, _, path_label = compute_path(cid, by_id)
        lookup[path_label] = cid
    return lookup


def resolve_category_id(
    row: dict[str, str],
    path_lookup: dict[str, str],
    tenant_category_ids: set[str],
) -> tuple[str | None, str | None]:
    category_path = (row.get("category_path") or "").strip()
    if category_path:
        matched = match_category_path(category_path, path_lookup)
        if matched is None:
            normalized = normalize_category_path(category_path)
            return None, f"分類路徑不存在：{normalized}"
        return path_lookup[matched], None

    category_id = (row.get("category_id") or "").strip()
    if category_id:
        if category_id not in tenant_category_ids:
            return None, f"分類 ID 不存在或不屬於此商家：{category_id}"
        return category_id, None

    return None, None


def _parse_bool(raw: str | None) -> bool:
    return str(raw or "").lower() in ("1", "true", "yes")


def _parse_price_cents(raw: str | None) -> tuple[int | None, str | None]:
    text = (raw or "").strip()
    if not text:
        return 0, None
    try:
        return int(text), None
    except ValueError:
        return None, f"price_cents 格式錯誤：{text}"


def render_import_template_csv() -> str:
    buf = StringIO()
    writer = csv.DictWriter(buf, fieldnames=IMPORT_CSV_COLUMNS, lineterminator="\n")
    writer.writeheader()
    for row in IMPORT_CSV_SAMPLE_ROWS:
        writer.writerow(row)
    return "\ufeff" + buf.getvalue()


async def _ensure_barcodes(
    db: AsyncSession, product: Product, barcodes: list[str], tenant_id: str
) -> None:
    existing_rows = (
        await db.execute(
            select(ProductBarcode).where(
                ProductBarcode.product_id == product.id,
                ProductBarcode.tenant_id == tenant_id,
            )
        )
    ).scalars().all()
    existing = {b.barcode: b for b in existing_rows}
    target = set(barcodes)
    for code, row in list(existing.items()):
        if code not in target:
            await db.delete(row)
    for code in target - set(existing.keys()):
        db.add(ProductBarcode(tenant_id=tenant_id, product_id=product.id, barcode=code))


async def import_products_from_csv(
    db: AsyncSession,
    tenant_id: str,
    rows: list[dict[str, str]],
) -> ImportResult:
    categories = await load_tenant_categories(db, tenant_id)
    path_lookup = build_path_lookup(categories)
    tenant_category_ids = {c.id for c in categories}

    result = ImportResult()
    for row_num, row in enumerate(rows, start=2):
        sku = (row.get("sku") or "").strip()
        if not sku:
            continue

        price_cents, price_err = _parse_price_cents(row.get("price_cents"))
        if price_err:
            result.skipped += 1
            result.errors.append(ImportRowError(row=row_num, sku=sku, message=price_err))
            continue

        category_id, cat_err = resolve_category_id(row, path_lookup, tenant_category_ids)
        if cat_err:
            result.skipped += 1
            result.errors.append(ImportRowError(row=row_num, sku=sku, message=cat_err))
            continue

        existing = (
            await db.execute(
                select(Product)
                .where(Product.tenant_id == tenant_id, Product.sku == sku)
                .options(selectinload(Product.barcodes))
            )
        ).scalar_one_or_none()

        defaults = dict(
            sku=sku,
            name=(row.get("name") or sku).strip(),
            price_cents=price_cents,
            category_id=category_id,
            is_weighted=_parse_bool(row.get("is_weighted")),
            unit=(row.get("unit") or "個").strip() or "個",
            is_active=True,
        )

        if existing:
            for k, v in defaults.items():
                setattr(existing, k, v)
            p = existing
            result.updated += 1
        else:
            try:
                await assert_can_add_product(db, tenant_id)
            except HTTPException as exc:
                detail = exc.detail if isinstance(exc.detail, str) else str(exc.detail)
                result.skipped += 1
                result.errors.append(ImportRowError(row=row_num, sku=sku, message=detail))
                continue
            p = Product(tenant_id=tenant_id, **defaults)
            db.add(p)
            result.created += 1

        await db.flush()
        bc = (row.get("barcode") or "").strip()
        if bc:
            await _ensure_barcodes(db, p, [bc], tenant_id)

    return result
