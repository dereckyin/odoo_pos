"""Marketplace listing helpers: slug, virtual table, distance, business hours."""
from __future__ import annotations

import math
import re
from datetime import datetime, timezone
from uuid import uuid4
from zoneinfo import ZoneInfo

from sqlalchemy import select

from ..core.security import generate_secret
from ..models import DiningTable, MarketplaceListing, Store

LOCAL_TZ = ZoneInfo("Asia/Taipei")
WEEKDAYS = ("mon", "tue", "wed", "thu", "fri", "sat", "sun")


def slugify(text: str) -> str:
    s = text.strip().lower()
    s = re.sub(r"[^\w\s-]", "", s, flags=re.UNICODE)
    s = re.sub(r"[\s_]+", "-", s)
    s = re.sub(r"-+", "-", s).strip("-")
    return s[:60] or "store"


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlng / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def is_store_open(business_hours: dict | None, now: datetime | None = None) -> bool:
    """Return True when no hours configured (always open) or current time in a slot."""
    if not business_hours:
        return True
    now = now or datetime.now(LOCAL_TZ)
    if now.tzinfo is None:
        now = now.replace(tzinfo=LOCAL_TZ)
    else:
        now = now.astimezone(LOCAL_TZ)
    day_key = WEEKDAYS[now.weekday()]
    slots = business_hours.get(day_key) or business_hours.get(day_key.upper())
    if not slots:
        return False
    current = now.strftime("%H:%M")
    for slot in slots:
        open_t = slot.get("open", "")
        close_t = slot.get("close", "")
        if open_t and close_t and open_t <= current <= close_t:
            return True
    return False


async def ensure_unique_slug(db, base: str, exclude_id: str | None = None) -> str:
    candidate = slugify(base)
    suffix = 0
    while True:
        slug = candidate if suffix == 0 else f"{candidate}-{suffix}"
        stmt = select(MarketplaceListing.id).where(MarketplaceListing.slug == slug)
        if exclude_id:
            stmt = stmt.where(MarketplaceListing.id != exclude_id)
        existing = (await db.execute(stmt)).scalar_one_or_none()
        if not existing:
            return slug
        suffix += 1


async def get_or_create_web_dinein_table(db, store: Store) -> DiningTable:
    row = (
        await db.execute(
            select(DiningTable).where(
                DiningTable.store_id == store.id,
                DiningTable.is_virtual.is_(True),
                DiningTable.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if row:
        return row
    table = DiningTable(
        id=str(uuid4()),
        tenant_id=store.tenant_id,
        store_id=store.id,
        label="網路內用",
        public_token=generate_secret(32),
        is_active=True,
        is_virtual=True,
        note="Marketplace dine-in virtual table",
    )
    db.add(table)
    await db.flush()
    return table


def listing_to_summary(
    listing: MarketplaceListing,
    store: Store,
    *,
    lat: float | None = None,
    lng: float | None = None,
) -> dict:
    distance_km = None
    if lat is not None and lng is not None and store.latitude is not None and store.longitude is not None:
        distance_km = round(haversine_km(lat, lng, store.latitude, store.longitude), 2)
    return {
        "slug": listing.slug,
        "display_name": listing.display_name,
        "tagline": listing.tagline,
        "logo_url": listing.logo_url,
        "banner_url": listing.banner_url,
        "cuisine_tags": listing.cuisine_tags or [],
        "min_order_cents": listing.min_order_cents,
        "delivery_fee_cents": listing.delivery_fee_cents,
        "supports_pickup": listing.supports_pickup,
        "supports_delivery": listing.supports_delivery,
        "supports_dine_in": listing.supports_dine_in,
        "payment_counter": listing.payment_counter,
        "payment_online": listing.payment_online,
        "store_address": store.address,
        "latitude": store.latitude,
        "longitude": store.longitude,
        "distance_km": distance_km,
        "is_open": is_store_open(listing.business_hours),
        "prep_time_min": listing.prep_time_min,
        "rating_avg": round(listing.rating_avg or 0.0, 1),
        "rating_count": listing.rating_count or 0,
    }
