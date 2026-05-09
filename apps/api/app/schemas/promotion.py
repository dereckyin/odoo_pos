from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel


class PromotionRead(ORMModel):
    id: str
    tenant_id: str
    name: str
    strategy: str
    config: dict
    priority: int
    starts_at: datetime | None
    ends_at: datetime | None
    is_active: bool
    stackable: bool
    applicable_product_ids: list[str]
    applicable_category_ids: list[str]
    member_level_ids: list[str]
    description: str | None
    updated_at: datetime
    deleted_at: datetime | None


class PromotionCreate(BaseModel):
    name: str
    strategy: str
    config: dict = Field(default_factory=dict)
    priority: int = 0
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    is_active: bool = True
    stackable: bool = False
    applicable_product_ids: list[str] = []
    applicable_category_ids: list[str] = []
    member_level_ids: list[str] = []
    description: str | None = None


class PromotionUpdate(BaseModel):
    name: str | None = None
    strategy: str | None = None
    config: dict | None = None
    priority: int | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    is_active: bool | None = None
    stackable: bool | None = None
    applicable_product_ids: list[str] | None = None
    applicable_category_ids: list[str] | None = None
    member_level_ids: list[str] | None = None
    description: str | None = None
