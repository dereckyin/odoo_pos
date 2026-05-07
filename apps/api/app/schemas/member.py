from datetime import date, datetime

from pydantic import BaseModel

from ._base import ORMModel


class MemberLevelRead(ORMModel):
    id: str
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


class MemberRead(ORMModel):
    id: str
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
    code: str
    type: str
    value: float
    member_id: str | None
    min_spend_cents: int
    expires_at: datetime | None
    used_at: datetime | None


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
    member_id: str
    delta: int
    reason: str
    order_id: str | None
    expires_at: datetime | None
    created_at: datetime
