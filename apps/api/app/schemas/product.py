from datetime import datetime

from pydantic import BaseModel

from ._base import ORMModel


class CategoryRead(ORMModel):
    id: str
    tenant_id: str
    name: str
    parent_id: str | None
    sort_order: int
    color: str | None
    icon: str | None
    hide_from_public_ordering: bool = False
    hide_from_pos_browse: bool = False
    updated_at: datetime
    deleted_at: datetime | None
    depth: int = 0
    path_names: list[str] = []
    path_label: str = ""
    has_children: bool = False


class CategoryTreeNode(CategoryRead):
    children: list["CategoryTreeNode"] = []


CategoryTreeNode.model_rebuild()


class CategoryCreate(BaseModel):
    name: str
    parent_id: str | None = None
    sort_order: int = 0
    color: str | None = None
    icon: str | None = None
    hide_from_public_ordering: bool = False
    hide_from_pos_browse: bool = False


class CategoryUpdate(BaseModel):
    name: str | None = None
    parent_id: str | None = None
    sort_order: int | None = None
    color: str | None = None
    icon: str | None = None
    hide_from_public_ordering: bool | None = None
    hide_from_pos_browse: bool | None = None


class ProductRead(ORMModel):
    id: str
    tenant_id: str
    sku: str
    name: str
    price_cents: int
    cost_cents: int | None
    category_id: str | None
    image_url: str | None
    tax_rate: float
    is_weighted: bool
    unit: str
    is_active: bool
    description: str | None
    hide_from_public_ordering: bool = False
    hide_from_pos_browse: bool = False
    track_inventory: bool = True
    product_kind: str = "regular"
    marketplace_category_id: str | None = None
    barcodes: list[str]
    updated_at: datetime
    deleted_at: datetime | None

    @classmethod
    def from_orm_with_barcodes(cls, p) -> "ProductRead":
        return cls(
            id=p.id,
            tenant_id=p.tenant_id,
            sku=p.sku,
            name=p.name,
            price_cents=p.price_cents,
            cost_cents=p.cost_cents,
            category_id=p.category_id,
            image_url=p.image_url,
            tax_rate=p.tax_rate,
            is_weighted=p.is_weighted,
            unit=p.unit,
            is_active=p.is_active,
            description=p.description,
            hide_from_public_ordering=getattr(p, "hide_from_public_ordering", False),
            hide_from_pos_browse=getattr(p, "hide_from_pos_browse", False),
            track_inventory=getattr(p, "track_inventory", True),
            product_kind=getattr(p, "product_kind", "regular"),
            marketplace_category_id=getattr(p, "marketplace_category_id", None),
            barcodes=[b.barcode for b in p.barcodes],
            updated_at=p.updated_at,
            deleted_at=p.deleted_at,
        )


class ProductCreate(BaseModel):
    sku: str
    name: str
    price_cents: int
    cost_cents: int | None = None
    category_id: str | None = None
    image_url: str | None = None
    tax_rate: float = 0.05
    is_weighted: bool = False
    unit: str = "個"
    is_active: bool = True
    description: str | None = None
    hide_from_public_ordering: bool = False
    hide_from_pos_browse: bool = False
    track_inventory: bool = True
    marketplace_category_id: str | None = None
    barcodes: list[str] = []


class ProductUpdate(BaseModel):
    sku: str | None = None
    name: str | None = None
    price_cents: int | None = None
    cost_cents: int | None = None
    category_id: str | None = None
    image_url: str | None = None
    tax_rate: float | None = None
    is_weighted: bool | None = None
    unit: str | None = None
    is_active: bool | None = None
    description: str | None = None
    hide_from_public_ordering: bool | None = None
    hide_from_pos_browse: bool | None = None
    track_inventory: bool | None = None
    marketplace_category_id: str | None = None
    barcodes: list[str] | None = None
