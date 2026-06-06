from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel


class DiscountPreset(BaseModel):
    label: str = Field(max_length=32)
    pct_off: int = Field(ge=0, le=100)


class ConsignmentBooksSettingsRead(BaseModel):
    book_share_pct: int = 60
    store_ids: list[str] = []
    discount_presets: list[DiscountPreset] = []


class ConsignmentBooksSettingsUpdate(BaseModel):
    book_share_pct: int | None = Field(default=None, ge=0, le=100)
    store_ids: list[str] | None = None
    discount_presets: list[DiscountPreset] | None = None


class ConsignmentPosConfig(BaseModel):
    enabled: bool
    book_share_pct: int = 60
    discount_presets: list[DiscountPreset] = []
    category_id: str | None = None


class BookLookupRead(BaseModel):
    barcode: str
    barcode_kind: str
    title: str
    author: str
    publisher: str
    isbn: str | None
    list_price_cents: int
    sale_price_cents: int | None = None
    category_main: str | None = None
    category_sub: str | None = None
    image_url: str | None = None
    pages: int | None = None
    publish_date: str | None = None
    translator: str | None = None
    is_second_hand: bool = False
    sale_disc: int | None = None
    source: str = "taaze"


class BookDetailRead(ORMModel):
    id: str
    tenant_id: str
    product_id: str
    barcode: str
    barcode_kind: str
    supplier_id: str | None
    author: str | None
    publisher: str | None
    isbn: str | None
    list_price_cents: int | None
    sale_disc: int | None = None
    updated_at: datetime


class BookProductRead(BaseModel):
    id: str
    sku: str
    name: str
    price_cents: int
    category_id: str | None
    image_url: str | None
    unit: str
    product_kind: str
    barcodes: list[str]
    author: str | None = None
    publisher: str | None = None
    isbn: str | None = None
    list_price_cents: int | None = None
    sale_disc: int | None = None
    on_hand: float | None = None


class BookReceiveRequest(BaseModel):
    barcode: str = Field(min_length=1)
    store_id: str | None = None
    qty: float = Field(gt=0)


class BookImportRowErrorRead(BaseModel):
    row: int
    barcode: str
    message: str


class BookImportResultRead(BaseModel):
    received: int = 0
    skipped: int = 0
    errors: list[BookImportRowErrorRead] = []


class ConsignmentSettlementRow(BaseModel):
    store_id: str
    store_name: str
    qty: float
    gross_revenue_cents: int = 0
    refund_cents: int = 0
    revenue_cents: int
    gross_book_share_cents: int = 0
    refund_book_share_cents: int = 0
    book_share_cents: int
    gross_restaurant_share_cents: int = 0
    refund_restaurant_share_cents: int = 0
    restaurant_share_cents: int


class ConsignmentSettlementReport(BaseModel):
    book_share_pct: int
    rows: list[ConsignmentSettlementRow]
    total_qty: float
    gross_revenue_cents: int = 0
    refund_cents: int = 0
    total_revenue_cents: int
    gross_book_share_cents: int = 0
    refund_book_share_cents: int = 0
    total_book_share_cents: int
    gross_restaurant_share_cents: int = 0
    refund_restaurant_share_cents: int = 0
    total_restaurant_share_cents: int
