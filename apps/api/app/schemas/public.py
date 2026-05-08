"""Schemas for the *public* (no JWT) customer-facing ordering endpoints.

These intentionally do not reuse the staff-facing schemas one-to-one — we
only expose what a guest needs to render a menu and place an order, and we
strip every internal field (cost, deleted_at, etc.).
"""
from pydantic import BaseModel


class PublicCategory(BaseModel):
    id: str
    name: str
    sort_order: int
    color: str | None = None
    icon: str | None = None


class PublicProduct(BaseModel):
    id: str
    sku: str
    name: str
    price_cents: int
    category_id: str | None
    image_url: str | None
    unit: str
    description: str | None


class PublicMeta(BaseModel):
    table_id: str
    table_label: str
    store_id: str
    store_name: str
    store_address: str | None = None


class PublicMenu(BaseModel):
    meta: PublicMeta
    categories: list[PublicCategory]
    products: list[PublicProduct]
