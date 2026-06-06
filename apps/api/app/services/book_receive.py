"""Consignment book inbound: TAAZE lookup, catalog upsert, inventory receive."""
from __future__ import annotations

from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..models import InventoryLevel, InventoryMovement, Product
from .book_catalog import product_to_book_read, upsert_book_from_barcode
from .book_lookup import BookLookupNotFoundError, UnsupportedBarcodeError, lookup_barcode


async def _apply_movement(db: AsyncSession, m: InventoryMovement) -> None:
    level = (
        await db.execute(
            select(InventoryLevel).where(
                InventoryLevel.store_id == m.store_id,
                InventoryLevel.product_id == m.product_id,
            )
        )
    ).scalar_one_or_none()
    if level is None:
        level = InventoryLevel(
            tenant_id=m.tenant_id,
            store_id=m.store_id,
            product_id=m.product_id,
            on_hand=m.qty_delta,
        )
        db.add(level)
    else:
        level.on_hand = float(level.on_hand) + float(m.qty_delta)


async def receive_book_by_barcode(
    db: AsyncSession,
    tenant_id: str,
    store_id: str,
    barcode: str,
    qty: float,
    user_id: str | None,
) -> tuple[Product, float]:
    """Lookup TAAZE, upsert master, add store inventory. Returns product and on_hand."""
    try:
        lookup = lookup_barcode(barcode)
    except UnsupportedBarcodeError:
        raise
    except BookLookupNotFoundError:
        raise

    product = await upsert_book_from_barcode(db, tenant_id, barcode.strip(), lookup)

    m = InventoryMovement(
        id=str(uuid4()),
        tenant_id=tenant_id,
        store_id=store_id,
        product_id=product.id,
        qty_delta=float(qty),
        reason="consignment_receive",
        ref_type="book_receive",
        ref_id=product.id,
        user_id=user_id,
    )
    db.add(m)
    await _apply_movement(db, m)
    await db.flush()

    level = (
        await db.execute(
            select(InventoryLevel).where(
                InventoryLevel.store_id == store_id,
                InventoryLevel.product_id == product.id,
            )
        )
    ).scalar_one_or_none()
    on_hand = float(level.on_hand) if level else float(qty)

    product = (
        await db.execute(
            select(Product)
            .where(Product.id == product.id)
            .options(selectinload(Product.barcodes), selectinload(Product.book_detail))
        )
    ).scalar_one()
    return product, on_hand


def product_read_after_receive(product: Product, on_hand: float) -> dict:
    return product_to_book_read(product, on_hand)
