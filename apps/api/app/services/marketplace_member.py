"""Unified marketplace member identity.

The marketplace acts like Uber Eats: one phone number = one account that works
across every approved store. We implement this on top of the existing Alliance
primitives by reserving a single platform-level ``AllianceNetwork`` (the
"marketplace alliance"). Every approved marketplace tenant is auto-enrolled as
an ``AllianceTenant`` of that network, and ``AllianceMember`` becomes the
cross-store identity. ``TenantMemberLink`` ties it to each store's local
``Member`` so POS / loyalty flows keep working unchanged.
"""
from __future__ import annotations

import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.security import create_token_with_ttl, decode_token
from ..models import (
    AllianceMember,
    AllianceNetwork,
    AllianceTenant,
)

MARKETPLACE_ALLIANCE_CODE = "__MARKETPLACE__"
MARKETPLACE_ALLIANCE_NAME = "跨店市集會員"
MEMBER_TOKEN_KIND = "mp_member"
MEMBER_TOKEN_TTL = timedelta(days=60)


@dataclass
class MarketplaceMemberContext:
    alliance_member_id: str
    alliance_id: str
    phone: str


async def get_or_create_marketplace_alliance(db: AsyncSession) -> AllianceNetwork:
    net = (
        await db.execute(
            select(AllianceNetwork).where(
                AllianceNetwork.code == MARKETPLACE_ALLIANCE_CODE,
            )
        )
    ).scalar_one_or_none()
    if net and net.deleted_at is None:
        return net
    net = AllianceNetwork(
        name=MARKETPLACE_ALLIANCE_NAME,
        code=MARKETPLACE_ALLIANCE_CODE,
        description="Platform-managed marketplace loyalty network",
        status="active",
    )
    db.add(net)
    await db.flush()
    return net


async def ensure_tenant_in_marketplace_alliance(db: AsyncSession, tenant_id: str) -> AllianceTenant:
    """Auto-enroll a tenant into the marketplace alliance (idempotent)."""
    net = await get_or_create_marketplace_alliance(db)
    existing = (
        await db.execute(
            select(AllianceTenant).where(
                AllianceTenant.alliance_id == net.id,
                AllianceTenant.tenant_id == tenant_id,
            )
        )
    ).scalar_one_or_none()
    if existing:
        if existing.status != "active":
            existing.status = "active"
        return existing
    at = AllianceTenant(
        alliance_id=net.id,
        tenant_id=tenant_id,
        data_scope="points",
        status="active",
        joined_at=datetime.now(timezone.utc),
    )
    db.add(at)
    await db.flush()
    return at


def _gen_referral_code() -> str:
    return secrets.token_hex(4).upper()


async def ensure_referral_code(db: AsyncSession, am: AllianceMember) -> str:
    if am.referral_code:
        return am.referral_code
    for _ in range(8):
        code = _gen_referral_code()
        clash = (
            await db.execute(
                select(AllianceMember.id).where(AllianceMember.referral_code == code)
            )
        ).scalar_one_or_none()
        if not clash:
            am.referral_code = code
            await db.flush()
            return code
    # extremely unlikely fall-through
    am.referral_code = _gen_referral_code() + secrets.token_hex(2).upper()
    await db.flush()
    return am.referral_code


def issue_member_token(am: AllianceMember) -> tuple[str, datetime]:
    return create_token_with_ttl(
        am.id,
        MEMBER_TOKEN_TTL,
        claims={
            "kind": MEMBER_TOKEN_KIND,
            "alliance_id": am.alliance_id,
            "phone": am.phone,
        },
    )


def decode_member_token(token: str) -> MarketplaceMemberContext:
    try:
        claims = decode_token(token)
    except ValueError as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, str(e)) from e
    if claims.get("kind") != MEMBER_TOKEN_KIND:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "invalid member token")
    return MarketplaceMemberContext(
        alliance_member_id=claims["sub"],
        alliance_id=claims.get("alliance_id", ""),
        phone=claims.get("phone", ""),
    )


async def resolve_marketplace_member(
    db: AsyncSession,
    *,
    phone: str,
    name: str | None = None,
) -> AllianceMember:
    """Find or create the cross-store member for a phone number."""
    net = await get_or_create_marketplace_alliance(db)
    am = (
        await db.execute(
            select(AllianceMember).where(
                AllianceMember.alliance_id == net.id,
                AllianceMember.phone == phone,
                AllianceMember.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if am is None:
        am = AllianceMember(
            alliance_id=net.id,
            phone=phone,
            name=name,
            verified_at=datetime.now(timezone.utc),
        )
        db.add(am)
        await db.flush()
    elif name and not am.name:
        am.name = name
    return am
