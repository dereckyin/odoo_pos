"""Schemas for the *public* (no JWT) customer-facing ordering endpoints.

These intentionally do not reuse the staff-facing schemas one-to-one — we
only expose what a guest needs to render a menu and place an order, and we
strip every internal field (cost, deleted_at, etc.).
"""
from pydantic import BaseModel, Field


class PublicOptionChoice(BaseModel):
    id: str
    name: str
    price_delta_cents: int
    is_default: bool


class PublicOptionGroup(BaseModel):
    id: str
    name: str
    selection_type: str
    is_required: bool
    min_selections: int
    max_selections: int | None
    sort_order: int
    choices: list[PublicOptionChoice] = Field(default_factory=list)


class PublicCategory(BaseModel):
    id: str
    name: str
    parent_id: str | None = None
    depth: int = 0
    path_label: str = ""
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
    option_groups: list[PublicOptionGroup] = Field(default_factory=list)


class PublicMeta(BaseModel):
    table_id: str
    table_label: str
    store_id: str
    store_name: str
    store_address: str | None = None


class PublicMenu(BaseModel):
    meta: PublicMeta
    categories: list[PublicCategory]
    root_category_ids: list[str] = Field(default_factory=list)
    products: list[PublicProduct]
