from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel


class OptionChoiceRead(ORMModel):
    id: str
    option_group_id: str
    name: str
    price_delta_cents: int
    is_default: bool
    sort_order: int
    is_active: bool
    updated_at: datetime
    deleted_at: datetime | None


class OptionChoiceCreate(BaseModel):
    name: str
    price_delta_cents: int = 0
    is_default: bool = False
    sort_order: int = 0
    is_active: bool = True


class OptionChoiceUpdate(BaseModel):
    name: str | None = None
    price_delta_cents: int | None = None
    is_default: bool | None = None
    sort_order: int | None = None
    is_active: bool | None = None


class OptionGroupRead(ORMModel):
    id: str
    tenant_id: str
    name: str
    selection_type: str
    is_required: bool
    min_selections: int
    max_selections: int | None
    sort_order: int
    choices: list[OptionChoiceRead] = Field(default_factory=list)
    updated_at: datetime
    deleted_at: datetime | None


class OptionGroupCreate(BaseModel):
    name: str
    selection_type: str = "single"
    is_required: bool = True
    min_selections: int = 0
    max_selections: int | None = None
    sort_order: int = 0


class OptionGroupUpdate(BaseModel):
    name: str | None = None
    selection_type: str | None = None
    is_required: bool | None = None
    min_selections: int | None = None
    max_selections: int | None = None
    sort_order: int | None = None


class ProductOptionGroupLink(BaseModel):
    option_group_id: str
    sort_order: int = 0
    is_required: bool | None = None


class ProductOptionGroupsSet(BaseModel):
    groups: list[ProductOptionGroupLink]


class ProductOptionChoiceOverrideItem(BaseModel):
    option_choice_id: str
    price_delta_cents: int | None = None
    is_hidden: bool = False


class ProductOptionOverridesSet(BaseModel):
    overrides: list[ProductOptionChoiceOverrideItem]


class ProductOptionChoiceOverrideRead(ORMModel):
    id: str
    product_id: str
    option_choice_id: str
    price_delta_cents: int | None
    is_hidden: bool
    updated_at: datetime


class ProductOptionGroupRead(BaseModel):
    option_group_id: str
    sort_order: int
    is_required: bool | None
    option_group: OptionGroupRead


class SelectedOptionSnapshot(BaseModel):
    """Frozen option selection stored on order lines."""

    group_id: str
    group_name: str
    choice_id: str
    choice_name: str
    price_delta_cents: int = 0


class ProductOptionLinkRead(ORMModel):
    id: str
    product_id: str
    option_group_id: str
    sort_order: int
    is_required: bool | None
    updated_at: datetime


class ProductOptionChoiceOverrideSyncRead(ORMModel):
    id: str
    product_id: str
    option_choice_id: str
    price_delta_cents: int | None
    is_hidden: bool
    updated_at: datetime
