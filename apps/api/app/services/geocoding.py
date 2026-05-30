"""Reverse geocoding via OpenStreetMap Nominatim (free, rate-limited)."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Store

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
USER_AGENT = "OdooPOS/1.0 (store geocoding)"


async def geocode_address(address: str) -> dict | None:
    if not address or not address.strip():
        return None
    async with httpx.AsyncClient(timeout=15.0) as client:
        resp = await client.get(
            NOMINATIM_URL,
            params={"q": address.strip(), "format": "json", "limit": 1},
            headers={"User-Agent": USER_AGENT},
        )
        resp.raise_for_status()
        data = resp.json()
        if not data:
            return None
        hit = data[0]
        return {
            "latitude": float(hit["lat"]),
            "longitude": float(hit["lon"]),
            "label": hit.get("display_name"),
        }


async def geocode_store(db: AsyncSession, store: Store) -> Store:
    if not store.address:
        raise ValueError("store has no address")
    result = await geocode_address(store.address)
    if not result:
        raise ValueError("address could not be geocoded")
    store.latitude = result["latitude"]
    store.longitude = result["longitude"]
    store.geocode_label = result.get("label")
    store.geocoded_at = datetime.now(timezone.utc)
    await db.flush()
    return store


_geocode_lock = asyncio.Lock()
_last_geocode_at: float = 0.0


async def geocode_store_rate_limited(db: AsyncSession, store: Store) -> Store:
    """Respect Nominatim 1 req/s policy."""
    global _last_geocode_at
    async with _geocode_lock:
        import time

        now = time.monotonic()
        wait = 1.0 - (now - _last_geocode_at)
        if wait > 0:
            await asyncio.sleep(wait)
        result = await geocode_store(db, store)
        _last_geocode_at = time.monotonic()
        return result
