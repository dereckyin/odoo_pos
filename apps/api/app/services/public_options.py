"""Build public-facing product option groups for menu display."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..models import OptionGroup, ProductOptionChoiceOverride, ProductOptionGroup
from ..schemas.public import PublicOptionChoice, PublicOptionGroup


async def load_public_product_options(
    db: AsyncSession, product_ids: list[str]
) -> dict[str, list[PublicOptionGroup]]:
    if not product_ids:
        return {}

    links = (
        await db.execute(
            select(ProductOptionGroup)
            .where(ProductOptionGroup.product_id.in_(product_ids))
            .options(
                selectinload(ProductOptionGroup.option_group).selectinload(OptionGroup.choices)
            )
            .order_by(ProductOptionGroup.sort_order)
        )
    ).scalars().unique().all()

    overrides = (
        await db.execute(
            select(ProductOptionChoiceOverride).where(
                ProductOptionChoiceOverride.product_id.in_(product_ids)
            )
        )
    ).scalars().all()
    override_map: dict[tuple[str, str], ProductOptionChoiceOverride] = {
        (o.product_id, o.option_choice_id): o for o in overrides
    }

    result: dict[str, list[PublicOptionGroup]] = {pid: [] for pid in product_ids}
    for link in links:
        group = link.option_group
        if group.deleted_at is not None:
            continue
        is_required = link.is_required if link.is_required is not None else group.is_required
        choices: list[PublicOptionChoice] = []
        for c in sorted(group.choices, key=lambda x: x.sort_order):
            if c.deleted_at is not None or not c.is_active:
                continue
            ov = override_map.get((link.product_id, c.id))
            if ov and ov.is_hidden:
                continue
            price = ov.price_delta_cents if ov and ov.price_delta_cents is not None else c.price_delta_cents
            choices.append(
                PublicOptionChoice(
                    id=c.id,
                    name=c.name,
                    price_delta_cents=price,
                    is_default=c.is_default,
                )
            )
        if not choices:
            continue
        result[link.product_id].append(
            PublicOptionGroup(
                id=group.id,
                name=group.name,
                selection_type=group.selection_type,
                is_required=is_required,
                min_selections=group.min_selections,
                max_selections=group.max_selections,
                sort_order=link.sort_order,
                choices=choices,
            )
        )
    return result
