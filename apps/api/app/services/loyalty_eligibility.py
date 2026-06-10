"""Resolve per-product loyalty eligibility (discount / earn / redeem).

Rules (mirrors the ``hide_from_*`` inheritance model):
- Product override (nullable bool): if set, it wins.
- Otherwise walk the category chain (product category + ancestors); if any
  category disables the flag (value False), the product is not eligible.
- Default: eligible (True).
"""
from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Category, Product

FLAGS = ("member_discount", "points_earn", "points_redeem")


@dataclass(frozen=True)
class LineEligibility:
    member_discount: bool = True
    points_earn: bool = True
    points_redeem: bool = True


def _category_chain_allows(
    category_id: str | None,
    cat_by_id: dict[str, Category],
    attr: str,
) -> bool:
    cur = cat_by_id.get(category_id) if category_id else None
    while cur is not None:
        if getattr(cur, attr) is False:
            return False
        cur = cat_by_id.get(cur.parent_id) if cur.parent_id else None
    return True


def _resolve_one(p: Product, cat_by_id: dict[str, Category]) -> LineEligibility:
    out: dict[str, bool] = {}
    for flag in FLAGS:
        override = getattr(p, f"{flag}_eligible")
        if override is not None:
            out[flag] = bool(override)
        else:
            out[flag] = _category_chain_allows(
                p.category_id, cat_by_id, f"{flag}_eligible"
            )
    return LineEligibility(
        member_discount=out["member_discount"],
        points_earn=out["points_earn"],
        points_redeem=out["points_redeem"],
    )


async def resolve_product_eligibility(
    db: AsyncSession,
    tenant_id: str,
    product_ids: list[str],
) -> dict[str, LineEligibility]:
    """Return ``{product_id: LineEligibility}`` for the given products."""
    if not product_ids:
        return {}
    cats = (
        await db.execute(
            select(Category).where(
                Category.tenant_id == tenant_id,
                Category.deleted_at.is_(None),
            )
        )
    ).scalars().all()
    cat_by_id = {c.id: c for c in cats}
    products = (
        await db.execute(
            select(Product).where(
                Product.id.in_(list(set(product_ids))),
                Product.tenant_id == tenant_id,
            )
        )
    ).scalars().all()
    return {p.id: _resolve_one(p, cat_by_id) for p in products}
