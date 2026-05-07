from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any


@dataclass
class ChargeRequest:
    order_id: str
    amount_cents: int
    currency: str = "TWD"
    description: str | None = None
    return_url: str | None = None
    metadata: dict[str, Any] | None = None


@dataclass
class RefundRequest:
    payment_id: str
    gateway_ref: str
    amount_cents: int
    reason: str | None = None


@dataclass
class PaymentResult:
    gateway: str
    status: str  # pending | authorized | captured | failed
    gateway_ref: str | None = None
    redirect_url: str | None = None
    qr_payload: str | None = None
    deep_link: str | None = None
    raw: dict[str, Any] | None = None


@dataclass
class RefundResult:
    gateway: str
    status: str
    gateway_ref: str | None = None
    raw: dict[str, Any] | None = None


class PaymentDriver(ABC):
    name: str = "abstract"

    @abstractmethod
    async def charge(self, req: ChargeRequest) -> PaymentResult: ...

    @abstractmethod
    async def confirm(self, gateway_ref: str, payload: dict[str, Any]) -> PaymentResult: ...

    @abstractmethod
    async def refund(self, req: RefundRequest) -> RefundResult: ...
