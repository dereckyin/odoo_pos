"""Physical bookstore: partner API, reservations, payment notify, exit pass."""
from __future__ import annotations

import hashlib
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select, update

from app.core import db as db_mod
from app.core.config import get_settings
from app.integrations.payments.provider import _ecpay_check_mac
from app.models import (
    BookDetail,
    BookstoreCheckout,
    InventoryLevel,
    Order,
    Product,
    ProductBarcode,
    Tenant,
)
from app.services.bookstore import issue_door_qr
from app.services.tenant_modules import apply_modules_patch

from .helpers import build_tenant, login_admin

PARTNER_KEY = "partner-key-for-tests-0123456789abcdef"
CUST_A = "custhash_aaaaaaaaaaaaaaaa"
CUST_B = "custhash_bbbbbbbbbbbbbbbb"


@pytest.fixture
def bookstore_settings(monkeypatch):
    s = get_settings()
    monkeypatch.setattr(s, "BOOKSTORE_PARTNER_TENANT_CODE", "taaze")
    monkeypatch.setattr(s, "BOOKSTORE_PARTNER_KEY_SHA256", hashlib.sha256(PARTNER_KEY.encode()).hexdigest())
    monkeypatch.setattr(s, "BOOKSTORE_PARTNER_ALLOWED_IPS", "127.0.0.1/32")
    monkeypatch.setattr(s, "BOOKSTORE_SIGNING_SECRET", "x" * 40)
    monkeypatch.setattr(s, "BOOKSTORE_RETURN_URL_PREFIXES", "https://app.taaze.tw/")
    monkeypatch.setattr(s, "ECPAY_MERCHANT_ID", "3002607")
    monkeypatch.setattr(s, "ECPAY_HASH_KEY", "pwFHCqoQZGmho4w6")
    monkeypatch.setattr(s, "ECPAY_HASH_IV", "EkRm7iFT261dpevs")
    monkeypatch.setattr(s, "ECPAY_BASE_URL", "https://payment-stage.ecpay.com.tw")
    return s


def _headers(customer: str | None = CUST_A) -> dict:
    h = {"X-Partner-Key": PARTNER_KEY}
    if customer:
        h["X-Customer-Ref"] = customer
    return h


async def _setup(client, *, online: bool = True, cash_price_pct: int = 100):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory, tenant_code="taaze")
    async with factory() as db:
        tenant = await db.get(Tenant, bundle.tenant.id)
        tenant.settings = apply_modules_patch(tenant.settings, {"physical_bookstore": True})
        await db.commit()
    token = await login_admin(client, bundle)
    admin = {"Authorization": f"Bearer {token}"}
    r = await client.post(
        "/stores",
        headers=admin,
        json={"code": "TN01", "name": "台南大遠百", "store_kind": "bookstore"},
    )
    assert r.status_code == 201, r.text
    store_id = r.json()["id"]
    r = await client.patch(
        f"/bookstore/stores/{store_id}/settings",
        headers=admin,
        json={"online_payment_enabled": online, "cash_price_pct": cash_price_pct},
    )
    assert r.status_code == 200, r.text

    async with factory() as db:
        books = []
        for sku, name, isbn, price, qty in [
            ("BK-1", "小王子", "9789573317241", 250, 1),
            ("BK-2", "被討厭的勇氣", "9789861371955", 300, 3),
        ]:
            p = Product(tenant_id=bundle.tenant.id, sku=sku, name=name, price_cents=price)
            db.add(p)
            await db.flush()
            db.add(BookDetail(
                tenant_id=bundle.tenant.id, product_id=p.id, barcode=isbn,
                barcode_kind="isbn", isbn=isbn, author="作者", list_price_cents=price + 50,
            ))
            db.add(ProductBarcode(tenant_id=bundle.tenant.id, product_id=p.id, barcode=isbn))
            db.add(InventoryLevel(
                tenant_id=bundle.tenant.id, store_id=store_id, product_id=p.id, on_hand=qty,
            ))
            books.append(p.id)
        await db.commit()
    return bundle, admin, store_id, books


async def _presence(client, store_id: str, customer: str = CUST_A) -> str:
    factory = db_mod.get_session_factory()
    from app.models import Store

    async with factory() as db:
        store = await db.get(Store, store_id)
        content, _ = issue_door_qr(store)
    r = await client.post(
        "/partner/bookstore/door-qr/resolve", headers=_headers(customer), json={"content": content}
    )
    assert r.status_code == 200, r.text
    return r.json()["presence_token"]


async def _checkout(client, store_id, presence, lines, customer=CUST_A, request_id="req-00000001"):
    return await client.post(
        "/partner/bookstore/checkouts",
        headers=_headers(customer),
        json={
            "store_id": store_id,
            "presence_token": presence,
            "client_request_id": request_id,
            "lines": lines,
        },
    )


def _notify_payload(trade_no: str, amount: int) -> dict:
    s = get_settings()
    payload = {
        "MerchantID": s.ECPAY_MERCHANT_ID,
        "MerchantTradeNo": trade_no,
        "RtnCode": "1",
        "RtnMsg": "Succeeded",
        "TradeNo": "2409291200001",
        "TradeAmt": str(amount),
        "PaymentDate": "2026/09/29 12:00:00",
        "PaymentType": "Credit_CreditCard",
        "SimulatePaid": "0",
    }
    payload["CheckMacValue"] = _ecpay_check_mac(payload, s.ECPAY_HASH_KEY, s.ECPAY_HASH_IV)
    return payload


async def _pay(client, checkout_id: str) -> str:
    r = await client.post(
        f"/partner/bookstore/checkouts/{checkout_id}/pay", headers=_headers(), json={}
    )
    assert r.status_code == 200, r.text
    url = r.json()["payment_url"]
    path = url.split("http://test", 1)[1]
    page = await client.get(path)
    assert page.status_code == 200, page.text
    assert "MerchantTradeNo" in page.text
    factory = db_mod.get_session_factory()
    async with factory() as db:
        c = await db.get(BookstoreCheckout, checkout_id)
        return f"{c.payment_trade_no}{c.payment_attempts:02d}"


@pytest.mark.asyncio
async def test_bookstore_kind_requires_module(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory, tenant_code="food")
    token = await login_admin(client, bundle)
    r = await client.post(
        "/stores",
        headers={"Authorization": f"Bearer {token}"},
        json={"code": "B1", "name": "書店", "store_kind": "bookstore"},
    )
    assert r.status_code == 403


@pytest.mark.asyncio
async def test_partner_auth_rejects_bad_key(app, client, bookstore_settings):
    await _setup(client)
    r = await client.get("/partner/bookstore/stores")
    assert r.status_code == 401
    r = await client.get("/partner/bookstore/stores", headers={"X-Partner-Key": "wrong"})
    assert r.status_code == 401
    r = await client.get("/partner/bookstore/stores", headers=_headers(None))
    assert r.status_code == 200
    assert [s["name"] for s in r.json()] == ["台南大遠百"]


@pytest.mark.asyncio
async def test_partner_rejects_disallowed_ip(app, client, bookstore_settings, monkeypatch):
    await _setup(client)
    monkeypatch.setattr(bookstore_settings, "BOOKSTORE_PARTNER_ALLOWED_IPS", "10.0.0.0/8")
    r = await client.get("/partner/bookstore/stores", headers=_headers(None))
    assert r.status_code == 403


@pytest.mark.asyncio
async def test_catalog_and_lookup(app, client, bookstore_settings):
    _, _, store_id, books = await _setup(client)
    r = await client.get(f"/partner/bookstore/stores/{store_id}/products", headers=_headers())
    assert r.status_code == 200, r.text
    items = {i["name"]: i for i in r.json()["items"]}
    assert items["小王子"]["stock_status"] == "last_one"
    assert items["被討厭的勇氣"]["stock_status"] == "in_stock"
    assert "on_hand" not in items["小王子"]

    r = await client.get(
        f"/partner/bookstore/stores/{store_id}/lookup",
        params={"code": "978-986-137-195-5"},
        headers=_headers(),
    )
    assert r.status_code == 200, r.text
    assert r.json()["id"] == books[1]

    r = await client.get(
        f"/partner/bookstore/stores/{store_id}/lookup", params={"code": "9780000000000"}, headers=_headers()
    )
    assert r.status_code == 404
    assert r.json()["detail"]["code"] == "not_in_store"


@pytest.mark.asyncio
async def test_checkout_requires_presence_and_ignores_client_price(app, client, bookstore_settings):
    _, _, store_id, books = await _setup(client)
    r = await _checkout(client, store_id, "forged.token", [{"product_id": books[1], "qty": 1}])
    assert r.status_code == 403

    presence = await _presence(client, store_id)
    r = await client.post(
        "/partner/bookstore/checkouts",
        headers=_headers(),
        json={
            "store_id": store_id,
            "presence_token": presence,
            "client_request_id": "req-price-01",
            "lines": [{"product_id": books[1], "qty": 2, "unit_price_cents": 1}],
            "total_cents": 1,
        },
    )
    assert r.status_code == 201, r.text
    assert r.json()["total_cents"] == 600

    other = await _presence(client, store_id, CUST_B)
    r = await _checkout(client, store_id, presence, [{"product_id": books[1], "qty": 1}], customer=CUST_B)
    assert r.status_code == 403, "presence token is bound to the customer"
    assert other


@pytest.mark.asyncio
async def test_last_copy_only_sells_once(app, client, bookstore_settings):
    _, _, store_id, books = await _setup(client)
    pa = await _presence(client, store_id, CUST_A)
    pb = await _presence(client, store_id, CUST_B)
    r1 = await _checkout(client, store_id, pa, [{"product_id": books[0], "qty": 1}], customer=CUST_A)
    r2 = await _checkout(client, store_id, pb, [{"product_id": books[0], "qty": 1}], customer=CUST_B)
    assert r1.status_code == 201, r1.text
    assert r2.status_code == 409
    assert r2.json()["detail"]["code"] == "insufficient_stock"


@pytest.mark.asyncio
async def test_other_customer_cannot_read_checkout(app, client, bookstore_settings):
    _, _, store_id, books = await _setup(client)
    presence = await _presence(client, store_id)
    r = await _checkout(client, store_id, presence, [{"product_id": books[1], "qty": 1}])
    cid = r.json()["id"]
    r = await client.get(f"/partner/bookstore/checkouts/{cid}", headers=_headers(CUST_B))
    assert r.status_code == 404
    r = await client.post(f"/partner/bookstore/checkouts/{cid}/pay", headers=_headers(CUST_B), json={})
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_return_url_must_be_allowlisted(app, client, bookstore_settings):
    _, _, store_id, books = await _setup(client)
    presence = await _presence(client, store_id)
    cid = (await _checkout(client, store_id, presence, [{"product_id": books[1], "qty": 1}])).json()["id"]
    r = await client.post(
        f"/partner/bookstore/checkouts/{cid}/pay",
        headers=_headers(),
        json={"return_url": "https://evil.example/phish"},
    )
    assert r.status_code == 400


@pytest.mark.asyncio
async def test_payment_notify_settles_once_and_checks_amount(app, client, bookstore_settings):
    bundle, admin, store_id, books = await _setup(client)
    presence = await _presence(client, store_id)
    r = await _checkout(client, store_id, presence, [{"product_id": books[1], "qty": 2}])
    cid = r.json()["id"]
    trade_no = await _pay(client, cid)

    bad = await client.post("/public/bookstore/payments/ecpay/notify", data=_notify_payload(trade_no, 1))
    assert bad.text == "0|FAIL"

    tampered = _notify_payload(trade_no, 600)
    tampered["TradeAmt"] = "1"
    assert (await client.post("/public/bookstore/payments/ecpay/notify", data=tampered)).text == "0|FAIL"

    ok = await client.post("/public/bookstore/payments/ecpay/notify", data=_notify_payload(trade_no, 600))
    assert ok.text == "1|OK"
    replay = await client.post("/public/bookstore/payments/ecpay/notify", data=_notify_payload(trade_no, 600))
    assert replay.text == "1|OK"

    factory = db_mod.get_session_factory()
    async with factory() as db:
        level = (
            await db.execute(
                select(InventoryLevel).where(
                    InventoryLevel.store_id == store_id, InventoryLevel.product_id == books[1]
                )
            )
        ).scalar_one()
        assert float(level.on_hand) == 1
        assert float(level.reserved) == 0
        orders = (await db.execute(select(Order).where(Order.store_id == store_id))).scalars().all()
        assert len(orders) == 1
        assert orders[0].total_cents == 600

    r = await client.get(f"/partner/bookstore/checkouts/{cid}", headers=_headers())
    body = r.json()
    assert body["status"] == "paid"
    assert body["invoice_status"] == "skipped"
    exit_pass = body["exit_pass"]
    assert exit_pass and len(exit_pass["code"]) == 6

    v1 = await client.post(
        "/bookstore/exit-pass/verify", headers=admin, json={"token": exit_pass["token"], "store_id": store_id}
    )
    assert v1.status_code == 200, v1.text
    assert v1.json()["result"] == "valid"
    v2 = await client.post(
        "/bookstore/exit-pass/verify", headers=admin, json={"code": exit_pass["code"], "store_id": store_id}
    )
    assert v2.json()["result"] == "already_used"
    assert (
        await client.post(
            "/bookstore/exit-pass/verify", headers=admin, json={"token": "abc.def", "store_id": store_id}
        )
    ).json()["result"] == "invalid"

    refund = await client.post(
        f"/bookstore/checkouts/{cid}/refund", headers=admin, json={"reason": "顧客退貨"}
    )
    assert refund.status_code == 200, refund.text
    assert refund.json()["checkout"]["status"] == "refunded"
    async with factory() as db:
        level = (
            await db.execute(
                select(InventoryLevel).where(
                    InventoryLevel.store_id == store_id, InventoryLevel.product_id == books[1]
                )
            )
        ).scalar_one()
        assert float(level.on_hand) == 3


@pytest.mark.asyncio
async def test_expired_reservation_is_released(app, client, bookstore_settings):
    _, _, store_id, books = await _setup(client)
    pa = await _presence(client, store_id, CUST_A)
    r = await _checkout(client, store_id, pa, [{"product_id": books[0], "qty": 1}])
    cid = r.json()["id"]
    factory = db_mod.get_session_factory()
    async with factory() as db:
        await db.execute(
            update(BookstoreCheckout)
            .where(BookstoreCheckout.id == cid)
            .values(expires_at=datetime.now(timezone.utc) - timedelta(minutes=1))
        )
        await db.commit()

    pb = await _presence(client, store_id, CUST_B)
    r2 = await _checkout(client, store_id, pb, [{"product_id": books[0], "qty": 1}], customer=CUST_B)
    assert r2.status_code == 201, r2.text
    r = await client.get(f"/partner/bookstore/checkouts/{cid}", headers=_headers(CUST_A))
    assert r.json()["status"] == "expired"


@pytest.mark.asyncio
async def test_cash_at_counter_with_discount(app, client, bookstore_settings):
    _, admin, store_id, books = await _setup(client, online=False, cash_price_pct=95)
    stores = (await client.get("/partner/bookstore/stores", headers=_headers(None))).json()
    assert stores[0]["cash_price_pct"] == 95
    assert stores[0]["online_payment_enabled"] is False

    presence = await _presence(client, store_id)
    lines = [{"product_id": books[0], "qty": 1}, {"product_id": books[1], "qty": 1}]
    cid = (await _checkout(client, store_id, presence, lines)).json()["id"]

    r = await client.post(f"/partner/bookstore/checkouts/{cid}/pay", headers=_headers(), json={})
    assert r.status_code == 409
    assert r.json()["detail"]["code"] == "online_unavailable"

    r = await client.post(f"/partner/bookstore/checkouts/{cid}/cash", headers=_headers())
    assert r.status_code == 200, r.text
    body = r.json()
    assert (body["subtotal_cents"], body["discount_cents"], body["total_cents"]) == (550, 28, 522)
    assert body["payment_method"] == "cash"
    cash = body["cash_payment"]
    assert len(cash["code"]) == 6 and cash["token"].startswith("TAAZECASH1:")
    again = (await client.post(f"/partner/bookstore/checkouts/{cid}/cash", headers=_headers())).json()
    assert again["cash_payment"]["code"] == cash["code"] and again["total_cents"] == 522
    assert (
        await client.post(f"/partner/bookstore/checkouts/{cid}/cash", headers=_headers(CUST_B))
    ).status_code == 404

    found = await client.post(
        "/bookstore/cash/lookup", headers=admin, json={"code": cash["code"], "store_id": store_id}
    )
    assert found.json()["result"] == "found"
    assert found.json()["checkout"]["total_cents"] == 522
    by_qr = await client.post(
        "/bookstore/cash/lookup", headers=admin, json={"token": cash["token"], "store_id": store_id}
    )
    assert by_qr.json()["checkout"]["id"] == cid
    forged = await client.post(
        "/bookstore/cash/lookup", headers=admin, json={"token": "TAAZECASH1:a.b", "store_id": store_id}
    )
    assert forged.json()["result"] == "invalid"

    wrong = await client.post(
        f"/bookstore/checkouts/{cid}/cash-confirm", headers=admin, json={"expected_total_cents": 550}
    )
    assert wrong.status_code == 409
    ok = await client.post(
        f"/bookstore/checkouts/{cid}/cash-confirm", headers=admin, json={"expected_total_cents": 522}
    )
    assert ok.status_code == 200, ok.text
    assert ok.json()["status"] == "paid"
    dup = await client.post(
        f"/bookstore/checkouts/{cid}/cash-confirm", headers=admin, json={"expected_total_cents": 522}
    )
    assert dup.status_code == 409

    factory = db_mod.get_session_factory()
    async with factory() as db:
        order = (await db.execute(select(Order).where(Order.store_id == store_id))).scalar_one()
        assert (order.subtotal_cents, order.discount_cents, order.total_cents) == (550, 28, 522)
        c = await db.get(BookstoreCheckout, cid)
        assert c.payment_gateway == "cash" and c.cash_confirmed_by

    body = (await client.get(f"/partner/bookstore/checkouts/{cid}", headers=_headers())).json()
    assert body["status"] == "paid" and body["exit_pass"] and body["cash_payment"] is None
    again = await client.post(
        "/bookstore/cash/lookup", headers=admin, json={"code": cash["code"], "store_id": store_id}
    )
    assert again.json()["result"] == "already_paid"

    refund = await client.post(f"/bookstore/checkouts/{cid}/refund", headers=admin, json={"reason": "退貨"})
    assert "現金 NT$ 522" in refund.json()["message"]


@pytest.mark.asyncio
async def test_cash_disabled_or_after_online_started(app, client, bookstore_settings):
    _, admin, store_id, books = await _setup(client, online=True)
    presence = await _presence(client, store_id)
    cid = (await _checkout(client, store_id, presence, [{"product_id": books[1], "qty": 1}])).json()["id"]
    await _pay(client, cid)
    r = await client.post(f"/partner/bookstore/checkouts/{cid}/cash", headers=_headers())
    assert r.json()["detail"]["code"] == "online_started"

    await client.patch(f"/bookstore/stores/{store_id}/settings", headers=admin, json={"cash_enabled": False})
    cid2 = (
        await _checkout(client, store_id, presence, [{"product_id": books[1], "qty": 1}], request_id="req-cash-02")
    ).json()["id"]
    r = await client.post(f"/partner/bookstore/checkouts/{cid2}/cash", headers=_headers())
    assert r.json()["detail"]["code"] == "cash_unavailable"


def test_discount_allocation_and_invoice_lines():
    from types import SimpleNamespace

    from app.services.bookstore_checkout import allocate_discount, invoice_lines

    assert allocate_discount([250, 300], 28) == [13, 15]
    assert sum(allocate_discount([333, 333, 334], 100)) == 100
    assert allocate_discount([100], 0) == [0]

    lines = [
        SimpleNamespace(product_name="A", qty=3, line_total_cents=900),
        SimpleNamespace(product_name="B", qty=1, line_total_cents=250),
    ]
    out = invoice_lines(lines, 58)
    assert sum(ln.amount_cents for ln in out) == 1150 - 58
    for ln in out:
        assert ln.unit_price_cents * int(ln.qty) == ln.amount_cents


@pytest.mark.asyncio
async def test_idempotent_checkout_and_pending_limit(app, client, bookstore_settings):
    _, _, store_id, books = await _setup(client)
    presence = await _presence(client, store_id)
    line = [{"product_id": books[1], "qty": 1}]
    a = await _checkout(client, store_id, presence, line, request_id="req-same-001")
    b = await _checkout(client, store_id, presence, line, request_id="req-same-001")
    assert a.json()["id"] == b.json()["id"]
    await _checkout(client, store_id, presence, line, request_id="req-other-02")
    c = await _checkout(client, store_id, presence, line, request_id="req-other-03")
    assert c.status_code == 429
