"""Public (no-auth) endpoints for the customer Vue ordering page.

A request must carry ``token`` (the table's ``public_token``) to identify
the table and store. Tokens are opaque, high-entropy strings; rotating a
token instantly invalidates any previously printed QR for that table.

The menu is **strictly tenant-scoped** to ``table.tenant_id`` so a QR code
in store A never leaks store B's catalogue.
"""
from datetime import datetime, timezone

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
    Member,
    Product,
    Store,
    TableSession,
)
from ...schemas.guest_order import GuestOrderRead, GuestOrderSubmit
from ...schemas.public import (
    PublicCategory,
    PublicMenu,
    PublicMeta,
    PublicProduct,
)
from ...services.category_tree import (
    build_category_maps,
    compute_path,
    descendant_ids,
)
from ...services.option_validation import (
    OptionValidationError,
    load_product_option_context,
    validate_line_options,
)
from ...services.public_options import load_public_product_options
from ...services.tenant_modules import assert_tenant_module, MODULE_ONLINE_ORDERING

router = APIRouter(prefix="/public", tags=["public-ordering"])


def _product_visible_on_public_menu(
    p: Product,
    cat_by_id: dict[str, Category],
) -> bool:
    if p.hide_from_public_ordering:
        return False
    if not p.category_id:
        return True
    cur = cat_by_id.get(p.category_id)
    while cur is not None:
        if cur.hide_from_public_ordering:
            return False
        cur = cat_by_id.get(cur.parent_id) if cur.parent_id else None
    return True


def _ancestor_ids(category_id: str, cat_by_id: dict[str, Category]) -> set[str]:
    out: set[str] = set()
    cur = cat_by_id.get(category_id)
    while cur is not None:
        out.add(cur.id)
        cur = cat_by_id.get(cur.parent_id) if cur.parent_id else None
    return out


def _root_has_visible_subtree(
    root_id: str,
    visible_cat_ids: set[str],
    children_map: dict[str | None, list],
) -> bool:
    for cid in descendant_ids(root_id, children_map):
        if cid in visible_cat_ids:
            return True
    return False


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
    now = datetime.now(timezone.utc)

    session = (
        await db.execute(
            select(TableSession)
            .where(
                TableSession.session_token == token,
                TableSession.status == "open",
            )
        )
    ).scalar_one_or_none()
    if session:
        if session.expires_at and session.expires_at < now:
            raise HTTPException(
                status.HTTP_410_GONE,
                "此 QR 已失效，請洽服務人員重新索取點餐碼",
            )
        table = await db.get(DiningTable, session.table_id)
        if not table or table.deleted_at or not table.is_active:
            raise HTTPException(
                status.HTTP_410_GONE,
                "此 QR 已失效，請洽服務人員重新索取點餐碼",
            )
        store = await db.get(Store, table.store_id)
        if not store or store.deleted_at:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
        await assert_tenant_module(db, table.tenant_id, MODULE_ONLINE_ORDERING)
        return table, store

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
        raise HTTPException(
            status.HTTP_410_GONE,
            "此 QR 已失效，請洽服務人員重新索取點餐碼",
        )
    store = await db.get(Store, table.store_id)
    if not store or store.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    if not getattr(store, "allow_static_table_qr", True):
        raise HTTPException(
            status.HTTP_410_GONE,
            "此 QR 已失效，請洽服務人員重新索取點餐碼",
        )
    await assert_tenant_module(db, table.tenant_id, MODULE_ONLINE_ORDERING)
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
    by_id, children_map = build_category_maps(cats)
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
    visible_products = [
        p for p in products if _product_visible_on_public_menu(p, cat_by_id)
    ]
    visible_cat_ids: set[str] = set()
    for p in visible_products:
        if p.category_id:
            visible_cat_ids.update(_ancestor_ids(p.category_id, cat_by_id))
    visible_cats = [c for c in cats if c.id in visible_cat_ids]
    root_cats = [c for c in visible_cats if c.parent_id is None]
    menu_roots = [
        c
        for c in root_cats
        if _root_has_visible_subtree(c.id, visible_cat_ids, children_map)
        and not c.hide_from_public_ordering
    ]
    options_by_product = await load_public_product_options(db, [p.id for p in visible_products])

    def _to_public_category(c: Category) -> PublicCategory:
        row = by_id[c.id]
        depth, _, path_label = compute_path(c.id, by_id)
        return PublicCategory(
            id=c.id,
            name=c.name,
            parent_id=c.parent_id,
            depth=depth,
            path_label=path_label,
            sort_order=c.sort_order,
            color=c.color,
            icon=c.icon,
        )

    return PublicMenu(
        meta=PublicMeta(
            table_id=table.id,
            table_label=table.label,
            store_id=store.id,
            store_name=store.name,
            store_address=store.address,
        ),
        categories=[_to_public_category(c) for c in visible_cats],
        root_category_ids=[c.id for c in menu_roots],
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
                option_groups=options_by_product.get(p.id, []),
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
    option_ctx = await load_product_option_context(db, table.tenant_id, product_ids)

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
        try:
            options_json = validate_line_options(
                p.id,
                p.price_cents,
                p.price_cents + sum(o.price_delta_cents for o in (ln.options or [])),
                ln.options,
                option_ctx,
            )
        except OptionValidationError as e:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e)) from e

        unit_price = p.price_cents + sum(o["price_delta_cents"] for o in options_json)
        line_total = round(unit_price * ln.qty)
        estimated += line_total
        line_models.append(
            GuestOrderLine(
                product_id=p.id,
                product_name=p.name,
                sku=p.sku,
                qty=ln.qty,
                unit_price_cents=unit_price,
                line_total_cents=line_total,
                note=ln.note,
                options_json=options_json or None,
            )
        )

    if payload.member_id:
        member = await db.get(Member, payload.member_id)
        if not member or member.tenant_id != table.tenant_id or member.deleted_at:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid member")

    g = GuestOrder(
        tenant_id=table.tenant_id,
        store_id=table.store_id,
        table_id=table.id,
        channel="table_qr",
        status="submitted",
        customer_note=payload.customer_note,
        party_size=payload.party_size,
        member_id=payload.member_id,
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
