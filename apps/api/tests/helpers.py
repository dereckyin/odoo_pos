"""Common helpers for the test suite — DRYs out the multi-tenant setup
boilerplate so each test file can ask for ``await build_tenant(factory)``
and get a fully wired (tenant, store, terminal, admin, cashier, key)."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import async_sessionmaker

from app.core.security import generate_secret, hash_password, hash_secret
from app.models import Store, Tenant, Terminal, User


@dataclass
class TenantBundle:
    tenant: Tenant
    store: Store
    terminal: Terminal
    admin: User
    cashier: User
    terminal_api_key: str


async def build_tenant(
    factory: async_sessionmaker,
    *,
    tenant_code: str = "demo",
    store_code: str = "S001",
    terminal_code: str = "T01",
    admin_username: str = "admin",
    cashier_username: str = "cashier",
) -> TenantBundle:
    api_key = generate_secret(16)
    async with factory() as db:
        tenant = Tenant(
            code=tenant_code,
            name=f"Tenant {tenant_code}",
            contact_email=f"{tenant_code}@example.com",
            status="active",
        )
        db.add(tenant)
        await db.flush()
        store = Store(tenant_id=tenant.id, code=store_code, name=f"{tenant_code}-{store_code}")
        db.add(store)
        await db.flush()
        terminal = Terminal(
            tenant_id=tenant.id,
            store_id=store.id,
            code=terminal_code,
            api_key_hash=hash_secret(api_key),
        )
        db.add(terminal)
        admin = User(
            tenant_id=tenant.id,
            username=admin_username,
            password_hash=hash_password("admin123"),
            display_name="Admin",
            role="tenant_admin",
            store_id=store.id,
            is_active=True,
        )
        cashier = User(
            tenant_id=tenant.id,
            username=cashier_username,
            password_hash=hash_password("cashier123"),
            display_name="Cashier",
            role="cashier",
            store_id=store.id,
            is_active=True,
        )
        db.add_all([admin, cashier])
        await db.commit()
        await db.refresh(tenant)
        await db.refresh(store)
        await db.refresh(terminal)
        await db.refresh(admin)
        await db.refresh(cashier)
        return TenantBundle(
            tenant=tenant,
            store=store,
            terminal=terminal,
            admin=admin,
            cashier=cashier,
            terminal_api_key=api_key,
        )


async def login_pos(client, bundle: TenantBundle, *, username: str = "admin",
                    password: str = "admin123") -> str:
    r = await client.post(
        "/auth/login",
        json={
            "tenant_code": bundle.tenant.code,
            "store_code": bundle.store.code,
            "terminal_code": bundle.terminal.code,
            "terminal_api_key": bundle.terminal_api_key,
            "username": username,
            "password": password,
        },
    )
    assert r.status_code == 200, r.text
    return r.json()["access_token"]


async def login_admin(client, bundle: TenantBundle, *, username: str = "admin",
                      password: str = "admin123") -> str:
    r = await client.post(
        "/auth/admin-login",
        json={
            "tenant_code": bundle.tenant.code,
            "username": username,
            "password": password,
        },
    )
    assert r.status_code == 200, r.text
    return r.json()["access_token"]
