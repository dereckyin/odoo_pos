"""End-to-end test of the public application + platform-admin approval
flow."""
from app.core import db as db_mod
from app.core.security import hash_password
from app.models import EmailOtp, SubscriptionPlan, User


async def test_full_apply_review_provisioning(app, client):
    factory = db_mod.get_session_factory()
    async with factory() as db:
        db.add(User(
            username="ops",
            password_hash=hash_password("ops-pass"),
            display_name="Ops",
            role="platform_super",
            is_active=True,
        ))
        db.add(SubscriptionPlan(
            code="starter", name="Starter", price_cents=0, interval="month",
            max_stores=1, max_terminals=2, max_orders_per_month=1000,
            max_products=200, is_active=True,
        ))
        await db.commit()

    # 1. Public submits an application.
    r = await client.post(
        "/public/applications",
        json={
            "company_name": "示範店家",
            "contact_name": "店長",
            "contact_email": "owner@example.com",
            "contact_phone": "0912345678",
            "tax_id": "12345678",
            "plan_code": "starter",
            "proposed_subdomain": "demoshop",
        },
    )
    assert r.status_code == 201, r.text
    app_id = r.json()["application_id"]

    # 2. Fetch the OTP code from the database (the stub mailer just logs it).
    async with factory() as db:
        from sqlalchemy import select

        otp = (
            await db.execute(
                select(EmailOtp).where(EmailOtp.email == "owner@example.com")
            )
        ).scalar_one()
        # Brute-force the 6-digit code by trying every value would be too slow;
        # instead we know the test instance and patch via the same hash check.
        # The stub `send_email` doesn't return the code, so we re-issue one we
        # KNOW (overwrite the hash).
        from app.core.security import hash_secret
        otp.code_hash = hash_secret("123456")
        await db.commit()

    # 3. Verify the application via OTP.
    r = await client.post(
        "/public/applications/verify",
        json={"application_id": app_id, "code": "123456"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "email_verified"

    # 4. Platform super logs in.
    r = await client.post(
        "/auth/admin-login",
        json={"username": "ops", "password": "ops-pass"},
    )
    assert r.status_code == 200, r.text
    super_token = r.json()["access_token"]

    # 5. Approve.
    r = await client.post(
        f"/platform/applications/{app_id}/approve",
        json={"plan_code": "starter", "owner_username": "owner"},
        headers={"Authorization": f"Bearer {super_token}"},
    )
    assert r.status_code == 200, r.text
    out = r.json()
    assert out["status"] == "provisioned"
    assert out["provisioned_tenant_id"]

    # 6. Listing tenants now includes the new one.
    r = await client.get(
        "/platform/tenants", headers={"Authorization": f"Bearer {super_token}"}
    )
    assert r.status_code == 200
    codes = {t["code"] for t in r.json()}
    assert "demoshop" in codes


async def test_apply_blocks_tenant_user_from_platform_endpoints(app, client):
    """A regular tenant_admin must NOT be able to call /platform/* endpoints."""
    factory = db_mod.get_session_factory()
    from .helpers import build_tenant, login_admin

    bundle = await build_tenant(factory, tenant_code="tt", admin_username="ttA",
                                cashier_username="ttC")
    token = await login_admin(client, bundle, username="ttA")
    r = await client.get(
        "/platform/applications", headers={"Authorization": f"Bearer {token}"}
    )
    assert r.status_code == 403


async def test_duplicate_application_email_rejected(app, client):
    r = await client.post(
        "/public/applications",
        json={
            "company_name": "Dup Shop",
            "contact_name": "Owner",
            "contact_email": "dup@example.com",
        },
    )
    assert r.status_code == 201
    r = await client.post(
        "/public/applications",
        json={
            "company_name": "Dup Shop 2",
            "contact_name": "Owner",
            "contact_email": "dup@example.com",
        },
    )
    assert r.status_code == 409
