"""Public marketplace endpoints (no auth): store discovery, menus, orders."""
from uuid import uuid4

from fastapi import APIRouter, HTTPException, Query, Request, status
from sqlalchemy import or_, select
from sqlalchemy.orm import selectinload

from ...core.deps import DbSession
from ...core.ratelimit import per_ip
from ...models import (
    AllianceMember,
    GuestOrder,
    MarketplaceListing,
    MarketplaceReview,
    Member,
    MemberFavoriteStore,
    Product,
    ProductOptionGroup,
    Store,
    Tenant,
)
from ...schemas.guest_order import GuestOrderLineRead
from ...schemas.marketplace import (
    MarketplaceBatchOrderCreated,
    MarketplaceBatchOrderItem,
    MarketplaceBatchOrderSubmit,
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
    MarketplaceReviewCreate,
    MarketplaceReviewRead,
    MarketplaceStoreDetail,
    MarketplaceStoreReviews,
    MarketplaceStoreSummary,
)
from ...schemas.public import PublicMeta
from ...services.alliance_service import resolve_alliance_member
from ...services.marketplace import (
    haversine_km,
    is_store_open,
    listing_to_summary,
)
from ...services.marketplace_category import load_marketplace_taxonomy, load_tenant_categories_map
from ...services.marketplace_member import (
    MarketplaceMemberContext,
    ensure_tenant_in_marketplace_alliance,
    get_or_create_marketplace_alliance,
)
from ...services.marketplace_order import MarketplaceOrderInput, build_marketplace_order
from ...services.public_menu import build_public_menu_for_tenant, product_orderable_via_public_menu
from ...services.tenant_modules import (
    MODULE_MARKETPLACE,
    assert_tenant_module,
    read_modules_from_settings,
)
from .public_members import OptionalMarketplaceMemberDep

router = APIRouter(prefix="/public/marketplace", tags=["public-marketplace"])

FULFILLMENT_TYPES = ("pickup", "delivery", "dine_in")
PAYMENT_METHODS = ("counter", "online")


async def _resolve_tenant_member_id(
    db, tenant_id: str, member_ctx: MarketplaceMemberContext | None
) -> str | None:
    """Map a unified marketplace member to this tenant's local member id."""
    if member_ctx is None:
        return None
    am = await db.get(AllianceMember, member_ctx.alliance_member_id)
    if not am or am.deleted_at is not None:
        return None
    net = await get_or_create_marketplace_alliance(db)
    await ensure_tenant_in_marketplace_alliance(db, tenant_id)
    _, member = await resolve_alliance_member(
        db,
        alliance_id=net.id,
        tenant_id=tenant_id,
        phone=am.phone,
        name=am.name,
    )
    return member.id


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
    await assert_tenant_module(db, row.tenant_id, MODULE_MARKETPLACE)
    return row, store


def _marketplace_enabled_for_tenant(tenant: Tenant | None) -> bool:
    if tenant is None:
        return False
    modules = read_modules_from_settings(tenant.settings)
    return bool(modules.get(MODULE_MARKETPLACE))


def _order_access_token(g: GuestOrder) -> str | None:
    if g.extras and isinstance(g.extras, dict):
        return g.extras.get("access_token")
    return None


def _eta_minutes(g: GuestOrder, listing: MarketplaceListing) -> int | None:
    """Rough remaining ETA: prep time (+ delivery buffer), counting down once accepted."""
    if g.status in ("merged", "cancelled"):
        return None
    base = max(0, listing.prep_time_min or 15)
    if g.fulfillment_type == "delivery":
        base += 15
    if g.status == "ready":
        return 0 if g.fulfillment_type != "delivery" else 10
    return base


def _to_marketplace_read(
    g: GuestOrder,
    listing: MarketplaceListing,
    store: Store,
    *,
    has_review: bool = False,
) -> MarketplaceOrderRead:
    completed = g.status == "merged" or (g.payment_status == "paid")
    can_review = completed and not has_review
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
        discount_cents=g.discount_cents or 0,
        points_redeemed=g.points_redeemed or 0,
        order_group_id=g.order_group_id,
        prep_time_min=listing.prep_time_min or 15,
        eta_minutes=_eta_minutes(g, listing),
        can_review=can_review,
        has_review=has_review,
        customer_note=g.customer_note,
        party_size=g.party_size,
        created_at=g.created_at,
        accepted_at=g.accepted_at,
        ready_at=g.ready_at,
        merged_at=g.merged_at,
        cancelled_at=g.cancelled_at,
        lines=[GuestOrderLineRead.model_validate(ln) for ln in g.lines],
    )


async def _favorite_listing_ids(db, member_ctx: MarketplaceMemberContext | None) -> set[str]:
    if member_ctx is None:
        return set()
    rows = (
        await db.execute(
            select(MemberFavoriteStore.listing_id).where(
                MemberFavoriteStore.alliance_member_id == member_ctx.alliance_member_id
            )
        )
    ).scalars().all()
    return set(rows)


@router.get("/stores", response_model=list[MarketplaceStoreSummary])
@per_ip("60/minute")
async def list_stores(
    request: Request,
    db: DbSession,
    member_ctx: OptionalMarketplaceMemberDep,
    q: str | None = Query(default=None),
    lat: float | None = Query(default=None),
    lng: float | None = Query(default=None),
    cuisine: str | None = Query(default=None),
    fulfillment: str | None = Query(default=None, description="pickup|delivery|dine_in"),
    sort: str | None = Query(default=None, description="distance|rating|prep"),
):
    stmt = (
        select(MarketplaceListing, Store, Tenant)
        .join(Store, Store.id == MarketplaceListing.store_id)
        .join(Tenant, Tenant.id == MarketplaceListing.tenant_id)
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
    fav_ids = await _favorite_listing_ids(db, member_ctx)
    summaries: list[MarketplaceStoreSummary] = []
    for listing, store, tenant in rows:
        if not _marketplace_enabled_for_tenant(tenant):
            continue
        if cuisine and cuisine not in (listing.cuisine_tags or []):
            continue
        if fulfillment == "delivery" and lat is not None and lng is not None:
            if store.latitude is None or store.longitude is None:
                continue
            dist = haversine_km(lat, lng, store.latitude, store.longitude)
            if listing.delivery_radius_km and dist > listing.delivery_radius_km:
                continue
        data = listing_to_summary(listing, store, lat=lat, lng=lng)
        data["is_favorite"] = listing.id in fav_ids
        summaries.append(MarketplaceStoreSummary(**data))

    if sort == "rating":
        summaries.sort(key=lambda s: s.rating_avg, reverse=True)
    elif sort == "prep":
        summaries.sort(key=lambda s: s.prep_time_min)
    elif lat is not None and lng is not None:
        summaries.sort(key=lambda s: s.distance_km if s.distance_km is not None else 9999)
    else:
        summaries.sort(key=lambda s: s.display_name)
    return summaries


@router.get("/stores/{slug}", response_model=MarketplaceStoreDetail)
@per_ip("60/minute")
async def get_store(
    request: Request, slug: str, db: DbSession, member_ctx: OptionalMarketplaceMemberDep
):
    listing, store = await _resolve_listing(db, slug)
    data = listing_to_summary(listing, store)
    fav_ids = await _favorite_listing_ids(db, member_ctx)
    data["is_favorite"] = listing.id in fav_ids
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
        select(Product, MarketplaceListing, Store, Tenant)
        .join(MarketplaceListing, MarketplaceListing.tenant_id == Product.tenant_id)
        .join(Store, Store.id == MarketplaceListing.store_id)
        .join(Tenant, Tenant.id == MarketplaceListing.tenant_id)
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

    for product, listing, _store, tenant in rows:
        if not _marketplace_enabled_for_tenant(tenant):
            continue
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
    member_ctx: OptionalMarketplaceMemberDep,
):
    listing, store = await _resolve_listing(db, slug)
    # Prefer the authenticated unified member; fall back to a raw member_id.
    member_id = await _resolve_tenant_member_id(db, store.tenant_id, member_ctx)
    available_points = None
    if member_ctx is not None:
        am = await db.get(AllianceMember, member_ctx.alliance_member_id)
        available_points = am.points if am else None
    if member_id is None and payload.member_id:
        member = await db.get(Member, payload.member_id)
        if member and member.tenant_id == store.tenant_id and not member.deleted_at:
            member_id = member.id
            available_points = member.points

    data = MarketplaceOrderInput(
        fulfillment_type=payload.fulfillment_type,
        payment_method=payload.payment_method,
        customer_name=payload.customer_name,
        customer_phone=payload.customer_phone,
        customer_note=payload.customer_note,
        party_size=payload.party_size,
        member_id=member_id,
        delivery_address=payload.delivery_address,
        delivery_lat=payload.delivery_lat,
        delivery_lng=payload.delivery_lng,
        delivery_note=payload.delivery_note,
        table_label=payload.table_label,
        points_redeemed=payload.points_redeemed,
        coupon_code=payload.coupon_code,
        available_points=available_points,
        lines=payload.lines,
    )
    g, access_token, estimated = await build_marketplace_order(
        db, listing=listing, store=store, data=data
    )
    await db.commit()
    return MarketplaceOrderCreated(
        order_id=g.id,
        access_token=access_token,
        payment_method=payload.payment_method,
        payment_status=g.payment_status,
        estimated_subtotal_cents=estimated,
    )


@router.post("/orders/batch", response_model=MarketplaceBatchOrderCreated, status_code=201)
@per_ip("15/minute")
async def submit_batch_order(
    request: Request,
    payload: MarketplaceBatchOrderSubmit,
    db: DbSession,
    member_ctx: OptionalMarketplaceMemberDep,
):
    """Multi-store checkout: one group id, one GuestOrder per store."""
    if not payload.carts:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "empty cart")
    group_id = str(uuid4())
    items: list[MarketplaceBatchOrderItem] = []
    total = 0
    available_points = None
    if member_ctx is not None:
        am = await db.get(AllianceMember, member_ctx.alliance_member_id)
        available_points = am.points if am else None
    for cart in payload.carts:
        listing, store = await _resolve_listing(db, cart.store_slug)
        member_id = await _resolve_tenant_member_id(db, store.tenant_id, member_ctx)
        data = MarketplaceOrderInput(
            fulfillment_type=cart.fulfillment_type,
            payment_method=cart.payment_method,
            customer_name=payload.customer_name,
            customer_phone=payload.customer_phone,
            customer_note=cart.store_note,
            party_size=cart.party_size,
            member_id=member_id,
            delivery_address=cart.delivery_address,
            delivery_lat=cart.delivery_lat,
            delivery_lng=cart.delivery_lng,
            delivery_note=cart.delivery_note,
            table_label=cart.table_label,
            points_redeemed=cart.points_redeemed,
            coupon_code=cart.coupon_code,
            available_points=available_points,
            lines=cart.lines,
        )
        g, access_token, estimated = await build_marketplace_order(
            db, listing=listing, store=store, data=data, order_group_id=group_id
        )
        total += estimated
        items.append(
            MarketplaceBatchOrderItem(
                order_id=g.id,
                access_token=access_token,
                store_slug=listing.slug,
                store_name=listing.display_name,
                payment_method=cart.payment_method,
                payment_status=g.payment_status,
                estimated_subtotal_cents=estimated,
            )
        )
    await db.commit()
    return MarketplaceBatchOrderCreated(
        order_group_id=group_id, orders=items, total_cents=total
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
    has_review = (
        await db.execute(
            select(MarketplaceReview.id).where(MarketplaceReview.guest_order_id == g.id)
        )
    ).scalar_one_or_none() is not None
    return _to_marketplace_read(g, listing, store, has_review=has_review)


@router.get("/order-groups/{group_id}", response_model=list[MarketplaceOrderRead])
@per_ip("120/minute")
async def get_order_group(
    request: Request,
    group_id: str,
    db: DbSession,
    member_ctx: OptionalMarketplaceMemberDep,
):
    """Aggregate tracking for a multi-store checkout. Requires the member token
    (the group's owner) to enumerate orders."""
    if member_ctx is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "member token required")
    member_ids = (
        await db.execute(
            select(GuestOrder)
            .where(GuestOrder.order_group_id == group_id)
            .options(selectinload(GuestOrder.lines))
            .order_by(GuestOrder.created_at)
        )
    ).scalars().all()
    out: list[MarketplaceOrderRead] = []
    for g in member_ids:
        listing = (
            await db.execute(
                select(MarketplaceListing).where(MarketplaceListing.store_id == g.store_id)
            )
        ).scalar_one_or_none()
        store = await db.get(Store, g.store_id)
        if listing and store:
            out.append(_to_marketplace_read(g, listing, store))
    return out


# ---------------------------------------------------------------------------
# Reviews
# ---------------------------------------------------------------------------

@router.get("/stores/{slug}/reviews", response_model=MarketplaceStoreReviews)
@per_ip("60/minute")
async def get_store_reviews(request: Request, slug: str, db: DbSession):
    listing, _store = await _resolve_listing(db, slug)
    rows = (
        await db.execute(
            select(MarketplaceReview)
            .where(MarketplaceReview.listing_id == listing.id)
            .order_by(MarketplaceReview.created_at.desc())
            .limit(50)
        )
    ).scalars().all()
    return MarketplaceStoreReviews(
        rating_avg=round(listing.rating_avg or 0.0, 1),
        rating_count=listing.rating_count or 0,
        reviews=[
            MarketplaceReviewRead(
                id=r.id,
                rating=r.rating,
                comment=r.comment,
                author_name=r.author_name,
                created_at=r.created_at,
            )
            for r in rows
        ],
    )


@router.post("/reviews", response_model=MarketplaceReviewRead, status_code=201)
@per_ip("20/minute")
async def submit_review(
    request: Request,
    payload: MarketplaceReviewCreate,
    db: DbSession,
):
    g = (
        await db.execute(
            select(GuestOrder).where(
                GuestOrder.id == payload.order_id,
                GuestOrder.channel == "marketplace",
            )
        )
    ).scalar_one_or_none()
    if not g or _order_access_token(g) != payload.access_token:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if g.status != "merged" and g.payment_status != "paid":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "只能評價已完成的訂單")
    existing = (
        await db.execute(
            select(MarketplaceReview).where(MarketplaceReview.guest_order_id == g.id)
        )
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "此訂單已評價")

    listing = (
        await db.execute(
            select(MarketplaceListing).where(MarketplaceListing.store_id == g.store_id)
        )
    ).scalar_one_or_none()
    if not listing:
        raise HTTPException(status.HTTP_404_NOT_FOUND)

    review = MarketplaceReview(
        listing_id=listing.id,
        tenant_id=g.tenant_id,
        store_id=g.store_id,
        guest_order_id=g.id,
        rating=payload.rating,
        comment=payload.comment,
        author_name=g.customer_name,
    )
    db.add(review)
    # Recompute aggregate rating incrementally.
    prev_total = (listing.rating_avg or 0.0) * (listing.rating_count or 0)
    listing.rating_count = (listing.rating_count or 0) + 1
    listing.rating_avg = (prev_total + payload.rating) / listing.rating_count
    await db.flush()
    await db.commit()
    await db.refresh(review)
    return MarketplaceReviewRead(
        id=review.id,
        rating=review.rating,
        comment=review.comment,
        author_name=review.author_name,
        created_at=review.created_at,
    )
