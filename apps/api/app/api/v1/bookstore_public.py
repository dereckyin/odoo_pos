"""Browser-facing payment pages and the gateway notification for bookstore
checkouts. Payment success is only ever recorded from the signed gateway
notification; the pages the shopper's browser lands on just display state."""
import html
import logging

from fastapi import APIRouter, HTTPException, Query, Request, status
from fastapi.responses import HTMLResponse, PlainTextResponse

from ...core.audit import audit
from ...core.config import get_settings
from ...core.deps import DbSession
from ...core.ratelimit import per_ip
from ...models import Tenant
from ...services import bookstore_checkout as svc
from ...services.bookstore import verify_token
from ...services.bookstore_payment import (
    build_checkout_form,
    resolve_ecpay_credentials,
    verify_notify,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/public/bookstore", tags=["public-bookstore"])

_PAGE = """<!doctype html><html lang="zh-Hant"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="no-referrer"><title>{title}</title>
<style>body{{font-family:system-ui,-apple-system,"Noto Sans TC",sans-serif;margin:0;
padding:32px 20px;text-align:center;color:#212121;background:#fafafa}}
h1{{font-size:20px;margin:0 0 12px}}p{{color:#555;line-height:1.6}}
a.btn,button{{display:inline-block;margin-top:20px;padding:12px 28px;border-radius:24px;
border:0;background:#E91E63;color:#fff;font-size:16px;text-decoration:none}}</style>
</head><body>{body}</body></html>"""

_HEADERS = {
    "Cache-Control": "no-store",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
}


def _page(title: str, body: str, code: int = 200) -> HTMLResponse:
    return HTMLResponse(_PAGE.format(title=html.escape(title), body=body), status_code=code, headers=_HEADERS)


def _pay_claims(checkout_id: str, token: str) -> dict:
    body = verify_token("pay", token)
    if not body or body.get("k") != checkout_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return body


def _dev_simulation_allowed() -> bool:
    s = get_settings()
    return not s.is_production and s.ENV.lower() == "dev"


@router.get("/pay/{checkout_id}", response_class=HTMLResponse)
@per_ip("30/minute")
async def payment_page(request: Request, checkout_id: str, db: DbSession, t: str = Query(..., max_length=1024)):
    _pay_claims(checkout_id, t)
    checkout = await svc.load_checkout(db, checkout_id)
    if checkout is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    if checkout.status == "paid":
        return _page("已付款", "<h1>這筆結帳已付款</h1><p>請回到讀冊 App 查看出門憑證。</p>")
    try:
        trade_no = await svc.next_payment_trade_no(db, checkout)
    except HTTPException as e:
        detail = e.detail if isinstance(e.detail, dict) else {"message": str(e.detail)}
        return _page("無法付款", f"<h1>無法付款</h1><p>{html.escape(detail.get('message', ''))}</p>", 409)

    creds = await resolve_ecpay_credentials(db, checkout.tenant_id)
    s = get_settings()
    base = (s.BOOKSTORE_PUBLIC_BASE_URL or str(request.base_url)).rstrip("/")
    result_url = f"{base}/public/bookstore/pay/{checkout.id}/done?t={t}"
    if creds is None:
        await db.rollback()
        if _dev_simulation_allowed():
            return _page(
                "開發模式付款",
                "<h1>開發模式</h1><p>尚未設定金流，可模擬付款成功。</p>"
                f'<form method="post" action="{html.escape(base)}/public/bookstore/pay/'
                f'{html.escape(checkout.id)}/dev-simulate?t={html.escape(t)}">'
                f"<p>金額 NT$ {checkout.total_cents}</p><button type=\"submit\">模擬付款成功</button></form>",
            )
        return _page("暫停付款", "<h1>付款服務尚未開放</h1><p>請洽店員協助。</p>", 503)

    tenant = await db.get(Tenant, checkout.tenant_id)
    form = build_checkout_form(
        creds,
        merchant_trade_no=trade_no,
        amount=checkout.total_cents,
        item_names=[f"{ln.product_name} x{ln.qty}" for ln in checkout.lines],
        notify_url=f"{base}/public/bookstore/payments/ecpay/notify",
        result_url=result_url,
        tenant_settings=tenant.settings if tenant else None,
    )
    await db.commit()
    return _page("前往付款", "<p>正在前往付款頁…</p>" + form)


@router.api_route("/pay/{checkout_id}/done", methods=["GET", "POST"], response_class=HTMLResponse)
@per_ip("60/minute")
async def payment_done(request: Request, checkout_id: str, db: DbSession, t: str = Query(..., max_length=1024)):
    claims = _pay_claims_lenient(checkout_id, t)
    checkout = await svc.load_checkout(db, checkout_id)
    if checkout is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    back = ""
    if claims.get("r"):
        back = f'<a class="btn" href="{html.escape(claims["r"])}">回到讀冊 App</a>'
    if checkout.status == "paid":
        return _page("付款完成", f"<h1>付款完成</h1><p>請回到讀冊 App 出示出門憑證。</p>{back}")
    return _page(
        "付款處理中",
        "<h1>正在確認付款</h1><p>請回到讀冊 App，付款結果會在幾秒內更新。</p>" + back,
    )


def _pay_claims_lenient(checkout_id: str, token: str) -> dict:
    body = verify_token("pay", token, check_exp=False)
    if not body or body.get("k") != checkout_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return body


@router.post("/pay/{checkout_id}/dev-simulate", response_class=HTMLResponse)
async def dev_simulate(request: Request, checkout_id: str, db: DbSession, t: str = Query(..., max_length=1024)):
    if not _dev_simulation_allowed():
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    _pay_claims(checkout_id, t)
    checkout = await svc.load_checkout(db, checkout_id)
    if checkout is None or await resolve_ecpay_credentials(db, checkout.tenant_id) is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    trade_no = f"{checkout.payment_trade_no or 'DEV'}{checkout.payment_attempts:02d}"
    if await svc.mark_paid(db, checkout, merchant_trade_no=trade_no, gateway_trade_no="DEV", gateway="dev"):
        await svc.issue_invoice_for_checkout(db, checkout.id)
    return _page("付款完成", "<h1>模擬付款完成</h1><p>請回到讀冊 App。</p>")


@router.post("/payments/ecpay/notify", response_class=PlainTextResponse)
async def ecpay_notify(request: Request, db: DbSession):
    form = await request.form()
    payload = {k: str(v) for k, v in form.items()}
    checkout = await svc.find_by_trade_no(db, payload.get("MerchantTradeNo", ""))
    if checkout is None:
        return PlainTextResponse("0|FAIL")
    creds = await resolve_ecpay_credentials(db, checkout.tenant_id)
    verified = verify_notify(creds, payload) if creds else None
    if verified is None:
        logger.warning("bookstore notify rejected checkout=%s", checkout.id)
        return PlainTextResponse("0|FAIL")
    if verified.amount != checkout.total_cents:
        logger.error(
            "bookstore notify amount mismatch checkout=%s expected=%s got=%s",
            checkout.id, checkout.total_cents, verified.amount,
        )
        return PlainTextResponse("0|FAIL")

    changed = await svc.mark_paid(
        db,
        checkout,
        merchant_trade_no=verified.merchant_trade_no,
        gateway_trade_no=verified.gateway_trade_no,
        gateway="ecpay",
    )
    if changed:
        await audit(
            db,
            None,
            tenant_id=checkout.tenant_id,
            action="bookstore_checkout_paid",
            resource_type="bookstore_checkout",
            resource_id=checkout.id,
            request=request,
            extra={"total_cents": checkout.total_cents},
        )
        await db.commit()
        await svc.issue_invoice_for_checkout(db, checkout.id)
    return PlainTextResponse("1|OK")
