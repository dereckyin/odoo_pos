from datetime import date, datetime

from pydantic import BaseModel

from ._base import ORMModel


class MemberLevelRead(ORMModel):
    id: str
    tenant_id: str
    name: str
    discount_rate: float
    min_spend: int
    min_points: int
    color: str | None
    sort_order: int


class MemberLevelCreate(BaseModel):
    name: str
    discount_rate: float = 1.0
    min_spend: int = 0
    min_points: int = 0
    color: str | None = None
    sort_order: int = 0


class MemberLevelUpdate(BaseModel):
    name: str | None = None
    discount_rate: float | None = None
    min_spend: int | None = None
    min_points: int | None = None
    color: str | None = None
    sort_order: int | None = None


class LoyaltyRuleRead(ORMModel):
    id: str
    tenant_id: str
    name: str
    rule_type: str
    spend_cents: int
    points_awarded: int
    category_ids: list
    level_multiplier: float
    is_active: bool
    sort_order: int
    valid_from: datetime | None
    valid_to: datetime | None


class LoyaltyRuleCreate(BaseModel):
    name: str
    rule_type: str = "earn"
    spend_cents: int = 100
    points_awarded: int = 1
    category_ids: list[str] = []
    level_multiplier: float = 1.0
    is_active: bool = True
    sort_order: int = 0
    valid_from: datetime | None = None
    valid_to: datetime | None = None


class LoyaltyRuleUpdate(BaseModel):
    name: str | None = None
    spend_cents: int | None = None
    points_awarded: int | None = None
    category_ids: list[str] | None = None
    level_multiplier: float | None = None
    is_active: bool | None = None
    sort_order: int | None = None
    valid_from: datetime | None = None
    valid_to: datetime | None = None


class LoyaltySettings(BaseModel):
    earn_enabled: bool = True
    redeem_enabled: bool = True
    point_value_cents: int = 1
    max_redeem_pct: int = 50
    point_expiry_days: int = 365
    auto_level: bool = True


class MemberRead(ORMModel):
    id: str
    tenant_id: str
    phone: str
    name: str
    email: str | None
    birthday: date | None
    points: int
    total_spent_cents: int
    level_id: str | None
    qr_code: str | None
    joined_at: datetime
    last_visit_at: datetime | None
    note: str | None
    updated_at: datetime
    deleted_at: datetime | None


class MemberCreate(BaseModel):
    phone: str
    name: str
    email: str | None = None
    birthday: date | None = None
    points: int = 0
    level_id: str | None = None
    qr_code: str | None = None
    note: str | None = None


class MemberUpdate(BaseModel):
    phone: str | None = None
    name: str | None = None
    email: str | None = None
    birthday: date | None = None
    points: int | None = None
    level_id: str | None = None
    qr_code: str | None = None
    note: str | None = None


class CouponRead(ORMModel):
    id: str
    tenant_id: str
    code: str
    type: str
    value: float
    member_id: str | None
    min_spend_cents: int
    expires_at: datetime | None
    used_at: datetime | None
    updated_at: datetime


class CouponCreate(BaseModel):
    code: str
    type: str
    value: float
    member_id: str | None = None
    min_spend_cents: int = 0
    expires_at: datetime | None = None


class PointTransactionCreate(BaseModel):
    member_id: str
    delta: int
    reason: str
    order_id: str | None = None
    expires_at: datetime | None = None


class PointTransactionRead(ORMModel):
    id: str
    tenant_id: str
    member_id: str
    delta: int
    reason: str
    order_id: str | None
    expires_at: datetime | None
    created_at: datetime
