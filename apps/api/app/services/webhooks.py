"""Fire-and-forget webhook queue (deliveries processed async in-process)."""
from __future__ import annotations

import hashlib
import hmac
import json

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import WebhookDelivery, WebhookSubscription


async def emit_webhook(
    db: AsyncSession,
    *,
    tenant_id: str,
    event: str,
    payload: dict,
) -> None:
    subs = (
        await db.execute(
            select(WebhookSubscription).where(
                WebhookSubscription.tenant_id == tenant_id,
                WebhookSubscription.is_active.is_(True),
            )
        )
    ).scalars().all()
    for sub in subs:
        if sub.events and event not in sub.events:
            continue
        db.add(
            WebhookDelivery(
                subscription_id=sub.id,
                event=event,
                payload=payload,
                status="pending",
            )
        )


async def deliver_pending_webhooks(db: AsyncSession, limit: int = 20) -> int:
    rows = (
        await db.execute(
            select(WebhookDelivery)
            .where(WebhookDelivery.status == "pending")
            .order_by(WebhookDelivery.created_at)
            .limit(limit)
        )
    ).scalars().all()
    delivered = 0
    for d in rows:
        sub = await db.get(WebhookSubscription, d.subscription_id)
        if not sub or not sub.is_active:
            d.status = "failed"
            d.last_error = "subscription inactive"
            continue
        body = json.dumps({"event": d.event, "data": d.payload}, ensure_ascii=False)
        headers = {"Content-Type": "application/json"}
        if sub.secret:
            sig = hmac.new(sub.secret.encode(), body.encode(), hashlib.sha256).hexdigest()
            headers["X-Webhook-Signature"] = sig
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(sub.url, content=body, headers=headers)
            if resp.status_code < 300:
                from datetime import datetime, timezone

                d.status = "delivered"
                d.delivered_at = datetime.now(timezone.utc)
                delivered += 1
            else:
                d.attempts = d.attempts + 1
                d.last_error = f"HTTP {resp.status_code}"
                if d.attempts >= 5:
                    d.status = "failed"
        except Exception as e:
            d.attempts = d.attempts + 1
            d.last_error = str(e)[:500]
            if d.attempts >= 5:
                d.status = "failed"
    await db.flush()
    return delivered
