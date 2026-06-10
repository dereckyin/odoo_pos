"""LINE Official Account webhook receiver (per-tenant).

Configure the webhook URL in the LINE Developers console as:
``https://<host>/api/v1/line/webhook/{tenant_id}``. Inbound events are
signature-verified with the tenant's channel secret before being accepted.
"""
import logging

from fastapi import APIRouter, Header, HTTPException, Request, status

from ...core.deps import DbSession
from ...models import Tenant
from ...services.line_oa import read_line_settings, verify_webhook_signature

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/line", tags=["line"])


@router.post("/webhook/{tenant_id}")
async def line_webhook(
    tenant_id: str,
    request: Request,
    db: DbSession,
    x_line_signature: str | None = Header(default=None, alias="X-Line-Signature"),
):
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "tenant not found")
    cfg = read_line_settings(tenant.settings)
    secret = cfg.get("channel_secret") or ""
    body = await request.body()
    if not verify_webhook_signature(secret, body, x_line_signature or ""):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "invalid signature")

    # Minimal handling: acknowledge. Event processing (follow/message/postback)
    # can be extended here as needed.
    try:
        payload = await request.json()
        events = payload.get("events", []) if isinstance(payload, dict) else []
        logger.info("line webhook tenant=%s events=%d", tenant_id, len(events))
    except Exception:  # noqa: BLE001
        pass
    return {"ok": True}
