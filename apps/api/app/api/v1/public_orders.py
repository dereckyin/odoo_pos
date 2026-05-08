"""Public (no-auth) endpoints for the customer Vue ordering page.

A request must carry ``token`` (the table's ``public_token``) to identify
the table and store. Tokens are opaque, high-entropy strings; rotating a
token instantly invalidates any previously printed QR for that table.

Inventory is intentionally NOT touched here. Orders submitted via this
path are stored as ``guest_orders`` with status ``submitted`` and need to
be accepted by kitchen staff (KDS) to begin preparation. The cashier
later resolves payment at the counter — see plan: "僅櫃台付".
"""
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from fastapi import APIRouter, HTTPException, status

from ...core.deps import DbSession
from ...models import (
    Category,
    DiningTable,
    GuestOrder,
    GuestOrderLine,
    Product,
    Store,
)
from ...schemas.guest_order import GuestOrderRead, GuestOrderSubmit
from ...schemas.public import (
    PublicCategory,
    PublicMenu,
    PublicMeta,
    PublicProduct,
)

router = APIRouter(prefix="/public", tags=["public-ordering"])


async def _resolve_table(db, token: str) -> tuple[DiningTable, Store]:
    table = (
        await db.execute(
            select(DiningTable).where(
                DiningTable.public_token == token,
                DiningTable.deleted_at.is_(None),
                DiningTable.is_active.is_(True),
            )
        )
    ).scalar_one_or_none()
    if not table:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "invalid or inactive table token")
    store = await db.get(Store, table.store_id)
    if not store or store.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    return table, store


@router.get("/menu/{token}", response_model=PublicMenu)
async def get_menu(token: str, db: DbSession):
    table, store = await _resolve_table(db, token)

    cats = (
        await db.execute(
            select(Category)
            .where(Category.deleted_at.is_(None))
            .order_by(Category.sort_order, Category.name)
        )
    ).scalars().all()
    products = (
        await db.execute(
            select(Product)
            .where(Product.deleted_at.is_(None), Product.is_active.is_(True))
            .order_by(Product.name)
        )
    ).scalars().all()

    return PublicMenu(
        meta=PublicMeta(
            table_id=table.id,
            table_label=table.label,
            store_id=store.id,
            store_name=store.name,
            store_address=store.address,
        ),
        categories=[
            PublicCategory(
                id=c.id, name=c.name, sort_order=c.sort_order, color=c.color, icon=c.icon
            )
            for c in cats
        ],
        products=[
            PublicProduct(
                id=p.id,
                sku=p.sku,
                name=p.name,
                price_cents=p.price_cents,
                category_id=p.category_id,
                image_url=p.image_url,
                unit=p.unit,
                description=p.description,
            )
            for p in products
        ],
    )


@router.post("/orders/{token}", response_model=GuestOrderRead, status_code=201)
async def submit_order(token: str, payload: GuestOrderSubmit, db: DbSession):
    if not payload.lines:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "empty cart")

    table, _store = await _resolve_table(db, token)

    # Resolve products and snapshot prices/names.
    product_ids = list({ln.product_id for ln in payload.lines})
    products = (
        await db.execute(
            select(Product).where(
                Product.id.in_(product_ids),
                Product.deleted_at.is_(None),
                Product.is_active.is_(True),
            )
        )
    ).scalars().all()
    by_id = {p.id: p for p in products}

    estimated = 0
    line_models: list[GuestOrderLine] = []
    for ln in payload.lines:
        p = by_id.get(ln.product_id)
        if not p:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"product not available: {ln.product_id}",
            )
        if ln.qty <= 0:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "qty must be > 0")
        line_total = round(p.price_cents * ln.qty)
        estimated += line_total
        line_models.append(
            GuestOrderLine(
                product_id=p.id,
                product_name=p.name,
                sku=p.sku,
                qty=ln.qty,
                unit_price_cents=p.price_cents,
                line_total_cents=line_total,
                note=ln.note,
            )
        )

    g = GuestOrder(
        store_id=table.store_id,
        table_id=table.id,
        status="submitted",
        customer_note=payload.customer_note,
        party_size=payload.party_size,
        estimated_subtotal_cents=estimated,
    )
    db.add(g)
    await db.flush()
    for lm in line_models:
        lm.order_id = g.id
        db.add(lm)
    await db.commit()

    g_full = (
        await db.execute(
            select(GuestOrder)
            .where(GuestOrder.id == g.id)
            .options(selectinload(GuestOrder.lines), selectinload(GuestOrder.table))
        )
    ).scalar_one()
    from .guest_orders import _to_read  # avoid circular import at module load

    return _to_read(g_full)


@router.get("/orders/{token}/{order_id}", response_model=GuestOrderRead)
async def get_order_status(token: str, order_id: str, db: DbSession):
    """Customer can poll this to see whether the kitchen has accepted /
    is preparing / is done. Token must match the table the order was
    placed at, to prevent simply enumerating other tables' orders."""
    table, _ = await _resolve_table(db, token)
    g = (
        await db.execute(
            select(GuestOrder)
            .where(GuestOrder.id == order_id, GuestOrder.table_id == table.id)
            .options(selectinload(GuestOrder.lines), selectinload(GuestOrder.table))
        )
    ).scalar_one_or_none()
    if not g:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    from .guest_orders import _to_read

    return _to_read(g)
