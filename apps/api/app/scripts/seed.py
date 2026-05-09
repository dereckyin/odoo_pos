"""Seed the database with demo data.

Usage:
    python -m app.scripts.seed
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from ..core.db import get_session_factory
from ..core.security import generate_secret, hash_password, hash_secret
from ..models import (
    Category,
    Member,
    MemberLevel,
    Product,
    ProductBarcode,
    Promotion,
    Store,
    SubscriptionPlan,
    Tenant,
    TenantSubscription,
    Terminal,
    User,
)


PLATFORM_ADMIN_USERNAME = "platform_super"
PLATFORM_ADMIN_PASSWORD = "platform-secret-CHANGE-ME"


async def seed() -> None:
    factory = get_session_factory()
    async with factory() as db:
        if (await db.execute(select(Tenant).where(Tenant.code != "__legacy__"))).scalar_one_or_none():
            print("[seed] tenants already present; skipping")
            return

        # Cross-tenant platform super-admin (single account, no tenant_id).
        if not (await db.execute(
            select(User).where(User.username == PLATFORM_ADMIN_USERNAME)
        )).scalar_one_or_none():
            db.add(User(
                username=PLATFORM_ADMIN_USERNAME,
                password_hash=hash_password(PLATFORM_ADMIN_PASSWORD),
                display_name="Platform Operator",
                role="platform_super",
                is_active=True,
                must_change_password=True,
            ))

        starter = (
            await db.execute(select(SubscriptionPlan).where(SubscriptionPlan.code == "starter"))
        ).scalar_one_or_none()

        # Demo tenant
        tenant = Tenant(
            code="demo",
            name="Demo 旗艦店股份有限公司",
            contact_email="demo@example.com",
            tax_id="12345678",
            status="active",
            plan_code="starter",
        )
        db.add(tenant)
        await db.flush()

        if starter:
            db.add(TenantSubscription(
                tenant_id=tenant.id, plan_id=starter.id, status="active",
                started_at=datetime.now(timezone.utc),
            ))

        store = Store(
            tenant_id=tenant.id, code="S001", name="旗艦店", tax_id="12345678",
            address="台北市信義區市府路1號", phone="02-12345678",
        )
        db.add(store)
        await db.flush()

        terminal_key = generate_secret(32)
        terminal = Terminal(
            tenant_id=tenant.id, store_id=store.id, code="T01",
            api_key_hash=hash_secret(terminal_key),
        )
        db.add(terminal)

        admin = User(
            tenant_id=tenant.id, username="admin",
            password_hash=hash_password("admin123"),
            display_name="管理員", role="tenant_admin", store_id=store.id,
            is_active=True,
        )
        cashier = User(
            tenant_id=tenant.id, username="cashier",
            password_hash=hash_password("cashier123"),
            display_name="收銀員", role="cashier", store_id=store.id,
            is_active=True,
        )
        db.add_all([admin, cashier])

        levels = [
            MemberLevel(tenant_id=tenant.id, name="銅卡", discount_rate=0.98, min_spend=0, sort_order=10, color="#CD7F32"),
            MemberLevel(tenant_id=tenant.id, name="銀卡", discount_rate=0.95, min_spend=10000, sort_order=20, color="#C0C0C0"),
            MemberLevel(tenant_id=tenant.id, name="金卡", discount_rate=0.9, min_spend=50000, sort_order=30, color="#FFD700"),
            MemberLevel(tenant_id=tenant.id, name="白金卡", discount_rate=0.85, min_spend=200000, sort_order=40, color="#E5E4E2"),
        ]
        db.add_all(levels)
        await db.flush()
        gold = levels[2]

        member = Member(
            tenant_id=tenant.id,
            phone="0912345678", name="王小明", level_id=gold.id, points=120,
            joined_at=datetime.now(timezone.utc), email="ming@example.com",
        )
        db.add(member)

        cats: dict[str, Category] = {}
        for n in ["飲料", "零食", "便當/熟食", "生活用品", "煙酒"]:
            c = Category(tenant_id=tenant.id, name=n)
            db.add(c)
            cats[n] = c
        await db.flush()

        sample_products = [
            ("4710001000017", "可口可樂 350ml", 25, "飲料", None),
            ("4710001000024", "雪碧 350ml", 25, "飲料", None),
            ("4710001000031", "礦泉水 600ml", 18, "飲料", None),
            ("4710001000048", "舒跑 350ml", 25, "飲料", None),
            ("4710002000016", "樂事洋芋片", 35, "零食", None),
            ("4710002000023", "波卡洋芋片", 30, "零食", None),
            ("4710002000030", "義美夾心酥", 45, "零食", None),
            ("4710003000015", "御便當-雞腿", 95, "便當/熟食", None),
            ("4710003000022", "御便當-排骨", 85, "便當/熟食", None),
            ("4710003000039", "三角飯糰", 28, "便當/熟食", None),
            ("4710004000014", "舒潔面紙", 65, "生活用品", None),
            ("4710004000021", "盤尼西林牙膏", 75, "生活用品", None),
            ("4710005000013", "台啤經典 350ml", 38, "煙酒", None),
            ("4710005000020", "黑松沙士 600ml", 30, "飲料", None),
            ("4710006000012", "茶葉蛋", 13, "便當/熟食", None),
        ]
        for sku, name, price, cat, img in sample_products:
            p = Product(
                tenant_id=tenant.id, sku=sku, name=name, price_cents=price, tax_rate=0.05,
                category_id=cats[cat].id, is_active=True, unit="個",
                image_url=img,
            )
            db.add(p)
            await db.flush()
            db.add(ProductBarcode(tenant_id=tenant.id, product_id=p.id, barcode=sku))

        now = datetime.now(timezone.utc)
        promos = [
            Promotion(
                tenant_id=tenant.id,
                name="滿 200 折 20", strategy="thresholdAmountOff",
                config={"threshold_amount": 200, "off_amount": 20},
                priority=10,
                starts_at=now - timedelta(days=1), ends_at=now + timedelta(days=30),
                is_active=True, applicable_product_ids=[],
                applicable_category_ids=[], member_level_ids=[],
            ),
            Promotion(
                tenant_id=tenant.id,
                name="飲料第二件 8 折", strategy="nthItemDiscount",
                config={"nth": 2, "nth_discount_pct": 20},
                priority=20,
                starts_at=now - timedelta(days=1), ends_at=now + timedelta(days=30),
                is_active=True, applicable_product_ids=[],
                applicable_category_ids=[cats["飲料"].id], member_level_ids=[],
            ),
            Promotion(
                tenant_id=tenant.id,
                name="零食買二送一", strategy="buyXGetY",
                config={"buy_n": 2, "get_n": 1, "get_discount_pct": 100},
                priority=15,
                starts_at=now - timedelta(days=1), ends_at=now + timedelta(days=30),
                is_active=True, applicable_product_ids=[],
                applicable_category_ids=[cats["零食"].id], member_level_ids=[],
            ),
        ]
        db.add_all(promos)

        await db.commit()
        print("[seed] done.")
        print(f"  platform_super:   {PLATFORM_ADMIN_USERNAME} / {PLATFORM_ADMIN_PASSWORD}")
        print(f"  tenant:           code=demo")
        print(f"  tenant_admin:     admin / admin123")
        print(f"  cashier:          cashier / cashier123")
        print(f"  store:            S001  terminal: T01")
        print(f"  terminal_api_key: {terminal_key}")


if __name__ == "__main__":
    asyncio.run(seed())
