"""Historical weather via Open-Meteo (free, no API key)."""

from __future__ import annotations

import httpx

OPEN_METEO_URL = "https://archive-api.open-meteo.com/v1/archive"


async def fetch_daily_weather(
    latitude: float,
    longitude: float,
    start_date: str,
    end_date: str,
) -> list[dict]:
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.get(
            OPEN_METEO_URL,
            params={
                "latitude": latitude,
                "longitude": longitude,
                "start_date": start_date,
                "end_date": end_date,
                "daily": "temperature_2m_mean,precipitation_sum",
                "timezone": "auto",
            },
        )
        resp.raise_for_status()
        data = resp.json()
    daily = data.get("daily") or {}
    dates = daily.get("time") or []
    temps = daily.get("temperature_2m_mean") or []
    precips = daily.get("precipitation_sum") or []
    return [
        {
            "date": dates[i],
            "temp_c": temps[i] if i < len(temps) else None,
            "precip_mm": precips[i] if i < len(precips) else 0,
            "rainy": (precips[i] or 0) > 1.0 if i < len(precips) else False,
        }
        for i in range(len(dates))
    ]
