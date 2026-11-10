"""Notify 讀冊 my_api after a bookstore checkout is paid or refunded.

POS never sees cust_id and never writes Oracle. my_api re-fetches this
checkout with the partner key, maps it to the member, and writes ORDER_MAS
(or reverses it on refund with F0501).
"""
from __future__ import annotations

import hashlib
import hmac
import json
import logging
from typing import Any

import httpx
from sqlalchemy import or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import get_settings
from ..models import BookstoreCheckout

logger = logging.getLogger(__name__)


def sign_body(secret: str, body: bytes) -> str:
    return hmac.new(secret.encode("utf-8"), body, hashlib.sha256).hexdigest()


def _refund_url(settle_url: str) -> str:
    base = settle_url.rstrip("/")
    if base.endswith("/paid"):
        return base[: -len("/paid")] + "/refunded"
    return base + "/refunded"


def _resolve_url(settle_url: str) -> str:
    base = settle_url.rstrip("/")
    if base.endswith("/paid"):
        return base[: -len("/paid")] + "/resolve"
    return base + "/resolve"


async def _post_signed(url: str, secret: str, payload: dict) -> dict[str, Any] | None:
    body = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "X-Taaze-Signature": "sha256=" + sign_body(secret, body),
        "Accept": "application/json",
    }
    try:
        # Oracle refund (wallet + F0501) on my_api often exceeds 8s on 169/prod paths.
        async with httpx.AsyncClient(timeout=45.0, follow_redirects=False) as client:
            resp = await client.post(url, content=body, headers=headers)
        if resp.status_code >= 300:
            logger.warning(
                "taaze notify rejected url=%s checkout=%s status=%s body=%s",
                url,
                payload.get("checkout_id") or payload.get("q"),
                resp.status_code,
                (resp.text or "")[:300],
            )
            return None
        try:
            data = resp.json()
        except ValueError:
            return {}
        return data if isinstance(data, dict) else {}
    except httpx.HTTPError as exc:
        logger.warning(
            "taaze notify unreachable url=%s checkout=%s (%s)",
            url,
            payload.get("checkout_id") or payload.get("q"),
            type(exc).__name__,
        )
        return None


async def apply_settle_ids(
    db: AsyncSession,
    checkout_id: str,
    *,
    mas_no: str | None,
    inv_no: str | None,
) -> None:
    """Persist my_api mas_no / inv_no onto the checkout for later refund search."""
    values: dict[str, Any] = {}
    if mas_no:
        values["external_mas_no"] = str(mas_no).strip()[:16]
    if inv_no:
        values["invoice_number"] = str(inv_no).strip()[:32]
        values["invoice_status"] = "issued"
    if not values:
        return
    await db.execute(
        update(BookstoreCheckout)
        .where(BookstoreCheckout.id == checkout_id)
        .values(**values)
        .execution_options(synchronize_session=False)
    )
    await db.commit()


async def notify_paid(checkout_id: str, total_cents: int, db: AsyncSession | None = None) -> dict[str, Any] | None:
    s = get_settings()
    if not s.TAAZE_SETTLE_URL or not s.TAAZE_SETTLE_SECRET:
        return None
    data = await _post_signed(
        s.TAAZE_SETTLE_URL,
        s.TAAZE_SETTLE_SECRET,
        {"checkout_id": checkout_id, "status": "paid", "total_cents": int(total_cents)},
    )
    if data and db is not None:
        await apply_settle_ids(
            db,
            checkout_id,
            mas_no=str(data.get("mas_no") or "") or None,
            inv_no=str(data.get("inv_no") or "") or None,
        )
    return data


async def notify_refunded(checkout_id: str, total_cents: int, reason: str = "") -> bool:
    """Best-effort: POS stock is already restored; Oracle/F0501 run on my_api."""
    s = get_settings()
    if not s.TAAZE_SETTLE_URL or not s.TAAZE_SETTLE_SECRET:
        return False
    data = await _post_signed(
        _refund_url(s.TAAZE_SETTLE_URL),
        s.TAAZE_SETTLE_SECRET,
        {
            "checkout_id": checkout_id,
            "status": "refunded",
            "total_cents": int(total_cents),
            "reason": (reason or "")[:500],
        },
    )
    return data is not None


async def resolve_checkout_via_taaze(q: str) -> dict[str, Any] | None:
    """Ask my_api to map member-facing mas_no / inv_no to a POS checkout_id."""
    s = get_settings()
    if not s.TAAZE_SETTLE_URL or not s.TAAZE_SETTLE_SECRET:
        return None
    return await _post_signed(
        _resolve_url(s.TAAZE_SETTLE_URL),
        s.TAAZE_SETTLE_SECRET,
        {"q": (q or "").strip()[:64]},
    )


async def find_checkout_ids_by_q(
    db: AsyncSession,
    *,
    tenant_id: str,
    store_id: str,
    q: str,
    limit: int = 20,
) -> list[str]:
    """Local search by order_no / invoice_number / external_mas_no; then my_api fallback."""
    from ..models import Order

    needle = (q or "").strip()
    if not needle:
        return []
    like = f"%{needle}%"
    exact = needle.upper().replace(" ", "").replace("-", "")

    # Direct checkout fields
    rows = (
        await db.execute(
            select(BookstoreCheckout.id)
            .where(
                BookstoreCheckout.tenant_id == tenant_id,
                BookstoreCheckout.store_id == store_id,
                or_(
                    BookstoreCheckout.invoice_number.ilike(like),
                    BookstoreCheckout.external_mas_no.ilike(like),
                    BookstoreCheckout.invoice_number == exact,
                    BookstoreCheckout.external_mas_no == exact,
                ),
            )
            .order_by(BookstoreCheckout.created_at.desc())
            .limit(limit)
        )
    ).scalars().all()
    if rows:
        return list(rows)

    # POS order_no via joined Order
    order_rows = (
        await db.execute(
            select(BookstoreCheckout.id)
            .join(Order, Order.id == BookstoreCheckout.order_id)
            .where(
                BookstoreCheckout.tenant_id == tenant_id,
                BookstoreCheckout.store_id == store_id,
                Order.order_no.ilike(like),
            )
            .order_by(BookstoreCheckout.created_at.desc())
            .limit(limit)
        )
    ).scalars().all()
    if order_rows:
        return list(order_rows)

    # Historical: Oracle knows HH / mas_no → checkout UUID in REMARK
    resolved = await resolve_checkout_via_taaze(needle)
    cid = str((resolved or {}).get("checkout_id") or "").strip()
    if not cid:
        return []
    checkout = (
        await db.execute(
            select(BookstoreCheckout.id).where(
                BookstoreCheckout.id == cid,
                BookstoreCheckout.tenant_id == tenant_id,
                BookstoreCheckout.store_id == store_id,
            )
        )
    ).scalar_one_or_none()
    if not checkout:
        return []
    # Opportunistically backfill ids from resolve response
    await apply_settle_ids(
        db,
        cid,
        mas_no=str((resolved or {}).get("mas_no") or "") or None,
        inv_no=str((resolved or {}).get("inv_no") or "") or None,
    )
    return [cid]
