"""Validate product option selections on order lines."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..models import (
    OptionChoice,
    OptionGroup,
    Product,
    ProductOptionChoiceOverride,
    ProductOptionGroup,
)
from ..schemas.option import SelectedOptionSnapshot


class OptionValidationError(ValueError):
    pass


async def load_product_option_context(
    db: AsyncSession, tenant_id: str, product_ids: list[str]
) -> dict[str, dict]:
    """Return per-product option configuration for validation."""
    if not product_ids:
        return {}

    links = (
        await db.execute(
            select(ProductOptionGroup)
            .join(Product, Product.id == ProductOptionGroup.product_id)
            .where(
                Product.id.in_(product_ids),
                Product.tenant_id == tenant_id,
            )
            .options(
                selectinload(ProductOptionGroup.option_group).selectinload(OptionGroup.choices)
            )
            .order_by(ProductOptionGroup.sort_order)
        )
    ).scalars().unique().all()

    overrides = (
        await db.execute(
            select(ProductOptionChoiceOverride)
            .join(Product, Product.id == ProductOptionChoiceOverride.product_id)
            .where(
                Product.id.in_(product_ids),
                Product.tenant_id == tenant_id,
            )
        )
    ).scalars().all()

    override_map: dict[tuple[str, str], ProductOptionChoiceOverride] = {
        (o.product_id, o.option_choice_id): o for o in overrides
    }

    ctx: dict[str, dict] = {pid: {"groups": [], "overrides": {}} for pid in product_ids}
    for link in links:
        ctx[link.product_id]["groups"].append(link)
        for o in overrides:
            if o.product_id == link.product_id:
                ctx[link.product_id]["overrides"][o.option_choice_id] = o

    return ctx


def _effective_required(link: ProductOptionGroup, group: OptionGroup) -> bool:
    return link.is_required if link.is_required is not None else group.is_required


def _choice_visible(product_id: str, choice: OptionChoice, overrides: dict) -> bool:
    ov = overrides.get(choice.id)
    if ov and ov.is_hidden:
        return False
    return choice.is_active and choice.deleted_at is None


def _effective_price(
    product_id: str, choice: OptionChoice, overrides: dict
) -> int:
    ov = overrides.get(choice.id)
    if ov and ov.price_delta_cents is not None:
        return ov.price_delta_cents
    return choice.price_delta_cents


def validate_line_options(
    product_id: str,
    product_price_cents: int,
    unit_price_cents: int,
    options: list[SelectedOptionSnapshot] | list[dict] | None,
    ctx: dict,
) -> list[dict]:
    """Validate selections and return normalized snapshot list."""
    product_ctx = ctx.get(product_id, {"groups": [], "overrides": {}})
    groups: list[ProductOptionGroup] = product_ctx["groups"]
    overrides: dict = product_ctx["overrides"]

    snapshots: list[SelectedOptionSnapshot] = []
    if options:
        for raw in options:
            if isinstance(raw, SelectedOptionSnapshot):
                snapshots.append(raw)
            elif isinstance(raw, dict):
                snapshots.append(SelectedOptionSnapshot(**raw))

    if not groups:
        if snapshots:
            raise OptionValidationError(f"product {product_id} does not accept options")
        return []

    # Build lookup: group_id -> selected choices
    by_group: dict[str, list[SelectedOptionSnapshot]] = {}
    for snap in snapshots:
        by_group.setdefault(snap.group_id, []).append(snap)

    expected_price = product_price_cents
    normalized: list[dict] = []

    for link in groups:
        group = link.option_group
        if group.deleted_at is not None:
            continue

        visible_choices = {
            c.id: c
            for c in group.choices
            if _choice_visible(product_id, c, overrides)
        }
        selected = by_group.get(group.id, [])
        required = _effective_required(link, group)

        if group.selection_type == "single":
            if required and len(selected) != 1:
                raise OptionValidationError(
                    f"product {product_id}: group '{group.name}' requires exactly one selection"
                )
            if len(selected) > 1:
                raise OptionValidationError(
                    f"product {product_id}: group '{group.name}' allows only one selection"
                )
        else:
            count = len(selected)
            min_sel = group.min_selections if group.min_selections else (1 if required else 0)
            max_sel = group.max_selections
            if count < min_sel:
                raise OptionValidationError(
                    f"product {product_id}: group '{group.name}' requires at least {min_sel} selections"
                )
            if max_sel is not None and count > max_sel:
                raise OptionValidationError(
                    f"product {product_id}: group '{group.name}' allows at most {max_sel} selections"
                )

        for snap in selected:
            if snap.group_id != group.id:
                raise OptionValidationError(
                    f"product {product_id}: choice '{snap.choice_name}' belongs to wrong group"
                )
            choice = visible_choices.get(snap.choice_id)
            if not choice:
                raise OptionValidationError(
                    f"product {product_id}: invalid or hidden choice '{snap.choice_id}'"
                )
            price = _effective_price(product_id, choice, overrides)
            if snap.price_delta_cents != price:
                raise OptionValidationError(
                    f"product {product_id}: price mismatch for '{choice.name}'"
                )
            expected_price += price
            normalized.append(
                {
                    "group_id": group.id,
                    "group_name": group.name,
                    "choice_id": choice.id,
                    "choice_name": choice.name,
                    "price_delta_cents": price,
                }
            )

    # Ensure no extra groups were submitted
    linked_group_ids = {link.option_group_id for link in groups if link.option_group.deleted_at is None}
    for gid in by_group:
        if gid not in linked_group_ids:
            raise OptionValidationError(f"product {product_id}: unknown option group '{gid}'")

    if unit_price_cents != expected_price:
        raise OptionValidationError(
            f"product {product_id}: unit_price_cents {unit_price_cents} != expected {expected_price}"
        )

    return normalized
