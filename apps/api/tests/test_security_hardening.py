"""IDS middleware, security headers, ECPay amount units, and upload sniffing."""
import pytest

from app.integrations.payments.provider import ECPayProvider, _ecpay_check_mac

from .helpers import build_tenant, login_admin
from app.core import db as db_mod

pytestmark = pytest.mark.asyncio

XSS = "<script>alert(1)</script><img src=x onerror=alert(1)>"
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 64
MID, KEY, IV = "3002607", "pwFHCqoQZGmho4w6", "EkRm7iFT261dpevs"


async def test_ids_blocks_combined_attack_payload(app, client):
    r = await client.post("/auth/login", json={"username": XSS, "password": "x"})
    assert r.status_code == 403
    assert "incident_id" in r.json()


async def test_ids_blocks_scanner_paths_and_user_agents(app, client):
    assert (await client.get("/.env")).status_code == 403
    assert (await client.get("/health", headers={"User-Agent": "sqlmap/1.7"})).status_code == 200
    assert (await client.get("/stores", headers={"User-Agent": "sqlmap/1.7"})).status_code == 403


async def test_ids_does_not_flag_normal_pos_text(app, client):
    body = {
        "username": "cashier-01",
        "password": "p@ss' OR '1'='1 -- <script>",
        "note": "桌 #5 -- 不要辣 / 少冰",
        "printer_url": "http://192.168.1.50:9100",
    }
    r = await client.post("/auth/login", json=body)
    assert r.status_code != 403


async def test_ids_bans_ip_after_repeated_blocks(app, client):
    for _ in range(3):
        assert (await client.get("/wp-login.php")).status_code == 403
    r = await client.get("/stores")
    assert r.status_code == 403


async def test_signed_webhooks_are_not_scanned(app, client):
    r = await client.post(
        "/public/marketplace/payments/webhook/ecpay",
        data={"CheckMacValue": "x", "CustomField1": XSS},
    )
    assert r.status_code == 200
    assert "0|FAIL" in r.text


def test_client_ip_behind_caddy_and_nginx():
    from app.core.client_ip import resolve_client_ip

    chain = {"x-forwarded-for": "61.216.10.20, 172.18.0.1"}
    assert resolve_client_ip("172.18.0.5", chain) == "61.216.10.20"
    spoofed = {"x-forwarded-for": "8.8.8.8, 61.216.10.20, 172.18.0.1"}
    assert resolve_client_ip("172.18.0.5", spoofed) == "61.216.10.20"
    assert resolve_client_ip("1.1.1.1", {"x-forwarded-for": "8.8.8.8"}) == "1.1.1.1"
    assert resolve_client_ip("127.0.0.1", {}) == "127.0.0.1"


async def test_security_headers(app, client):
    r = await client.get("/health")
    assert r.headers["x-content-type-options"] == "nosniff"
    assert r.headers["x-frame-options"] == "DENY"


async def test_marketplace_ecpay_uses_whole_twd():
    p = ECPayProvider(MID, KEY, IV, sandbox=True)
    res = await p.initiate(
        order_id="0f0e0d0c-0b0a-0908-0706-050403020100",
        amount_cents=380,
        description='店名"><script>x</script>',
        customer_name="",
        customer_phone="",
        return_url="https://shop.example/return",
        notify_url="https://api.example/notify",
    )
    assert 'name="TotalAmount" value="380"' in res.payment_form_html
    assert "<script>x</script>" not in res.payment_form_html

    with pytest.raises(ValueError):
        await p.initiate(order_id="x", amount_cents=0, description="d", customer_name="",
                         customer_phone="", return_url="r", notify_url="n")


async def test_marketplace_ecpay_notify_amount_and_simulate():
    payload = {"MerchantTradeNo": "T1", "TradeNo": "E1", "RtnCode": "1", "TradeAmt": "380", "SimulatePaid": "0"}
    payload["CheckMacValue"] = _ecpay_check_mac(payload, KEY, IV)
    assert await ECPayProvider(MID, KEY, IV, sandbox=True).verify_webhook(dict(payload)) == ("T1", "E1", 380)

    sim = {**{k: v for k, v in payload.items() if k != "CheckMacValue"}, "SimulatePaid": "1"}
    sim["CheckMacValue"] = _ecpay_check_mac(sim, KEY, IV)
    assert await ECPayProvider(MID, KEY, IV, sandbox=False).verify_webhook(dict(sim)) is None
    assert await ECPayProvider(MID, KEY, IV, sandbox=True).verify_webhook(dict(sim)) is not None

    tampered = {**payload, "TradeAmt": "1"}
    assert await ECPayProvider(MID, KEY, IV, sandbox=True).verify_webhook(tampered) is None


async def test_upload_rejects_disguised_html_and_renames_by_content(app, client):
    bundle = await build_tenant(db_mod.get_session_factory())
    headers = {"Authorization": f"Bearer {await login_admin(client, bundle)}"}

    evil = await client.post(
        "/uploads/images",
        files={"file": ("x.html", b"<html><script>steal()</script></html>", "image/png")},
        headers=headers,
    )
    assert evil.status_code == 400

    ok = await client.post(
        "/uploads/images", files={"file": ("x.html", PNG, "text/html")}, headers=headers
    )
    assert ok.status_code == 200, ok.text
    assert ok.json()["filename"].endswith(".png")

    served = await client.get(ok.json()["url"])
    assert served.status_code == 200
    assert "sandbox" in served.headers["content-security-policy"]
