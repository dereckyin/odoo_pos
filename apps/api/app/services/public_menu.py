"""Shared helpers for building public menus (QR + marketplace)."""
from sqlalchemy import select

from ..models import Category, Product, Store
from ..schemas.public import PublicCategory, PublicMenu, PublicMeta, PublicProduct
from .category_tree import build_category_maps, compute_path, descendant_ids
from .public_options import load_public_product_options


def product_visible_on_public_menu(p: Product, cat_by_id: dict[str, Category]) -> bool:
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


def ancestor_ids(category_id: str, cat_by_id: dict[str, Category]) -> set[str]:
    out: set[str] = set()
    cur = cat_by_id.get(category_id)
    while cur is not None:
        out.add(cur.id)
        cur = cat_by_id.get(cur.parent_id) if cur.parent_id else None
    return out


def root_has_visible_subtree(
    root_id: str,
    visible_cat_ids: set[str],
    children_map: dict[str | None, list],
) -> bool:
    for cid in descendant_ids(root_id, children_map):
        if cid in visible_cat_ids:
            return True
    return False


async def build_public_menu_for_tenant(
    db,
    tenant_id: str,
    meta: PublicMeta,
) -> PublicMenu:
    cats = (
        await db.execute(
            select(Category)
            .where(
                Category.tenant_id == tenant_id,
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
                Product.tenant_id == tenant_id,
                Product.deleted_at.is_(None),
                Product.is_active.is_(True),
            )
            .order_by(Product.name)
        )
    ).scalars().all()
    visible_products = [p for p in products if product_visible_on_public_menu(p, cat_by_id)]
    visible_cat_ids: set[str] = set()
    for p in visible_products:
        if p.category_id:
            visible_cat_ids.update(ancestor_ids(p.category_id, cat_by_id))
    visible_cats = [c for c in cats if c.id in visible_cat_ids]
    root_cats = [c for c in visible_cats if c.parent_id is None]
    menu_roots = [
        c
        for c in root_cats
        if root_has_visible_subtree(c.id, visible_cat_ids, children_map)
        and not c.hide_from_public_ordering
    ]
    options_by_product = await load_public_product_options(db, [p.id for p in visible_products])

    def _to_public_category(c: Category) -> PublicCategory:
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
        meta=meta,
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


async def product_orderable_via_public_menu(db, p: Product) -> bool:
    if p.hide_from_public_ordering:
        return False
    if not p.category_id:
        return True
    c = await db.get(Category, p.category_id)
    if c is None or c.deleted_at is not None:
        return True
    return not c.hide_from_public_ordering
