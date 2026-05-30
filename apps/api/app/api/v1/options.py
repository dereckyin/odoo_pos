from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.audit import audit
from ...core.deps import DbSession, StoreAdminDep, TenantScope, apply_tenant, ensure_same_tenant
from ...models import OptionChoice, OptionGroup, Product, ProductOptionChoiceOverride, ProductOptionGroup
from ...schemas.option import (
    OptionChoiceCreate,
    OptionChoiceRead,
    OptionChoiceUpdate,
    OptionGroupCreate,
    OptionGroupRead,
    OptionGroupUpdate,
    ProductOptionChoiceOverrideRead,
    ProductOptionGroupsSet,
    ProductOptionLinkRead,
    ProductOptionOverridesSet,
)

router = APIRouter(prefix="/option-groups", tags=["option-groups"])


def _group_to_read(g: OptionGroup) -> OptionGroupRead:
    choices = [
        OptionChoiceRead.model_validate(c)
        for c in sorted(g.choices, key=lambda x: x.sort_order)
        if c.deleted_at is None
    ]
    return OptionGroupRead(
        id=g.id,
        tenant_id=g.tenant_id,
        name=g.name,
        selection_type=g.selection_type,
        is_required=g.is_required,
        min_selections=g.min_selections,
        max_selections=g.max_selections,
        sort_order=g.sort_order,
        choices=choices,
        updated_at=g.updated_at,
        deleted_at=g.deleted_at,
    )


@router.get("", response_model=list[OptionGroupRead])
async def list_option_groups(db: DbSession, scope: TenantScope) -> list[OptionGroupRead]:
    stmt = (
        select(OptionGroup)
        .where(OptionGroup.deleted_at.is_(None))
        .options(selectinload(OptionGroup.choices))
        .order_by(OptionGroup.sort_order, OptionGroup.name)
    )
    stmt = apply_tenant(stmt, OptionGroup, scope)
    rows = (await db.execute(stmt)).scalars().unique().all()
    return [_group_to_read(r) for r in rows]


@router.post("", response_model=OptionGroupRead, status_code=201)
async def create_option_group(
    payload: OptionGroupCreate, db: DbSession, scope: StoreAdminDep
) -> OptionGroupRead:
    g = OptionGroup(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(g)
    await audit(
        db, scope, action="option_group_create", resource_type="option_group",
        resource_id=g.id, flush=False,
    )
    await db.commit()
    g = (
        await db.execute(
            select(OptionGroup).where(OptionGroup.id == g.id).options(selectinload(OptionGroup.choices))
        )
    ).scalar_one()
    return _group_to_read(g)


@router.get("/{group_id}", response_model=OptionGroupRead)
async def get_option_group(group_id: str, db: DbSession, scope: TenantScope) -> OptionGroupRead:
    g = (
        await db.execute(
            select(OptionGroup)
            .where(OptionGroup.id == group_id, OptionGroup.deleted_at.is_(None))
            .options(selectinload(OptionGroup.choices))
        )
    ).scalar_one_or_none()
    if not g:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "option group not found")
    ensure_same_tenant(scope, g)
    return _group_to_read(g)


@router.patch("/{group_id}", response_model=OptionGroupRead)
async def update_option_group(
    group_id: str, payload: OptionGroupUpdate, db: DbSession, scope: StoreAdminDep
) -> OptionGroupRead:
    g = await db.get(OptionGroup, group_id)
    if not g or g.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "option group not found")
    ensure_same_tenant(scope, g)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(g, k, v)
    await audit(
        db, scope, action="option_group_update", resource_type="option_group",
        resource_id=g.id, flush=False,
    )
    await db.commit()
    g = (
        await db.execute(
            select(OptionGroup).where(OptionGroup.id == g.id).options(selectinload(OptionGroup.choices))
        )
    ).scalar_one()
    return _group_to_read(g)


@router.delete("/{group_id}", status_code=204)
async def delete_option_group(group_id: str, db: DbSession, scope: StoreAdminDep) -> None:
    g = await db.get(OptionGroup, group_id)
    if not g or g.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "option group not found")
    ensure_same_tenant(scope, g)
    g.deleted_at = datetime.now(timezone.utc)
    await audit(
        db, scope, action="option_group_delete", resource_type="option_group",
        resource_id=g.id, flush=False,
    )
    await db.commit()


@router.post("/{group_id}/choices", response_model=OptionChoiceRead, status_code=201)
async def create_choice(
    group_id: str, payload: OptionChoiceCreate, db: DbSession, scope: StoreAdminDep
) -> OptionChoiceRead:
    g = await db.get(OptionGroup, group_id)
    if not g or g.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "option group not found")
    ensure_same_tenant(scope, g)
    if payload.is_default and g.selection_type == "single":
        for c in g.choices:
            if c.deleted_at is None:
                c.is_default = False
    c = OptionChoice(option_group_id=g.id, **payload.model_dump())
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return OptionChoiceRead.model_validate(c)


@router.patch("/{group_id}/choices/{choice_id}", response_model=OptionChoiceRead)
async def update_choice(
    group_id: str,
    choice_id: str,
    payload: OptionChoiceUpdate,
    db: DbSession,
    scope: StoreAdminDep,
) -> OptionChoiceRead:
    g = await db.get(OptionGroup, group_id)
    if not g or g.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "option group not found")
    ensure_same_tenant(scope, g)
    c = await db.get(OptionChoice, choice_id)
    if not c or c.option_group_id != group_id or c.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "choice not found")
    data = payload.model_dump(exclude_unset=True)
    if data.get("is_default") and g.selection_type == "single":
        for other in g.choices:
            if other.id != choice_id and other.deleted_at is None:
                other.is_default = False
    for k, v in data.items():
        setattr(c, k, v)
    await db.commit()
    await db.refresh(c)
    return OptionChoiceRead.model_validate(c)


@router.delete("/{group_id}/choices/{choice_id}", status_code=204)
async def delete_choice(
    group_id: str, choice_id: str, db: DbSession, scope: StoreAdminDep
) -> None:
    g = await db.get(OptionGroup, group_id)
    if not g:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "option group not found")
    ensure_same_tenant(scope, g)
    c = await db.get(OptionChoice, choice_id)
    if not c or c.option_group_id != group_id or c.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "choice not found")
    c.deleted_at = datetime.now(timezone.utc)
    await db.commit()


@router.post("/seed/drink-shop", response_model=list[OptionGroupRead])
async def seed_drink_shop_template(db: DbSession, scope: StoreAdminDep) -> list[OptionGroupRead]:
    """One-click template: 甜度 / 冰塊 / 加料 / 辣度 for new tenants."""
    existing = (
        await db.execute(
            select(OptionGroup).where(
                OptionGroup.tenant_id == scope.tenant_id,
                OptionGroup.deleted_at.is_(None),
            )
        )
    ).scalars().all()
    if existing:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "option groups already exist for this tenant")

    templates = [
        ("甜度", "single", True, [
            ("全糖", 0, True), ("少糖", 0, False), ("半糖", 0, False), ("微糖", 0, False), ("無糖", 0, False),
        ]),
        ("冰塊", "single", True, [
            ("正常冰", 0, True), ("少冰", 0, False), ("微冰", 0, False), ("去冰", 0, False), ("熱飲", 0, False),
        ]),
        ("加料", "multi", False, [
            ("珍珠", 1000, False), ("布丁", 1000, False), ("椰果", 1000, False),
        ]),
        ("辣度", "single", True, [
            ("不辣", 0, True), ("小辣", 0, False), ("中辣", 0, False), ("大辣", 0, False),
        ]),
    ]
    created: list[OptionGroup] = []
    for sort, (name, sel_type, required, choices) in enumerate(templates):
        g = OptionGroup(
            tenant_id=scope.tenant_id,
            name=name,
            selection_type=sel_type,
            is_required=required,
            min_selections=0 if not required else (0 if sel_type == "multi" else 1),
            max_selections=3 if name == "加料" else None,
            sort_order=sort,
        )
        db.add(g)
        await db.flush()
        for i, (cname, price, is_def) in enumerate(choices):
            db.add(OptionChoice(
                option_group_id=g.id,
                name=cname,
                price_delta_cents=price,
                is_default=is_def,
                sort_order=i,
            ))
        created.append(g)
    await db.commit()
    for g in created:
        await db.refresh(g)
    result = []
    for g in created:
        g_full = (
            await db.execute(
                select(OptionGroup).where(OptionGroup.id == g.id).options(selectinload(OptionGroup.choices))
            )
        ).scalar_one()
        result.append(_group_to_read(g_full))
    return result


product_options_router = APIRouter(prefix="/products", tags=["products"])


@product_options_router.get("/{product_id}/option-groups", response_model=list[ProductOptionLinkRead])
async def get_product_option_groups(
    product_id: str, db: DbSession, scope: TenantScope
) -> list[ProductOptionLinkRead]:
    product = await db.get(Product, product_id)
    if not product or product.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "product not found")
    ensure_same_tenant(scope, product)
    rows = (
        await db.execute(
            select(ProductOptionGroup)
            .where(ProductOptionGroup.product_id == product_id)
            .order_by(ProductOptionGroup.sort_order)
        )
    ).scalars().all()
    return [ProductOptionLinkRead.model_validate(r) for r in rows]


@product_options_router.put("/{product_id}/option-groups", response_model=list[ProductOptionLinkRead])
async def set_product_option_groups(
    product_id: str, payload: ProductOptionGroupsSet, db: DbSession, scope: StoreAdminDep
) -> list[ProductOptionLinkRead]:
    product = await db.get(Product, product_id)
    if not product or product.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "product not found")
    ensure_same_tenant(scope, product)

    group_ids = [g.option_group_id for g in payload.groups]
    if group_ids:
        owned = (
            await db.execute(
                select(OptionGroup.id).where(
                    OptionGroup.id.in_(group_ids),
                    OptionGroup.tenant_id == scope.tenant_id,
                    OptionGroup.deleted_at.is_(None),
                )
            )
        ).scalars().all()
        if len(owned) != len(set(group_ids)):
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid option group ids")

    existing = (
        await db.execute(
            select(ProductOptionGroup).where(ProductOptionGroup.product_id == product_id)
        )
    ).scalars().all()
    for row in existing:
        await db.delete(row)
    await db.flush()

    for item in payload.groups:
        db.add(
            ProductOptionGroup(
                product_id=product_id,
                option_group_id=item.option_group_id,
                sort_order=item.sort_order,
                is_required=item.is_required,
            )
        )
    await audit(
        db, scope, action="product_option_groups_set", resource_type="product",
        resource_id=product_id, flush=False,
    )
    await db.commit()
    rows = (
        await db.execute(
            select(ProductOptionGroup)
            .where(ProductOptionGroup.product_id == product_id)
            .order_by(ProductOptionGroup.sort_order)
        )
    ).scalars().all()
    return [ProductOptionLinkRead.model_validate(r) for r in rows]


@product_options_router.get(
    "/{product_id}/option-overrides", response_model=list[ProductOptionChoiceOverrideRead]
)
async def get_product_option_overrides(
    product_id: str, db: DbSession, scope: TenantScope
) -> list[ProductOptionChoiceOverrideRead]:
    product = await db.get(Product, product_id)
    if not product or product.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "product not found")
    ensure_same_tenant(scope, product)
    rows = (
        await db.execute(
            select(ProductOptionChoiceOverride).where(
                ProductOptionChoiceOverride.product_id == product_id
            )
        )
    ).scalars().all()
    return [ProductOptionChoiceOverrideRead.model_validate(r) for r in rows]


@product_options_router.put(
    "/{product_id}/option-overrides", response_model=list[ProductOptionChoiceOverrideRead]
)
async def set_product_option_overrides(
    product_id: str, payload: ProductOptionOverridesSet, db: DbSession, scope: StoreAdminDep
) -> list[ProductOptionChoiceOverrideRead]:
    product = await db.get(Product, product_id)
    if not product or product.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "product not found")
    ensure_same_tenant(scope, product)

    existing = (
        await db.execute(
            select(ProductOptionChoiceOverride).where(
                ProductOptionChoiceOverride.product_id == product_id
            )
        )
    ).scalars().all()
    for row in existing:
        await db.delete(row)
    await db.flush()

    for item in payload.overrides:
        db.add(
            ProductOptionChoiceOverride(
                product_id=product_id,
                option_choice_id=item.option_choice_id,
                price_delta_cents=item.price_delta_cents,
                is_hidden=item.is_hidden,
            )
        )
    await db.commit()
    rows = (
        await db.execute(
            select(ProductOptionChoiceOverride).where(
                ProductOptionChoiceOverride.product_id == product_id
            )
        )
    ).scalars().all()
    return [ProductOptionChoiceOverrideRead.model_validate(r) for r in rows]
