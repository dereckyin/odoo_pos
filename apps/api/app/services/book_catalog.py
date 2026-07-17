"""Create / find consignment book products."""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..models import BookDetail, Category, InventoryLevel, Product, ProductBarcode
from .book_lookup import (
    BookLookupResult,
    UnsupportedBarcodeError,
    default_sell_price_cents,
    lookup_barcode,
)
from .consignment_books import (
    CONSIGNMENT_CATEGORY_NAME,
    PRODUCT_KIND_CONSIGNMENT,
    ensure_consignment_suppliers,
)


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def _find_or_create_child_category(
    db: AsyncSession,
    tenant_id: str,
    name: str,
    parent_id: str | None,
    *,
    hide_from_pos_browse: bool = False,
) -> Category:
    stmt = select(Category).where(
        Category.tenant_id == tenant_id,
        Category.name == name,
        Category.parent_id == parent_id if parent_id else Category.parent_id.is_(None),
        Category.deleted_at.is_(None),
    )
    row = (await db.execute(stmt)).scalar_one_or_none()
    if row:
        return row
    cat = Category(
        tenant_id=tenant_id,
        name=name,
        parent_id=parent_id,
        sort_order=860,
        hide_from_public_ordering=True,
        hide_from_pos_browse=hide_from_pos_browse,
    )
    db.add(cat)
    await db.flush()
    return cat


async def ensure_book_category_for_lookup(
    db: AsyncSession, tenant_id: str, lookup: BookLookupResult
) -> Category:
    """Map TAAZE catName1 / catName under the consignment root category."""
    root = await ensure_consignment_category(db, tenant_id)
    main = (lookup.category_main or "").strip()
    sub = (lookup.category_sub or "").strip()
    if not main:
        return root
    parent = await _find_or_create_child_category(db, tenant_id, main, root.id)
    if not sub or sub == main:
        return parent
    return await _find_or_create_child_category(db, tenant_id, sub, parent.id)


async def ensure_consignment_category(db: AsyncSession, tenant_id: str) -> Category:
    row = (
        await db.execute(
            select(Category).where(
                Category.tenant_id == tenant_id,
                Category.name == CONSIGNMENT_CATEGORY_NAME,
                Category.parent_id.is_(None),
                Category.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if row:
        return row
    cat = Category(
        tenant_id=tenant_id,
        name=CONSIGNMENT_CATEGORY_NAME,
        sort_order=850,
        hide_from_public_ordering=True,
        hide_from_pos_browse=False,
    )
    db.add(cat)
    await db.flush()
    return cat


async def find_book_by_barcode(db: AsyncSession, tenant_id: str, barcode: str) -> Product | None:
    code = barcode.strip()
    row = (
        await db.execute(
            select(Product)
            .join(BookDetail, BookDetail.product_id == Product.id)
            .where(
                Product.tenant_id == tenant_id,
                Product.deleted_at.is_(None),
                BookDetail.barcode == code,
            )
            .options(selectinload(Product.barcodes), selectinload(Product.book_detail))
        )
    ).scalar_one_or_none()
    if row:
        return row
    row = (
        await db.execute(
            select(Product)
            .join(ProductBarcode, ProductBarcode.product_id == Product.id)
            .where(
                Product.tenant_id == tenant_id,
                Product.deleted_at.is_(None),
                ProductBarcode.barcode == code,
                Product.product_kind == PRODUCT_KIND_CONSIGNMENT,
            )
            .options(selectinload(Product.barcodes), selectinload(Product.book_detail))
        )
    ).scalar_one_or_none()
    return row


async def upsert_book_from_barcode(
    db: AsyncSession, tenant_id: str, barcode: str, lookup: BookLookupResult | None = None
) -> Product:
    existing = await find_book_by_barcode(db, tenant_id, barcode)
    if existing:
        if lookup is None:
            lookup = lookup_barcode(barcode)
        # Refresh sell/list price from lookup (TWD stores whole dollars in *_cents).
        existing.price_cents = default_sell_price_cents(lookup)
        existing.updated_at = _now()
        bd = existing.book_detail
        if bd is not None:
            bd.list_price_cents = lookup.list_price_cents
            bd.sale_disc = lookup.sale_disc
            if lookup.author:
                bd.author = lookup.author
            bd.updated_at = _now()
        await db.flush()
        return existing

    if lookup is None:
        lookup = lookup_barcode(barcode)

    category = await ensure_book_category_for_lookup(db, tenant_id, lookup)
    suppliers = await ensure_consignment_suppliers(db, tenant_id)
    supplier = (
        suppliers["consignment_internal"]
        if lookup.barcode_kind == "internal_11"
        else suppliers["consignment_external"]
    )

    desc_parts: list[str] = []
    if lookup.translator:
        desc_parts.append(f"譯者：{lookup.translator}")
    if lookup.publish_date:
        desc_parts.append(f"出版：{lookup.publish_date}")
    if lookup.pages:
        desc_parts.append(f"{lookup.pages} 頁")
    if lookup.is_second_hand:
        desc_parts.append("二手")

    product = Product(
        tenant_id=tenant_id,
        sku=barcode.strip(),
        name=lookup.title,
        price_cents=default_sell_price_cents(lookup),
        category_id=category.id,
        image_url=lookup.image_url,
        description=" · ".join(desc_parts) if desc_parts else None,
        tax_rate=0.05,
        unit="本",
        is_active=True,
        hide_from_public_ordering=True,
        hide_from_pos_browse=True,
        product_kind=PRODUCT_KIND_CONSIGNMENT,
        updated_at=_now(),
    )
    db.add(product)
    await db.flush()
    db.add(ProductBarcode(tenant_id=tenant_id, product_id=product.id, barcode=barcode.strip()))
    db.add(
        BookDetail(
            tenant_id=tenant_id,
            product_id=product.id,
            barcode=barcode.strip(),
            barcode_kind=lookup.barcode_kind,
            supplier_id=supplier.id,
            author=lookup.author,
            publisher=lookup.publisher,
            isbn=lookup.isbn,
            list_price_cents=lookup.list_price_cents,
            sale_disc=lookup.sale_disc,
            updated_at=_now(),
        )
    )
    await db.flush()
    return (
        await db.execute(
            select(Product)
            .where(Product.id == product.id)
            .options(selectinload(Product.barcodes), selectinload(Product.book_detail))
        )
    ).scalar_one()


async def book_on_hand_by_product(
    db: AsyncSession,
    tenant_id: str,
    product_ids: list[str],
    store_id: str | None = None,
) -> dict[str, float]:
    """Return on_hand per product; sums all stores when store_id is omitted."""
    if not product_ids:
        return {}
    stmt = select(InventoryLevel).where(
        InventoryLevel.tenant_id == tenant_id,
        InventoryLevel.product_id.in_(product_ids),
    )
    if store_id:
        stmt = stmt.where(InventoryLevel.store_id == store_id)
    levels = (await db.execute(stmt)).scalars().all()
    totals: dict[str, float] = {}
    for lv in levels:
        totals[lv.product_id] = totals.get(lv.product_id, 0.0) + float(lv.on_hand)
    return totals


async def search_books(
    db: AsyncSession,
    tenant_id: str,
    q: str,
    store_id: str | None,
    limit: int = 50,
) -> list[tuple[Product, float | None]]:
    like = f"%{q.strip()}%"
    stmt = (
        select(Product)
        .join(BookDetail, BookDetail.product_id == Product.id)
        .where(
            Product.tenant_id == tenant_id,
            Product.deleted_at.is_(None),
            Product.product_kind == PRODUCT_KIND_CONSIGNMENT,
            or_(
                Product.name.ilike(like),
                Product.sku.ilike(like),
                BookDetail.barcode == q.strip(),
                BookDetail.author.ilike(like),
                BookDetail.isbn.ilike(like),
            ),
        )
        .options(selectinload(Product.barcodes), selectinload(Product.book_detail))
        .order_by(Product.name)
        .limit(limit)
    )
    products = (await db.execute(stmt)).scalars().unique().all()
    on_hand_map = await book_on_hand_by_product(
        db, tenant_id, [p.id for p in products], store_id
    )
    return [(p, on_hand_map.get(p.id, 0.0)) for p in products]


def product_to_book_read(product: Product, on_hand: float | None = None) -> dict:
    bd = product.book_detail
    return {
        "id": product.id,
        "sku": product.sku,
        "name": product.name,
        "price_cents": product.price_cents,
        "category_id": product.category_id,
        "image_url": product.image_url,
        "unit": product.unit,
        "product_kind": product.product_kind,
        "barcodes": [b.barcode for b in product.barcodes],
        "author": bd.author if bd else None,
        "publisher": bd.publisher if bd else None,
        "isbn": bd.isbn if bd else None,
        "list_price_cents": bd.list_price_cents if bd else None,
        "sale_disc": bd.sale_disc if bd else None,
        "on_hand": on_hand,
    }


__all__ = [
    "UnsupportedBarcodeError",
    "lookup_barcode",
    "find_book_by_barcode",
    "upsert_book_from_barcode",
    "search_books",
    "product_to_book_read",
    "ensure_consignment_category",
    "ensure_book_category_for_lookup",
]
