from datetime import datetime

from pydantic import BaseModel, Field

from ._base import ORMModel
from .guest_order import GuestOrderLineCreate, GuestOrderLineRead
from .public import PublicCategory, PublicMeta, PublicProduct


class MarketplaceStoreSummary(BaseModel):
    slug: str
    display_name: str
    tagline: str | None = None
    logo_url: str | None = None
    banner_url: str | None = None
    cuisine_tags: list[str] = Field(default_factory=list)
    min_order_cents: int = 0
    delivery_fee_cents: int = 0
    supports_pickup: bool = True
    supports_delivery: bool = False
    supports_dine_in: bool = False
    payment_counter: bool = True
    payment_online: bool = False
    store_address: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    distance_km: float | None = None
    is_open: bool = True
    prep_time_min: int = 15
    rating_avg: float = 0.0
    rating_count: int = 0
    price_level: int = 2
    is_favorite: bool = False


class MarketplaceStoreDetail(MarketplaceStoreSummary):
    store_id: str
    business_hours: dict | None = None


class MarketplaceMenuMeta(PublicMeta):
    slug: str
    display_name: str
    tagline: str | None = None
    logo_url: str | None = None
    supports_pickup: bool = True
    supports_delivery: bool = False
    supports_dine_in: bool = False
    payment_counter: bool = True
    payment_online: bool = False
    min_order_cents: int = 0
    delivery_fee_cents: int = 0
    is_open: bool = True


class MarketplaceMenu(BaseModel):
    meta: MarketplaceMenuMeta
    categories: list[PublicCategory]
    root_category_ids: list[str] = Field(default_factory=list)
    products: list[PublicProduct]


class MarketplaceProductCard(BaseModel):
    product_id: str
    product_name: str
    price_cents: int
    image_url: str | None = None
    description: str | None = None
    has_options: bool = False
    feed_category_id: str
    feed_category_name: str
    store_slug: str
    store_name: str
    logo_url: str | None = None
    store_is_open: bool = True


class MarketplaceProductSearchHit(MarketplaceProductCard):
    """Backward-compatible alias for product search hits."""


class MarketplaceFeedCategory(BaseModel):
    id: str
    slug: str
    name: str
    icon: str | None = None
    product_count: int = 0


class MarketplaceProductFeedSection(BaseModel):
    category_id: str
    category_slug: str
    category_name: str
    icon: str | None = None
    products: list[MarketplaceProductCard] = Field(default_factory=list)


class MarketplaceProductFeed(BaseModel):
    sections: list[MarketplaceProductFeedSection] = Field(default_factory=list)


class MarketplaceFeedCategoryOption(BaseModel):
    """For admin product form dropdown."""
    id: str
    slug: str
    name: str
    icon: str | None = None


class MarketplaceOrderSubmit(BaseModel):
    fulfillment_type: str = Field(description="pickup | delivery | dine_in")
    payment_method: str = Field(description="counter | online")
    customer_name: str = Field(min_length=1, max_length=64)
    customer_phone: str = Field(min_length=1, max_length=32)
    customer_note: str | None = None
    party_size: int | None = Field(default=None, ge=1)
    member_id: str | None = None
    delivery_address: str | None = None
    delivery_lat: float | None = None
    delivery_lng: float | None = None
    delivery_note: str | None = None
    table_label: str | None = Field(default=None, description="Optional table number for dine_in")
    points_redeemed: int = Field(default=0, ge=0)
    coupon_code: str | None = None
    lines: list[GuestOrderLineCreate]


class MarketplaceOrderCreated(BaseModel):
    order_id: str
    access_token: str
    payment_method: str
    payment_status: str | None = None
    estimated_subtotal_cents: int


class MarketplaceStoreCart(BaseModel):
    """One store's portion of a multi-store checkout."""

    store_slug: str
    fulfillment_type: str = Field(description="pickup | delivery | dine_in")
    payment_method: str = Field(description="counter | online")
    delivery_address: str | None = None
    delivery_lat: float | None = None
    delivery_lng: float | None = None
    delivery_note: str | None = None
    table_label: str | None = None
    party_size: int | None = Field(default=None, ge=1)
    store_note: str | None = None
    points_redeemed: int = Field(default=0, ge=0)
    coupon_code: str | None = None
    lines: list[GuestOrderLineCreate]


class MarketplaceBatchOrderSubmit(BaseModel):
    """Multi-store checkout: shared contact info + per-store carts."""

    customer_name: str = Field(min_length=1, max_length=64)
    customer_phone: str = Field(min_length=1, max_length=32)
    carts: list[MarketplaceStoreCart] = Field(min_length=1)


class MarketplaceBatchOrderItem(BaseModel):
    order_id: str
    access_token: str
    store_slug: str
    store_name: str
    payment_method: str
    payment_status: str | None = None
    estimated_subtotal_cents: int


class MarketplaceBatchOrderCreated(BaseModel):
    order_group_id: str
    orders: list[MarketplaceBatchOrderItem]
    total_cents: int


class MarketplaceReviewCreate(BaseModel):
    order_id: str
    access_token: str
    rating: int = Field(ge=1, le=5)
    comment: str | None = Field(default=None, max_length=1000)


class MarketplaceReviewRead(BaseModel):
    id: str
    rating: int
    comment: str | None
    author_name: str | None
    created_at: datetime


class MarketplaceStoreReviews(BaseModel):
    rating_avg: float
    rating_count: int
    reviews: list[MarketplaceReviewRead]


class MarketplaceOrderRead(BaseModel):
    id: str
    status: str
    channel: str
    fulfillment_type: str | None
    payment_method: str | None
    payment_status: str | None
    delivery_status: str | None
    customer_name: str | None
    customer_phone: str | None
    delivery_address: str | None
    store_name: str
    store_slug: str
    estimated_subtotal_cents: int
    discount_cents: int = 0
    points_redeemed: int = 0
    order_group_id: str | None = None
    prep_time_min: int = 15
    eta_minutes: int | None = None
    can_review: bool = False
    has_review: bool = False
    customer_note: str | None
    party_size: int | None
    created_at: datetime
    accepted_at: datetime | None
    ready_at: datetime | None
    merged_at: datetime | None
    cancelled_at: datetime | None
    lines: list[GuestOrderLineRead]


class MarketplaceListingRead(ORMModel):
    id: str
    tenant_id: str
    store_id: str
    slug: str
    status: str
    display_name: str
    tagline: str | None
    logo_url: str | None
    banner_url: str | None
    cuisine_tags: list[str] | None
    min_order_cents: int
    delivery_fee_cents: int
    delivery_radius_km: float | None
    supports_pickup: bool
    supports_delivery: bool
    supports_dine_in: bool
    payment_counter: bool
    payment_online: bool
    business_hours: dict | None
    prep_time_min: int = 15
    rating_avg: float = 0.0
    rating_count: int = 0
    price_level: int = 2
    approved_at: datetime | None
    submitted_at: datetime | None
    created_at: datetime
    updated_at: datetime


class MarketplaceListingUpdate(BaseModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=128)
    tagline: str | None = Field(default=None, max_length=256)
    logo_url: str | None = None
    banner_url: str | None = None
    cuisine_tags: list[str] | None = None
    min_order_cents: int | None = Field(default=None, ge=0)
    delivery_fee_cents: int | None = Field(default=None, ge=0)
    delivery_radius_km: float | None = Field(default=None, ge=0)
    supports_pickup: bool | None = None
    supports_delivery: bool | None = None
    supports_dine_in: bool | None = None
    payment_counter: bool | None = None
    payment_online: bool | None = None
    business_hours: dict | None = None
    prep_time_min: int | None = Field(default=None, ge=0, le=240)
    price_level: int | None = Field(default=None, ge=1, le=3)
    store_id: str | None = None


class MarketplaceListingCreate(BaseModel):
    store_id: str
    display_name: str = Field(min_length=1, max_length=128)
    slug: str | None = Field(default=None, min_length=2, max_length=64)


class PaymentInitiateResponse(BaseModel):
    order_id: str
    payment_url: str | None = None
    payment_form_html: str | None = None
    message: str | None = None
