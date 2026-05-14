"""Public (no-auth) endpoints for the customer Vue ordering page.

A request must carry ``token`` (the table's ``public_token``) to identify
the table and store. Tokens are opaque, high-entropy strings; rotating a
token instantly invalidates any previously printed QR for that table.

The menu is **strictly tenant-scoped** to ``table.tenant_id`` so a QR code
in store A never leaks store B's catalogue.
"""
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from fastapi import APIRouter, HTTPException, Request, status

from ...core.deps import DbSession
from ...core.ratelimit import per_ip
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


def _product_visible_on_public_menu(p: Product, cat_by_id: dict[str, Category]) -> bool:
    if p.hide_from_public_ordering:
        return False
    if p.category_id:
        c = cat_by_id.get(p.category_id)
        if c is not None and c.hide_from_public_ordering:
            return False
    return True


async def _product_orderable_via_public_menu(db, p: Product) -> bool:
    if p.hide_from_public_ordering:
        return False
    if not p.category_id:
        return True
    c = await db.get(Category, p.category_id)
    if c is None or c.deleted_at is not None:
        return True
    return not c.hide_from_public_ordering


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
@per_ip("60/minute")
async def get_menu(request: Request, token: str, db: DbSession):
    table, store = await _resolve_table(db, token)

    cats = (
        await db.execute(
            select(Category)
            .where(
                Category.tenant_id == table.tenant_id,
                Category.deleted_at.is_(None),
            )
            .order_by(Category.sort_order, Category.name)
        )
    ).scalars().all()
    cat_by_id = {c.id: c for c in cats}
    products = (
        await db.execute(
            select(Product)
            .where(
                Product.tenant_id == table.tenant_id,
                Product.deleted_at.is_(None),
                Product.is_active.is_(True),
            )
            .order_by(Product.name)
        )
    ).scalars().all()
    visible_products = [p for p in products if _product_visible_on_public_menu(p, cat_by_id)]
    visible_cat_ids = {p.category_id for p in visible_products if p.category_id}
    visible_cats = [c for c in cats if c.id in visible_cat_ids]

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
            for c in visible_cats
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
            for p in visible_products
        ],
    )


@router.post("/orders/{token}", response_model=GuestOrderRead, status_code=201)
@per_ip("30/minute")
async def submit_order(
    request: Request, token: str, payload: GuestOrderSubmit, db: DbSession
):
    if not payload.lines:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "empty cart")

    table, _store = await _resolve_table(db, token)

    product_ids = list({ln.product_id for ln in payload.lines})
    products = (
        await db.execute(
            select(Product).where(
                Product.id.in_(product_ids),
                Product.tenant_id == table.tenant_id,
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
        if not await _product_orderable_via_public_menu(db, p):
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"product not available for table ordering: {ln.product_id}",
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
        tenant_id=table.tenant_id,
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
    from .guest_orders import _to_read

    return _to_read(g_full)


@router.get("/orders/{token}/{order_id}", response_model=GuestOrderRead)
@per_ip("120/minute")
async def get_order_status(
    request: Request, token: str, order_id: str, db: DbSession
):
    """Customer can poll this to see whether the kitchen has accepted /
    is preparing / is done. Token must match the table the order was
    placed at, to prevent simply enumerating other tables' orders."""
    table, _ = await _resolve_table(db, token)
    g = (
        await db.execute(
            select(GuestOrder)
            .where(
                GuestOrder.id == order_id,
                GuestOrder.table_id == table.id,
                GuestOrder.tenant_id == table.tenant_id,
            )
            .options(selectinload(GuestOrder.lines), selectinload(GuestOrder.table))
        )
    ).scalar_one_or_none()
    if not g:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    from .guest_orders import _to_read

    return _to_read(g)
