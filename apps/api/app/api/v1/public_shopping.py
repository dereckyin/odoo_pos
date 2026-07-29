"""Public unified shopping endpoints (no auth): store picker, menu, orders.

Unlike marketplace (slug + approved listing), this channel uses store UUID and
per-store ``online_ordering_json.enabled``, gated by the tenant
``online_ordering`` module.
"""
from fastapi import APIRouter, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from ...core.deps import DbSession
from ...core.ratelimit import per_ip
from ...models import GuestOrder, Store, Tenant
from ...schemas.public import PublicMeta
from ...schemas.shopping import (
    ShoppingMenu,
    ShoppingMenuMeta,
    ShoppingOrderCreated,
    ShoppingOrderRead,
    ShoppingOrderSubmit,
    ShoppingStoreSummary,
)
from ...services.marketplace_order import (
    MarketplaceOrderInput,
    build_marketplace_order,
    profile_from_store,
)
from ...services.online_ordering import is_online_ordering_enabled, read_online_ordering
from ...services.public_menu import build_public_menu_for_tenant
from ...services.tenant_modules import MODULE_ONLINE_ORDERING, read_modules_from_settings

router = APIRouter(prefix="/public/shopping", tags=["public-shopping"])


def _order_access_token(g: GuestOrder) -> str | None:
    if not g.extras:
        return None
    return g.extras.get("access_token")


async def _resolve_shopping_store(db, store_id: str) -> Store:
    store = await db.get(Store, store_id)
    if not store or store.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    tenant = await db.get(Tenant, store.tenant_id)
    if not tenant or tenant.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    if tenant.status not in ("active", "trial"):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    mods = read_modules_from_settings(tenant.settings)
    if not mods.get(MODULE_ONLINE_ORDERING):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    if not is_online_ordering_enabled(store):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    return store


def _to_summary(store: Store) -> ShoppingStoreSummary:
    cfg = read_online_ordering(store)
    return ShoppingStoreSummary(
        id=store.id,
        name=store.name,
        address=store.address,
        phone=store.phone,
        supports_pickup=bool(cfg["supports_pickup"]),
        supports_delivery=bool(cfg["supports_delivery"]),
        supports_dine_in=bool(cfg["supports_dine_in"]),
        payment_counter=bool(cfg["payment_counter"]),
        payment_online=bool(cfg["payment_online"]),
        min_order_cents=int(cfg["min_order_cents"]),
        delivery_fee_cents=int(cfg["delivery_fee_cents"]),
        is_open=True,
    )


def _to_order_read(g: GuestOrder, store: Store) -> ShoppingOrderRead:
    return ShoppingOrderRead(
        id=g.id,
        status=g.status,
        channel=g.channel,
        fulfillment_type=g.fulfillment_type,
        payment_method=g.payment_method,
        payment_status=g.payment_status,
        delivery_status=g.delivery_status,
        customer_name=g.customer_name,
        customer_phone=g.customer_phone,
        delivery_address=g.delivery_address,
        store_name=store.name,
        store_id=store.id,
        estimated_subtotal_cents=g.estimated_subtotal_cents or 0,
        discount_cents=g.discount_cents or 0,
        customer_note=g.customer_note,
        party_size=g.party_size,
        created_at=g.created_at,
        accepted_at=g.accepted_at,
        ready_at=g.ready_at,
        merged_at=g.merged_at,
        cancelled_at=g.cancelled_at,
        lines=g.lines or [],
    )


@router.get("/stores", response_model=list[ShoppingStoreSummary])
@per_ip("60/minute")
async def list_shopping_stores(request: Request, db: DbSession):
    """Stores available on the unified shopping store-picker page."""
    tenants = (
        await db.execute(
            select(Tenant).where(
                Tenant.deleted_at.is_(None),
                Tenant.status.in_(("active", "trial")),
            )
        )
    ).scalars().all()
    enabled_tenant_ids = [
        t.id
        for t in tenants
        if read_modules_from_settings(t.settings).get(MODULE_ONLINE_ORDERING)
    ]
    if not enabled_tenant_ids:
        return []
    stores = (
        await db.execute(
            select(Store)
            .where(
                Store.deleted_at.is_(None),
                Store.tenant_id.in_(enabled_tenant_ids),
            )
            .order_by(Store.name)
        )
    ).scalars().all()
    return [_to_summary(s) for s in stores if is_online_ordering_enabled(s)]


@router.get("/stores/{store_id}/menu", response_model=ShoppingMenu)
@per_ip("60/minute")
async def get_shopping_menu(request: Request, store_id: str, db: DbSession):
    store = await _resolve_shopping_store(db, store_id)
    cfg = read_online_ordering(store)
    menu = await build_public_menu_for_tenant(
        db,
        store.tenant_id,
        PublicMeta(
            table_id="",
            table_label="",
            store_id=store.id,
            store_name=store.name,
            store_address=store.address,
        ),
    )
    return ShoppingMenu(
        meta=ShoppingMenuMeta(
            **menu.meta.model_dump(),
            slug=store.id,
            display_name=store.name,
            supports_pickup=bool(cfg["supports_pickup"]),
            supports_delivery=bool(cfg["supports_delivery"]),
            supports_dine_in=bool(cfg["supports_dine_in"]),
            payment_counter=bool(cfg["payment_counter"]),
            payment_online=bool(cfg["payment_online"]),
            min_order_cents=int(cfg["min_order_cents"]),
            delivery_fee_cents=int(cfg["delivery_fee_cents"]),
            is_open=True,
        ),
        categories=menu.categories,
        root_category_ids=menu.root_category_ids,
        products=menu.products,
    )


@router.post("/stores/{store_id}/orders", response_model=ShoppingOrderCreated, status_code=201)
@per_ip("30/minute")
async def submit_shopping_order(
    request: Request,
    store_id: str,
    payload: ShoppingOrderSubmit,
    db: DbSession,
):
    store = await _resolve_shopping_store(db, store_id)
    profile = profile_from_store(store)
    data = MarketplaceOrderInput(
        fulfillment_type=payload.fulfillment_type,
        payment_method=payload.payment_method,
        customer_name=payload.customer_name,
        customer_phone=payload.customer_phone,
        customer_note=payload.customer_note,
        party_size=payload.party_size,
        delivery_address=payload.delivery_address,
        delivery_lat=payload.delivery_lat,
        delivery_lng=payload.delivery_lng,
        delivery_note=payload.delivery_note,
        table_label=payload.table_label,
        lines=payload.lines,
    )
    g, access_token, estimated = await build_marketplace_order(
        db,
        store=store,
        data=data,
        profile=profile,
        channel="shopping",
    )
    await db.commit()
    return ShoppingOrderCreated(
        order_id=g.id,
        access_token=access_token,
        payment_method=payload.payment_method,
        payment_status=g.payment_status,
        estimated_subtotal_cents=estimated,
    )


@router.get("/orders/{order_id}", response_model=ShoppingOrderRead)
@per_ip("120/minute")
async def get_shopping_order(
    request: Request,
    order_id: str,
    db: DbSession,
    access_token: str = Query(...),
):
    g = (
        await db.execute(
            select(GuestOrder)
            .where(
                GuestOrder.id == order_id,
                GuestOrder.channel == "shopping",
            )
            .options(selectinload(GuestOrder.lines))
        )
    ).scalar_one_or_none()
    if not g or _order_access_token(g) != access_token:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    store = await db.get(Store, g.store_id)
    if not store:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return _to_order_read(g, store)
