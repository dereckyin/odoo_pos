"""Per-tenant feature module toggles (platform_super controlled).

Stored in ``Tenant.settings["modules"]``. Missing keys default to enabled so
existing tenants keep current behaviour until platform turns a module off.
"""
from __future__ import annotations

from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.deps import DbSession, TenantScope
from ..models import Tenant

MODULE_ONLINE_ORDERING = "online_ordering"
MODULE_MARKETPLACE = "marketplace"
MODULE_BUSINESS_INTELLIGENCE = "business_intelligence"
MODULE_CONSIGNMENT_BOOKS = "consignment_books"
MODULE_LINE = "line"
MODULE_EVENTS = "events"

ALL_MODULES = (
    MODULE_ONLINE_ORDERING,
    MODULE_MARKETPLACE,
    MODULE_BUSINESS_INTELLIGENCE,
    MODULE_CONSIGNMENT_BOOKS,
    MODULE_LINE,
    MODULE_EVENTS,
)

DEFAULT_MODULES: dict[str, bool] = {
    MODULE_ONLINE_ORDERING: False,
    MODULE_MARKETPLACE: False,
    MODULE_BUSINESS_INTELLIGENCE: False,
    MODULE_CONSIGNMENT_BOOKS: True,
    MODULE_LINE: False,
    MODULE_EVENTS: False,
}

MODULE_LABELS: dict[str, str] = {
    MODULE_ONLINE_ORDERING: "桌邊點餐",
    MODULE_MARKETPLACE: "市集上架",
    MODULE_BUSINESS_INTELLIGENCE: "商業智慧",
    MODULE_CONSIGNMENT_BOOKS: "寄賣書籍",
    MODULE_LINE: "LINE 官方帳號",
    MODULE_EVENTS: "活動報名/票券",
}


def read_modules_from_settings(settings: dict | None) -> dict[str, bool]:
    raw = (settings or {}).get("modules") or {}
    return {
        key: bool(raw.get(key, DEFAULT_MODULES[key])) for key in ALL_MODULES
    }


async def get_tenant_modules(db: AsyncSession, tenant_id: str) -> dict[str, bool]:
    tenant = await db.get(Tenant, tenant_id)
    if tenant is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "tenant not found")
    return read_modules_from_settings(tenant.settings)


async def assert_tenant_module(db: AsyncSession, tenant_id: str, module: str) -> None:
    if module not in ALL_MODULES:
        raise ValueError(f"unknown module: {module}")
    mods = await get_tenant_modules(db, tenant_id)
    if not mods.get(module, True):
        label = MODULE_LABELS.get(module, module)
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            f"此租戶已停用「{label}」模組",
        )


def apply_modules_patch(settings: dict | None, patch: dict[str, bool | None]) -> dict:
    merged = dict(settings or {})
    current = read_modules_from_settings(merged)
    for key in ALL_MODULES:
        if patch.get(key) is not None:
            current[key] = bool(patch[key])
    merged["modules"] = current
    return merged


async def require_online_ordering(db: DbSession, scope: TenantScope) -> None:
    if scope.tenant_id:
        await assert_tenant_module(db, scope.tenant_id, MODULE_ONLINE_ORDERING)


async def require_marketplace(db: DbSession, scope: TenantScope) -> None:
    if scope.tenant_id:
        await assert_tenant_module(db, scope.tenant_id, MODULE_MARKETPLACE)


async def require_guest_order_admin(db: DbSession, scope: TenantScope) -> None:
    """Guest-order staff API: allowed when table-side or marketplace module is on."""
    if not scope.tenant_id:
        return
    mods = await get_tenant_modules(db, scope.tenant_id)
    if mods.get(MODULE_ONLINE_ORDERING) or mods.get(MODULE_MARKETPLACE):
        return
    raise HTTPException(
        status.HTTP_403_FORBIDDEN,
        "此租戶已停用「桌邊點餐」與「市集上架」模組",
    )


async def require_business_intelligence(db: DbSession, scope: TenantScope) -> None:
    if scope.tenant_id:
        await assert_tenant_module(db, scope.tenant_id, MODULE_BUSINESS_INTELLIGENCE)


async def require_line(db: DbSession, scope: TenantScope) -> None:
    if scope.tenant_id:
        await assert_tenant_module(db, scope.tenant_id, MODULE_LINE)


async def require_events(db: DbSession, scope: TenantScope) -> None:
    if scope.tenant_id:
        await assert_tenant_module(db, scope.tenant_id, MODULE_EVENTS)


def online_ordering_dep():
    return Depends(require_online_ordering)


def business_intelligence_dep():
    return Depends(require_business_intelligence)
