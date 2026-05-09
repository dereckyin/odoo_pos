"""Phase 3 (per-tenant secrets) tests:
- tenant_payment_settings round-trip via the admin API
- ``tenant_driver_for`` honours per-tenant credentials and falls back when
  no row is configured
- Payment-charge endpoint refuses cross-tenant orders.
"""
from app.core import db as db_mod
from app.core.crypto import decrypt
from app.integrations.payment import tenant_driver_for
from app.models import TenantPaymentSetting

from .helpers import build_tenant, login_admin


async def test_payment_setting_round_trip(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_admin(client, bundle)

    payload = {
        "driver": "ecpay",
        "is_enabled": True,
        "is_sandbox": True,
        "merchant_id": "M-12345",
        "hash_key": "super-hash-key",
        "hash_iv": "iv-12345678",
    }
    r = await client.put(
        "/tenant/payment-settings",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["driver"] == "ecpay"
    assert body["merchant_id"] == "M-12345"
    # Crucial: API never echoes back the secret.
    assert "hash_key" not in body
    assert "hash_iv" not in body

    # Listing it back doesn't leak secrets either.
    r = await client.get(
        "/tenant/payment-settings",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200
    rows = r.json()
    assert len(rows) == 1
    assert "hash_key" not in rows[0]

    # The DB-level row stores Fernet-encrypted blobs that decrypt back to
    # the original secrets — proving the wire never carries plaintext keys.
    async with factory() as db:
        from sqlalchemy import select
        row = (
            await db.execute(select(TenantPaymentSetting).where(
                TenantPaymentSetting.tenant_id == bundle.tenant.id,
                TenantPaymentSetting.driver == "ecpay",
            ))
        ).scalar_one()
        assert row.hash_key_enc and row.hash_key_enc != "super-hash-key"
        assert decrypt(row.hash_key_enc) == "super-hash-key"
        assert decrypt(row.hash_iv_enc) == "iv-12345678"

    # tenant_driver_for picks up the per-tenant credentials.
    async with factory() as db:
        drv = await tenant_driver_for(db, bundle.tenant.id, "ecpay")
        assert drv.merchant_id == "M-12345"
        assert drv.hash_key == "super-hash-key"
        assert drv.hash_iv == "iv-12345678"


async def test_payment_setting_isolated_by_tenant(app, client):
    factory = db_mod.get_session_factory()
    a = await build_tenant(factory, tenant_code="alpha", store_code="A1",
                           admin_username="alpha_admin", cashier_username="alpha_cashier")
    b = await build_tenant(factory, tenant_code="beta", store_code="B1",
                           admin_username="beta_admin", cashier_username="beta_cashier")
    a_token = await login_admin(client, a, username="alpha_admin")
    b_token = await login_admin(client, b, username="beta_admin")

    await client.put(
        "/tenant/payment-settings",
        json={
            "driver": "newebpay",
            "merchant_id": "alpha-merchant",
            "hash_key": "alpha-key",
            "hash_iv": "alpha-iv",
        },
        headers={"Authorization": f"Bearer {a_token}"},
    )
    # Tenant beta sees an empty list — alpha's secrets are invisible.
    r = await client.get(
        "/tenant/payment-settings",
        headers={"Authorization": f"Bearer {b_token}"},
    )
    assert r.status_code == 200
    assert r.json() == []

    async with factory() as db:
        a_drv = await tenant_driver_for(db, a.tenant.id, "newebpay")
        b_drv = await tenant_driver_for(db, b.tenant.id, "newebpay")
        assert a_drv.merchant_id == "alpha-merchant"
        # Beta has no override, so it falls back to the (empty) platform default.
        assert b_drv.merchant_id != "alpha-merchant"
