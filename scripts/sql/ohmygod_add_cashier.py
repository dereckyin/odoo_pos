"""One-off: create cashier user for ohmygod tenant. Run on API container:
  docker exec pos_api_prod python /tmp/ohmygod_add_cashier.py
"""
import asyncio
from sqlalchemy import select

from app.core.db import get_session_factory
from app.core.security import hash_password
from app.models import Store, Tenant, User


async def main() -> None:
    factory = get_session_factory()
    async with factory() as db:
        tenant = (
            await db.execute(select(Tenant).where(Tenant.code == "ohmygod"))
        ).scalar_one()
        store = (
            await db.execute(
                select(Store).where(Store.tenant_id == tenant.id, Store.code == "MAIN")
            )
        ).scalar_one()

        existing = (
            await db.execute(
                select(User).where(User.tenant_id == tenant.id, User.username == "cashier")
            )
        ).scalar_one_or_none()
        if existing:
            existing.password_hash = hash_password("cashier123")
            existing.is_active = True
            existing.store_id = store.id
            existing.role = "cashier"
            existing.display_name = "收銀員"
            print("updated cashier / cashier123")
        else:
            db.add(
                User(
                    tenant_id=tenant.id,
                    store_id=store.id,
                    username="cashier",
                    password_hash=hash_password("cashier123"),
                    display_name="收銀員",
                    role="cashier",
                    is_active=True,
                )
            )
            print("created cashier / cashier123")
        await db.commit()


if __name__ == "__main__":
    asyncio.run(main())
