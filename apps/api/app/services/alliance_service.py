"""Alliance identity resolution and cross-brand points."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import (
    AllianceMember,
    AlliancePointLedger,
    AllianceTenant,
    Member,
    TenantMemberLink,
)


async def tenant_alliance(db: AsyncSession, tenant_id: str) -> AllianceTenant | None:
    return (
        await db.execute(
            select(AllianceTenant).where(
                AllianceTenant.tenant_id == tenant_id,
                AllianceTenant.status == "active",
            )
        )
    ).scalar_one_or_none()


async def resolve_alliance_member(
    db: AsyncSession,
    *,
    alliance_id: str,
    tenant_id: str,
    phone: str,
    name: str | None = None,
) -> tuple[AllianceMember, Member]:
    """Find or create alliance + tenant member for phone."""
    am = (
        await db.execute(
            select(AllianceMember).where(
                AllianceMember.alliance_id == alliance_id,
                AllianceMember.phone == phone,
                AllianceMember.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    now = datetime.now(timezone.utc)
    if am is None:
        am = AllianceMember(
            alliance_id=alliance_id,
            phone=phone,
            name=name,
            verified_at=now,
        )
        db.add(am)
        await db.flush()

    link = (
        await db.execute(
            select(TenantMemberLink).where(
                TenantMemberLink.tenant_id == tenant_id,
                TenantMemberLink.alliance_member_id == am.id,
            )
        )
    ).scalar_one_or_none()
    if link:
        member = await db.get(Member, link.member_id)
        if member and member.deleted_at is None:
            return am, member

    existing = (
        await db.execute(
            select(Member).where(
                Member.tenant_id == tenant_id,
                Member.phone == phone,
                Member.deleted_at.is_(None),
            )
        )
    ).scalar_one_or_none()
    if existing:
        member = existing
    else:
        member = Member(
            tenant_id=tenant_id,
            phone=phone,
            name=name or phone,
            joined_at=now,
        )
        db.add(member)
        await db.flush()

    db.add(
        TenantMemberLink(
            alliance_id=alliance_id,
            alliance_member_id=am.id,
            tenant_id=tenant_id,
            member_id=member.id,
        )
    )
    return am, member


async def earn_alliance_points(
    db: AsyncSession,
    *,
    alliance_id: str,
    alliance_member_id: str,
    tenant_id: str,
    order_id: str,
    points: int,
) -> None:
    if points <= 0:
        return
    am = await db.get(AllianceMember, alliance_member_id)
    if not am:
        return
    am.points = am.points + points
    db.add(
        AlliancePointLedger(
            alliance_id=alliance_id,
            alliance_member_id=alliance_member_id,
            tenant_id=tenant_id,
            delta=points,
            reason=f"order:{order_id}",
            order_id=order_id,
        )
    )
