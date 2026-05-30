"""Resolve platform feed category for marketplace products."""

from __future__ import annotations

import unicodedata

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Category, MarketplaceCategory, MarketplaceCategoryAlias, Product

OTHER_CATEGORY_SLUG = "other"


def normalize_alias(text: str) -> str:
    s = unicodedata.normalize("NFKC", text.strip()).lower()
    return " ".join(s.split())


def root_category_name(category_id: str | None, categories_by_id: dict[str, Category]) -> str | None:
    if not category_id or category_id not in categories_by_id:
        return None
    cur = categories_by_id[category_id]
    while cur.parent_id and cur.parent_id in categories_by_id:
        cur = categories_by_id[cur.parent_id]
    return cur.name


class MarketplaceTaxonomy:
    def __init__(
        self,
        categories: list[MarketplaceCategory],
        alias_map: dict[str, str],
    ) -> None:
        self.categories = sorted(categories, key=lambda c: (c.sort_order, c.name))
        self.by_id = {c.id: c for c in categories}
        self.by_slug = {c.slug: c for c in categories}
        self.alias_map = alias_map
        self.other = self.by_slug.get(OTHER_CATEGORY_SLUG) or next(
            (c for c in categories if c.slug == OTHER_CATEGORY_SLUG),
            categories[-1] if categories else None,
        )

    def resolve(
        self,
        product: Product,
        tenant_categories: dict[str, Category],
    ) -> MarketplaceCategory | None:
        if not self.other:
            return None
        if product.marketplace_category_id and product.marketplace_category_id in self.by_id:
            return self.by_id[product.marketplace_category_id]
        root_name = root_category_name(product.category_id, tenant_categories)
        if root_name:
            hit = self.alias_map.get(normalize_alias(root_name))
            if hit and hit in self.by_id:
                return self.by_id[hit]
        return self.other


async def load_marketplace_taxonomy(db: AsyncSession) -> MarketplaceTaxonomy:
    categories = (
        await db.execute(
            select(MarketplaceCategory)
            .where(MarketplaceCategory.is_active.is_(True))
            .order_by(MarketplaceCategory.sort_order, MarketplaceCategory.name)
        )
    ).scalars().all()
    aliases = (await db.execute(select(MarketplaceCategoryAlias))).scalars().all()
    alias_map = {a.alias_normalized: a.marketplace_category_id for a in aliases}
    return MarketplaceTaxonomy(list(categories), alias_map)


async def load_tenant_categories_map(db: AsyncSession, tenant_ids: set[str]) -> dict[str, dict[str, Category]]:
    if not tenant_ids:
        return {}
    rows = (
        await db.execute(
            select(Category).where(
                Category.tenant_id.in_(tenant_ids),
                Category.deleted_at.is_(None),
            )
        )
    ).scalars().all()
    out: dict[str, dict[str, Category]] = {tid: {} for tid in tenant_ids}
    for cat in rows:
        out.setdefault(cat.tenant_id, {})[cat.id] = cat
    return out
