"""Public marketplace endpoints (no auth): store discovery, menus, orders."""
from uuid import uuid4

from fastapi import APIRouter, HTTPException, Query, Request, status
from sqlalchemy import or_, select
from sqlalchemy.orm import selectinload

from ...core.deps import DbSession
from ...core.ratelimit import per_ip
from ...models import (
    GuestOrder,
    GuestOrderLine,
    MarketplaceListing,
    Member,
    Product,
    ProductOptionGroup,
    Store,
)
from ...schemas.guest_order import GuestOrderLineRead
from ...schemas.marketplace import (
    MarketplaceFeedCategory,
    MarketplaceMenu,
    MarketplaceMenuMeta,
    MarketplaceOrderCreated,
    MarketplaceOrderRead,
    MarketplaceOrderSubmit,
    MarketplaceProductCard,
    MarketplaceProductFeed,
    MarketplaceProductFeedSection,
    MarketplaceProductSearchHit,
    MarketplaceStoreDetail,
    MarketplaceStoreSummary,
)
from ...schemas.public import PublicMeta
from ...services.marketplace import (
    get_or_create_web_dinein_table,
    haversine_km,
    is_store_open,
    listing_to_summary,
)
from ...services.marketplace_category import load_marketplace_taxonomy, load_tenant_categories_map
from ...services.option_validation import (
    OptionValidationError,
    load_product_option_context,
    validate_line_options,
)
from ...services.public_menu import build_public_menu_for_tenant, product_orderable_via_public_menu

router = APIRouter(prefix="/public/marketplace", tags=["public-marketplace"])

FULFILLMENT_TYPES = ("pickup", "delivery", "dine_in")
PAYMENT_METHODS = ("counter", "online")


async def _resolve_listing(db, slug: str) -> tuple[MarketplaceListing, Store]:
    row = (
        await db.execute(
            select(MarketplaceListing)
            .where(
                MarketplaceListing.slug == slug,
                MarketplaceListing.status == "approved",
            )
        )
    ).scalar_one_or_none()
    if not row:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    store = await db.get(Store, row.store_id)
    if not store or store.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    return row, store


def _order_access_token(g: GuestOrder) -> str | None:
    if g.extras and isinstance(g.extras, dict):
        return g.extras.get("access_token")
    return None


def _to_marketplace_read(g: GuestOrder, listing: MarketplaceListing, store: Store) -> MarketplaceOrderRead:
    return MarketplaceOrderRead(
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
        store_name=listing.display_name,
        store_slug=listing.slug,
        estimated_subtotal_cents=g.estimated_subtotal_cents,
        customer_note=g.customer_note,
        party_size=g.party_size,
        created_at=g.created_at,
        accepted_at=g.accepted_at,
        ready_at=g.ready_at,
        merged_at=g.merged_at,
        cancelled_at=g.cancelled_at,
        lines=[GuestOrderLineRead.model_validate(ln) for ln in g.lines],
    )


@router.get("/stores", response_model=list[MarketplaceStoreSummary])
@per_ip("60/minute")
async def list_stores(
    request: Request,
    db: DbSession,
    q: str | None = Query(default=None),
    lat: float | None = Query(default=None),
    lng: float | None = Query(default=None),
    cuisine: str | None = Query(default=None),
    fulfillment: str | None = Query(default=None, description="pickup|delivery|dine_in"),
):
    stmt = (
        select(MarketplaceListing, Store)
        .join(Store, Store.id == MarketplaceListing.store_id)
        .where(
            MarketplaceListing.status == "approved",
            Store.deleted_at.is_(None),
        )
    )
    if q:
        like = f"%{q.strip()}%"
        stmt = stmt.where(
            or_(
                MarketplaceListing.display_name.ilike(like),
                MarketplaceListing.tagline.ilike(like),
                Store.address.ilike(like),
            )
        )
    if cuisine:
        # cuisine filter applied post-query for JSON portability
        pass
    if fulfillment == "pickup":
        stmt = stmt.where(MarketplaceListing.supports_pickup.is_(True))
    elif fulfillment == "delivery":
        stmt = stmt.where(MarketplaceListing.supports_delivery.is_(True))
    elif fulfillment == "dine_in":
        stmt = stmt.where(MarketplaceListing.supports_dine_in.is_(True))

    rows = (await db.execute(stmt)).all()
    summaries: list[MarketplaceStoreSummary] = []
    for listing, store in rows:
        if cuisine and cuisine not in (listing.cuisine_tags or []):
            continue
        if fulfillment == "delivery" and lat is not None and lng is not None:
            if store.latitude is None or store.longitude is None:
                continue
            dist = haversine_km(lat, lng, store.latitude, store.longitude)
            if listing.delivery_radius_km and dist > listing.delivery_radius_km:
                continue
        data = listing_to_summary(listing, store, lat=lat, lng=lng)
        summaries.append(MarketplaceStoreSummary(**data))

    if lat is not None and lng is not None:
        summaries.sort(key=lambda s: s.distance_km if s.distance_km is not None else 9999)
    else:
        summaries.sort(key=lambda s: s.display_name)
    return summaries


@router.get("/stores/{slug}", response_model=MarketplaceStoreDetail)
@per_ip("60/minute")
async def get_store(request: Request, slug: str, db: DbSession):
    listing, store = await _resolve_listing(db, slug)
    data = listing_to_summary(listing, store)
    return MarketplaceStoreDetail(
        **data,
        store_id=store.id,
        business_hours=listing.business_hours,
    )


@router.get("/stores/{slug}/menu", response_model=MarketplaceMenu)
@per_ip("60/minute")
async def get_store_menu(request: Request, slug: str, db: DbSession):
    listing, store = await _resolve_listing(db, slug)
    menu = await build_public_menu_for_tenant(
        db,
        store.tenant_id,
        PublicMeta(
            table_id="",
            table_label="",
            store_id=store.id,
            store_name=listing.display_name,
            store_address=store.address,
        ),
    )
    return MarketplaceMenu(
        meta=MarketplaceMenuMeta(
            **menu.meta.model_dump(),
            slug=listing.slug,
            display_name=listing.display_name,
            tagline=listing.tagline,
            logo_url=listing.logo_url,
            supports_pickup=listing.supports_pickup,
            supports_delivery=listing.supports_delivery,
            supports_dine_in=listing.supports_dine_in,
            payment_counter=listing.payment_counter,
            payment_online=listing.payment_online,
            min_order_cents=listing.min_order_cents,
            delivery_fee_cents=listing.delivery_fee_cents,
            is_open=is_store_open(listing.business_hours),
        ),
        categories=menu.categories,
        root_category_ids=menu.root_category_ids,
        products=menu.products,
    )


def _truncate_description(text: str | None, max_len: int = 80) -> str | None:
    if not text:
        return None
    s = text.strip()
    if len(s) <= max_len:
        return s
    return s[: max_len - 1].rstrip() + "…"


async def _product_ids_with_options(db, product_ids: list[str]) -> set[str]:
    if not product_ids:
        return set()
    rows = (
        await db.execute(
            select(ProductOptionGroup.product_id).where(ProductOptionGroup.product_id.in_(product_ids))
        )
    ).scalars().all()
    return set(rows)


async def _list_marketplace_products(
    db,
    *,
    q: str | None = None,
    fulfillment: str | None = None,
    cuisine: str | None = None,
    feed_category_id: str | None = None,
    limit: int = 48,
    offset: int = 0,
    open_only: bool = True,
) -> list[MarketplaceProductCard]:
    taxonomy = await load_marketplace_taxonomy(db)
    stmt = (
        select(Product, MarketplaceListing, Store)
        .join(MarketplaceListing, MarketplaceListing.tenant_id == Product.tenant_id)
        .join(Store, Store.id == MarketplaceListing.store_id)
        .where(
            MarketplaceListing.status == "approved",
            Store.deleted_at.is_(None),
            Product.deleted_at.is_(None),
            Product.is_active.is_(True),
            Product.hide_from_public_ordering.is_(False),
        )
    )
    if q and q.strip():
        like = f"%{q.strip()}%"
        stmt = stmt.where(or_(Product.name.ilike(like), Product.sku.ilike(like)))
    if fulfillment == "pickup":
        stmt = stmt.where(MarketplaceListing.supports_pickup.is_(True))
    elif fulfillment == "delivery":
        stmt = stmt.where(MarketplaceListing.supports_delivery.is_(True))
    elif fulfillment == "dine_in":
        stmt = stmt.where(MarketplaceListing.supports_dine_in.is_(True))

    stmt = stmt.order_by(Product.name).offset(offset).limit(limit)
    rows = (await db.execute(stmt)).all()

    pending_ids: list[str] = []
    pending_rows: list[tuple[Product, MarketplaceListing, Store]] = []
    seen: set[tuple[str, str]] = set()
    tenant_ids: set[str] = set()

    for product, listing, _store in rows:
        if cuisine and cuisine not in (listing.cuisine_tags or []):
            continue
        store_open = is_store_open(listing.business_hours)
        if open_only and not store_open:
            continue
        key = (product.id, listing.slug)
        if key in seen:
            continue
        if not await product_orderable_via_public_menu(db, product):
            continue
        seen.add(key)
        pending_rows.append((product, listing, _store))
        pending_ids.append(product.id)
        tenant_ids.add(product.tenant_id)

    tenant_cats = await load_tenant_categories_map(db, tenant_ids)
    option_ids = await _product_ids_with_options(db, pending_ids)
    cards: list[MarketplaceProductCard] = []
    for product, listing, _store in pending_rows:
        feed_cat = taxonomy.resolve(product, tenant_cats.get(product.tenant_id, {}))
        if not feed_cat:
            continue
        if feed_category_id and feed_cat.id != feed_category_id:
            continue
        cards.append(
            MarketplaceProductCard(
                product_id=product.id,
                product_name=product.name,
                price_cents=product.price_cents,
                image_url=product.image_url,
                description=_truncate_description(product.description),
                has_options=product.id in option_ids,
                feed_category_id=feed_cat.id,
                feed_category_name=feed_cat.name,
                store_slug=listing.slug,
                store_name=listing.display_name,
                logo_url=listing.logo_url,
                store_is_open=is_store_open(listing.business_hours),
            )
        )
    return cards


def _group_cards_by_category(
    cards: list[MarketplaceProductCard],
    taxonomy,
) -> MarketplaceProductFeed:
    by_cat: dict[str, list[MarketplaceProductCard]] = {}
    for card in cards:
        by_cat.setdefault(card.feed_category_id, []).append(card)
    sections: list[MarketplaceProductFeedSection] = []
    for cat in taxonomy.categories:
        products = by_cat.get(cat.id, [])
        if not products:
            continue
        sections.append(
            MarketplaceProductFeedSection(
                category_id=cat.id,
                category_slug=cat.slug,
                category_name=cat.name,
                icon=cat.icon,
                products=products,
            )
        )
    return MarketplaceProductFeed(sections=sections)


@router.get("/feed-categories", response_model=list[MarketplaceFeedCategory])
@per_ip("60/minute")
async def list_feed_categories(
    request: Request,
    db: DbSession,
    fulfillment: str | None = Query(default=None, description="pickup|delivery|dine_in"),
    cuisine: str | None = Query(default=None),
):
    taxonomy = await load_marketplace_taxonomy(db)
    cards = await _list_marketplace_products(
        db,
        fulfillment=fulfillment,
        cuisine=cuisine,
        limit=500,
        open_only=True,
    )
    counts: dict[str, int] = {}
    for card in cards:
        counts[card.feed_category_id] = counts.get(card.feed_category_id, 0) + 1
    return [
        MarketplaceFeedCategory(
            id=cat.id,
            slug=cat.slug,
            name=cat.name,
            icon=cat.icon,
            product_count=counts.get(cat.id, 0),
        )
        for cat in taxonomy.categories
        if counts.get(cat.id, 0) > 0
    ]


@router.get("/products/feed", response_model=MarketplaceProductFeed)
@per_ip("60/minute")
async def list_products_feed(
    request: Request,
    db: DbSession,
    q: str | None = Query(default=None),
    fulfillment: str | None = Query(default=None, description="pickup|delivery|dine_in"),
    cuisine: str | None = Query(default=None),
    category: str | None = Query(default=None, description="feed category id or slug"),
    limit: int = Query(default=48, le=200),
):
    taxonomy = await load_marketplace_taxonomy(db)
    feed_category_id = None
    if category:
        if category in taxonomy.by_id:
            feed_category_id = category
        elif category in taxonomy.by_slug:
            feed_category_id = taxonomy.by_slug[category].id
    cards = await _list_marketplace_products(
        db,
        q=q,
        fulfillment=fulfillment,
        cuisine=cuisine,
        feed_category_id=feed_category_id,
        limit=limit,
        open_only=True,
    )
    if feed_category_id:
        cat = taxonomy.by_id.get(feed_category_id)
        if not cat:
            return MarketplaceProductFeed(sections=[])
        return MarketplaceProductFeed(
            sections=[
                MarketplaceProductFeedSection(
                    category_id=cat.id,
                    category_slug=cat.slug,
                    category_name=cat.name,
                    icon=cat.icon,
                    products=cards,
                )
            ]
            if cards
            else []
        )
    return _group_cards_by_category(cards, taxonomy)


@router.get("/products", response_model=list[MarketplaceProductCard])
@per_ip("60/minute")
async def list_products(
    request: Request,
    db: DbSession,
    q: str | None = Query(default=None),
    fulfillment: str | None = Query(default=None, description="pickup|delivery|dine_in"),
    cuisine: str | None = Query(default=None),
    category: str | None = Query(default=None, description="feed category id or slug"),
    limit: int = Query(default=48, le=100),
    offset: int = Query(default=0, ge=0),
):
    taxonomy = await load_marketplace_taxonomy(db)
    feed_category_id = None
    if category:
        if category in taxonomy.by_id:
            feed_category_id = category
        elif category in taxonomy.by_slug:
            feed_category_id = taxonomy.by_slug[category].id
    return await _list_marketplace_products(
        db,
        q=q,
        fulfillment=fulfillment,
        cuisine=cuisine,
        feed_category_id=feed_category_id,
        limit=limit,
        offset=offset,
        open_only=True,
    )


@router.get("/search/products", response_model=list[MarketplaceProductSearchHit])
@per_ip("60/minute")
async def search_products(
    request: Request,
    db: DbSession,
    q: str = Query(min_length=1),
    limit: int = Query(default=30, le=100),
):
    return await _list_marketplace_products(db, q=q, limit=limit, open_only=False)


@router.post("/stores/{slug}/orders", response_model=MarketplaceOrderCreated, status_code=201)
@per_ip("30/minute")
async def submit_marketplace_order(
    request: Request,
    slug: str,
    payload: MarketplaceOrderSubmit,
    db: DbSession,
):
    if not payload.lines:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "empty cart")
    if payload.fulfillment_type not in FULFILLMENT_TYPES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid fulfillment_type")
    if payload.payment_method not in PAYMENT_METHODS:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid payment_method")

    listing, store = await _resolve_listing(db, slug)
    if not is_store_open(listing.business_hours):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "store is currently closed")

    if payload.fulfillment_type == "pickup" and not listing.supports_pickup:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "pickup not supported")
    if payload.fulfillment_type == "delivery" and not listing.supports_delivery:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "delivery not supported")
    if payload.fulfillment_type == "dine_in" and not listing.supports_dine_in:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "dine_in not supported")
    if payload.payment_method == "counter" and not listing.payment_counter:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "counter payment not supported")
    if payload.payment_method == "online" and not listing.payment_online:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "online payment not supported")

    if payload.fulfillment_type == "delivery":
        if not payload.delivery_address:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "delivery_address required")

    table_id = None
    if payload.fulfillment_type == "dine_in":
        table = await get_or_create_web_dinein_table(db, store)
        table_id = table.id
        if payload.table_label:
            table.label = payload.table_label[:32]
            await db.flush()

    product_ids = list({ln.product_id for ln in payload.lines})
    products = (
        await db.execute(
            select(Product).where(
                Product.id.in_(product_ids),
                Product.tenant_id == store.tenant_id,
                Product.deleted_at.is_(None),
                Product.is_active.is_(True),
            )
        )
    ).scalars().all()
    by_id = {p.id: p for p in products}
    option_ctx = await load_product_option_context(db, store.tenant_id, product_ids)

    estimated = 0
    if payload.fulfillment_type == "delivery":
        estimated += listing.delivery_fee_cents
    line_models: list[GuestOrderLine] = []
    for ln in payload.lines:
        p = by_id.get(ln.product_id)
        if not p:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, f"product not available: {ln.product_id}")
        if not await product_orderable_via_public_menu(db, p):
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"product not available: {ln.product_id}",
            )
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

    if estimated < listing.min_order_cents:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"minimum order is {listing.min_order_cents} cents",
        )

    if payload.member_id:
        member = await db.get(Member, payload.member_id)
        if not member or member.tenant_id != store.tenant_id or member.deleted_at:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "invalid member")

    access_token = str(uuid4())
    payment_status = "pending" if payload.payment_method == "online" else None
    delivery_status = "pending" if payload.fulfillment_type == "delivery" else None

    g = GuestOrder(
        tenant_id=store.tenant_id,
        store_id=store.id,
        table_id=table_id,
        channel="marketplace",
        fulfillment_type=payload.fulfillment_type,
        status="submitted",
        customer_name=payload.customer_name,
        customer_phone=payload.customer_phone,
        customer_note=payload.customer_note,
        party_size=payload.party_size,
        member_id=payload.member_id,
        delivery_address=payload.delivery_address,
        delivery_lat=payload.delivery_lat,
        delivery_lng=payload.delivery_lng,
        delivery_note=payload.delivery_note,
        delivery_status=delivery_status,
        payment_method=payload.payment_method,
        payment_status=payment_status,
        estimated_subtotal_cents=estimated,
        extras={"access_token": access_token, "store_slug": slug},
    )
    db.add(g)
    await db.flush()
    for lm in line_models:
        lm.order_id = g.id
        db.add(lm)
    await db.commit()

    return MarketplaceOrderCreated(
        order_id=g.id,
        access_token=access_token,
        payment_method=payload.payment_method,
        payment_status=payment_status,
        estimated_subtotal_cents=estimated,
    )


@router.get("/orders/{order_id}", response_model=MarketplaceOrderRead)
@per_ip("120/minute")
async def get_marketplace_order(
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
                GuestOrder.channel == "marketplace",
            )
            .options(selectinload(GuestOrder.lines))
        )
    ).scalar_one_or_none()
    if not g or _order_access_token(g) != access_token:
        raise HTTPException(status.HTTP_404_NOT_FOUND)

    listing = (
        await db.execute(
            select(MarketplaceListing).where(MarketplaceListing.store_id == g.store_id)
        )
    ).scalar_one_or_none()
    store = await db.get(Store, g.store_id)
    if not listing or not store:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return _to_marketplace_read(g, listing, store)
