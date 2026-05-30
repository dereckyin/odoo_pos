"""Tenant admin endpoints for marketplace listing management."""
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from ...core.deps import DbSession, TenantScope, apply_tenant, ensure_same_tenant
from ...models import MarketplaceListing, Store
from ...schemas.marketplace import (
    MarketplaceFeedCategoryOption,
    MarketplaceListingCreate,
    MarketplaceListingRead,
    MarketplaceListingUpdate,
)
from ...services.marketplace import ensure_unique_slug, slugify
from ...services.marketplace_category import load_marketplace_taxonomy

router = APIRouter(prefix="/marketplace", tags=["marketplace-admin"])


def _to_read(row: MarketplaceListing) -> MarketplaceListingRead:
    return MarketplaceListingRead(
        id=row.id,
        tenant_id=row.tenant_id,
        store_id=row.store_id,
        slug=row.slug,
        status=row.status,
        display_name=row.display_name,
        tagline=row.tagline,
        logo_url=row.logo_url,
        banner_url=row.banner_url,
        cuisine_tags=row.cuisine_tags,
        min_order_cents=row.min_order_cents,
        delivery_fee_cents=row.delivery_fee_cents,
        delivery_radius_km=row.delivery_radius_km,
        supports_pickup=row.supports_pickup,
        supports_delivery=row.supports_delivery,
        supports_dine_in=row.supports_dine_in,
        payment_counter=row.payment_counter,
        payment_online=row.payment_online,
        business_hours=row.business_hours,
        approved_at=row.approved_at,
        submitted_at=row.submitted_at,
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


async def _get_store(db, scope: TenantScope, store_id: str) -> Store:
    store = await db.get(Store, store_id)
    if not store or store.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "store not found")
    ensure_same_tenant(scope, store)
    return store


@router.get("/listings", response_model=list[MarketplaceListingRead])
async def list_listings(db: DbSession, scope: TenantScope):
    stmt = apply_tenant(select(MarketplaceListing), MarketplaceListing, scope)
    rows = (await db.execute(stmt.order_by(MarketplaceListing.created_at.desc()))).scalars().all()
    return [_to_read(r) for r in rows]


@router.get("/listing", response_model=MarketplaceListingRead | None)
async def get_listing(
    db: DbSession,
    scope: TenantScope,
    store_id: str | None = Query(default=None),
):
    target = store_id or scope.store_id
    if not target:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "store_id required")
    await _get_store(db, scope, target)
    row = (
        await db.execute(
            select(MarketplaceListing).where(MarketplaceListing.store_id == target)
        )
    ).scalar_one_or_none()
    return _to_read(row) if row else None


@router.post("/listings", response_model=MarketplaceListingRead, status_code=201)
async def create_listing(
    payload: MarketplaceListingCreate,
    db: DbSession,
    scope: TenantScope,
):
    store = await _get_store(db, scope, payload.store_id)
    existing = (
        await db.execute(
            select(MarketplaceListing).where(MarketplaceListing.store_id == store.id)
        )
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "listing already exists for this store")

    base_slug = payload.slug or slugify(f"{store.name}-{store.code}")
    slug = await ensure_unique_slug(db, base_slug)
    row = MarketplaceListing(
        tenant_id=scope.tenant_id,
        store_id=store.id,
        slug=slug,
        status="draft",
        display_name=payload.display_name,
    )
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return _to_read(row)


@router.patch("/listing/{listing_id}", response_model=MarketplaceListingRead)
async def update_listing(
    listing_id: str,
    payload: MarketplaceListingUpdate,
    db: DbSession,
    scope: TenantScope,
):
    row = await db.get(MarketplaceListing, listing_id)
    if not row:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, row)
    if row.status == "approved":
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "approved listing cannot be edited directly; contact platform to suspend first",
        )

    data = payload.model_dump(exclude_unset=True)
    if "store_id" in data:
        del data["store_id"]
    for k, v in data.items():
        setattr(row, k, v)
    await db.commit()
    await db.refresh(row)
    return _to_read(row)


@router.post("/listing/{listing_id}/submit", response_model=MarketplaceListingRead)
async def submit_listing(listing_id: str, db: DbSession, scope: TenantScope):
    row = await db.get(MarketplaceListing, listing_id)
    if not row:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, row)
    if row.status not in ("draft", "suspended"):
        raise HTTPException(status.HTTP_409_CONFLICT, f"cannot submit from status={row.status}")
    if not row.display_name:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "display_name required")
    row.status = "pending"
    row.submitted_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(row)
    return _to_read(row)


@router.get("/feed-categories", response_model=list[MarketplaceFeedCategoryOption])
async def list_feed_category_options(db: DbSession, scope: TenantScope):
    taxonomy = await load_marketplace_taxonomy(db)
    return [
        MarketplaceFeedCategoryOption(id=c.id, slug=c.slug, name=c.name, icon=c.icon)
        for c in taxonomy.categories
    ]
