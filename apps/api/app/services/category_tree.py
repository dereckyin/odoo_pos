"""Category tree helpers: path computation, validation, nested tree build."""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Category, Product
from ..schemas.product import CategoryRead, CategoryTreeNode

MAX_CATEGORY_DEPTH = 2  # 0=root, 1=child, 2=grandchild (3 levels total)


class CategoryTreeError(ValueError):
    pass


@dataclass
class _CatRow:
    id: str
    tenant_id: str
    name: str
    parent_id: str | None
    sort_order: int
    color: str | None
    icon: str | None
    hide_from_public_ordering: bool
    hide_from_pos_browse: bool
    updated_at: object
    deleted_at: object | None


def _as_row(c: Category) -> _CatRow:
    return _CatRow(
        id=c.id,
        tenant_id=c.tenant_id,
        name=c.name,
        parent_id=c.parent_id,
        sort_order=c.sort_order,
        color=c.color,
        icon=c.icon,
        hide_from_public_ordering=c.hide_from_public_ordering,
        hide_from_pos_browse=c.hide_from_pos_browse,
        updated_at=c.updated_at,
        deleted_at=c.deleted_at,
    )


def build_category_maps(
    categories: list[Category],
) -> tuple[dict[str, _CatRow], dict[str | None, list[_CatRow]]]:
    rows = [_as_row(c) for c in categories if c.deleted_at is None]
    by_id = {r.id: r for r in rows}
    children_map: dict[str | None, list[_CatRow]] = {}
    for r in rows:
        children_map.setdefault(r.parent_id, []).append(r)
    for key in children_map:
        children_map[key].sort(key=lambda x: (x.sort_order, x.name))
    return by_id, children_map


def compute_path(
    category_id: str,
    by_id: dict[str, _CatRow],
) -> tuple[int, list[str], str]:
    names: list[str] = []
    cur = by_id.get(category_id)
    depth = 0
    while cur is not None:
        names.insert(0, cur.name)
        depth += 1
        if cur.parent_id is None:
            break
        cur = by_id.get(cur.parent_id)
    return depth - 1, names, " / ".join(names)


def category_to_read(
    row: _CatRow,
    by_id: dict[str, _CatRow],
    children_map: dict[str | None, list[_CatRow]],
) -> CategoryRead:
    depth, path_names, path_label = compute_path(row.id, by_id)
    has_children = bool(children_map.get(row.id))
    return CategoryRead(
        id=row.id,
        tenant_id=row.tenant_id,
        name=row.name,
        parent_id=row.parent_id,
        sort_order=row.sort_order,
        color=row.color,
        icon=row.icon,
        hide_from_public_ordering=row.hide_from_public_ordering,
        hide_from_pos_browse=row.hide_from_pos_browse,
        updated_at=row.updated_at,  # type: ignore[arg-type]
        deleted_at=row.deleted_at,  # type: ignore[arg-type]
        depth=depth,
        path_names=path_names,
        path_label=path_label,
        has_children=has_children,
    )


def build_tree(
    categories: list[Category],
    parent_id: str | None = None,
) -> list[CategoryTreeNode]:
    by_id, children_map = build_category_maps(categories)

    def _node(row: _CatRow) -> CategoryTreeNode:
        base = category_to_read(row, by_id, children_map)
        kids = children_map.get(row.id, [])
        return CategoryTreeNode(
            **base.model_dump(),
            children=[_node(k) for k in kids],
        )

    roots = children_map.get(parent_id, [])
    return [_node(r) for r in roots]


def descendant_ids(category_id: str, children_map: dict[str | None, list[_CatRow]]) -> set[str]:
    out = {category_id}

    def walk(cid: str) -> None:
        for child in children_map.get(cid, []):
            out.add(child.id)
            walk(child.id)

    walk(category_id)
    return out


def validate_parent_assignment(
    category_id: str | None,
    parent_id: str | None,
    tenant_id: str,
    by_id: dict[str, _CatRow],
    children_map: dict[str | None, list[_CatRow]],
) -> None:
    if parent_id is None:
        return
    if category_id and parent_id == category_id:
        raise CategoryTreeError("category cannot be its own parent")
    parent = by_id.get(parent_id)
    if not parent or parent.tenant_id != tenant_id:
        raise CategoryTreeError("parent category not found")
    parent_depth, _, _ = compute_path(parent_id, by_id)
    if parent_depth >= MAX_CATEGORY_DEPTH:
        raise CategoryTreeError(f"maximum category depth is {MAX_CATEGORY_DEPTH + 1} levels")
    if category_id:
        # Would parent become a descendant of category?
        if parent_id in descendant_ids(category_id, children_map):
            raise CategoryTreeError("cannot set parent to a descendant category")


async def load_tenant_categories(db: AsyncSession, tenant_id: str) -> list[Category]:
    return (
        await db.execute(
            select(Category).where(
                Category.tenant_id == tenant_id,
                Category.deleted_at.is_(None),
            )
        )
    ).scalars().all()


async def validate_category_parent(
    db: AsyncSession,
    tenant_id: str,
    category_id: str | None,
    parent_id: str | None,
) -> None:
    cats = await load_tenant_categories(db, tenant_id)
    by_id, children_map = build_category_maps(cats)
    validate_parent_assignment(category_id, parent_id, tenant_id, by_id, children_map)


async def enrich_category_read(db: AsyncSession, category: Category) -> CategoryRead:
    cats = await load_tenant_categories(db, category.tenant_id)
    by_id, children_map = build_category_maps(cats)
    row = by_id.get(category.id)
    if not row:
        row = _as_row(category)
    return category_to_read(row, by_id, children_map)


async def assert_category_deletable(db: AsyncSession, category: Category) -> None:
    cats = await load_tenant_categories(db, category.tenant_id)
    by_id, children_map = build_category_maps(cats)
    if children_map.get(category.id):
        raise CategoryTreeError("category has child categories; delete or move them first")
    product_count = (
        await db.execute(
            select(Product.id).where(
                Product.tenant_id == category.tenant_id,
                Product.category_id == category.id,
                Product.deleted_at.is_(None),
            ).limit(1)
        )
    ).first()
    if product_count:
        raise CategoryTreeError("category has products assigned; reassign products first")
