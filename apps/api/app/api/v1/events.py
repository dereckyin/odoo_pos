"""Event registration / ticketing (module-gated by ``events``)."""
import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import func, select

from ...core.deps import DbSession, StoreAdminDep, TenantScope, apply_tenant
from ...models import Event, EventRegistration
from ...services.tenant_modules import require_events

router = APIRouter(
    prefix="/events",
    tags=["events"],
    dependencies=[Depends(require_events)],
)


# --------------------------------------------------------------------------- #
# Schemas
# --------------------------------------------------------------------------- #
class EventBase(BaseModel):
    title: str
    description: str | None = None
    location: str | None = None
    image_url: str | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    capacity: int = 0
    price_cents: int = 0
    is_published: bool = False
    list_on_marketplace: bool = False


class EventCreate(EventBase):
    pass


class EventUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    location: str | None = None
    image_url: str | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    capacity: int | None = None
    price_cents: int | None = None
    is_published: bool | None = None
    list_on_marketplace: bool | None = None


class EventRead(EventBase):
    id: str
    registered_count: int = 0

    class Config:
        from_attributes = True


class RegistrationCreate(BaseModel):
    name: str
    phone: str | None = None
    member_id: str | None = None
    qty: int = 1


class RegistrationRead(BaseModel):
    id: str
    event_id: str
    member_id: str | None
    name: str
    phone: str | None
    qty: int
    amount_cents: int
    ticket_code: str
    status: str
    checked_in_at: datetime | None
    created_at: datetime

    class Config:
        from_attributes = True


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def _gen_ticket_code() -> str:
    return secrets.token_hex(4).upper()  # 8 hex chars


async def _registered_qty(db: DbSession, event_id: str) -> int:
    total = (
        await db.execute(
            select(func.coalesce(func.sum(EventRegistration.qty), 0)).where(
                EventRegistration.event_id == event_id,
                EventRegistration.status != "cancelled",
            )
        )
    ).scalar_one()
    return int(total)


async def _get_event(db: DbSession, scope, event_id: str) -> Event:
    ev = await db.get(Event, event_id)
    if not ev or ev.tenant_id != scope.tenant_id or ev.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "event not found")
    return ev


def _to_read(ev: Event, registered: int) -> EventRead:
    return EventRead(
        id=ev.id,
        title=ev.title,
        description=ev.description,
        location=ev.location,
        image_url=ev.image_url,
        starts_at=ev.starts_at,
        ends_at=ev.ends_at,
        capacity=ev.capacity,
        price_cents=ev.price_cents,
        is_published=ev.is_published,
        list_on_marketplace=ev.list_on_marketplace,
        registered_count=registered,
    )


# --------------------------------------------------------------------------- #
# Event CRUD
# --------------------------------------------------------------------------- #
@router.get("", response_model=list[EventRead])
async def list_events(db: DbSession, scope: TenantScope):
    rows = (
        await db.execute(
            apply_tenant(select(Event), Event, scope)
            .where(Event.deleted_at.is_(None))
            .order_by(Event.starts_at.desc().nullslast(), Event.created_at.desc())
        )
    ).scalars().all()
    out: list[EventRead] = []
    for ev in rows:
        out.append(_to_read(ev, await _registered_qty(db, ev.id)))
    return out


@router.post("", response_model=EventRead, status_code=201)
async def create_event(payload: EventCreate, db: DbSession, scope: StoreAdminDep):
    ev = Event(tenant_id=scope.tenant_id, **payload.model_dump())
    db.add(ev)
    await db.commit()
    await db.refresh(ev)
    return _to_read(ev, 0)


@router.get("/{event_id}", response_model=EventRead)
async def get_event(event_id: str, db: DbSession, scope: TenantScope):
    ev = await _get_event(db, scope, event_id)
    return _to_read(ev, await _registered_qty(db, ev.id))


@router.patch("/{event_id}", response_model=EventRead)
async def update_event(
    event_id: str, payload: EventUpdate, db: DbSession, scope: StoreAdminDep
):
    ev = await _get_event(db, scope, event_id)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(ev, k, v)
    await db.commit()
    await db.refresh(ev)
    return _to_read(ev, await _registered_qty(db, ev.id))


@router.delete("/{event_id}", status_code=204)
async def delete_event(event_id: str, db: DbSession, scope: StoreAdminDep):
    ev = await _get_event(db, scope, event_id)
    ev.deleted_at = datetime.now(timezone.utc)
    await db.commit()


# --------------------------------------------------------------------------- #
# Registrations
# --------------------------------------------------------------------------- #
@router.get("/{event_id}/registrations", response_model=list[RegistrationRead])
async def list_registrations(event_id: str, db: DbSession, scope: TenantScope):
    await _get_event(db, scope, event_id)
    rows = (
        await db.execute(
            select(EventRegistration)
            .where(EventRegistration.event_id == event_id)
            .order_by(EventRegistration.created_at.desc())
        )
    ).scalars().all()
    return rows


@router.post(
    "/{event_id}/registrations", response_model=RegistrationRead, status_code=201
)
async def register(
    event_id: str, payload: RegistrationCreate, db: DbSession, scope: StoreAdminDep
):
    ev = await _get_event(db, scope, event_id)
    qty = max(1, payload.qty)
    if ev.capacity > 0:
        used = await _registered_qty(db, ev.id)
        if used + qty > ev.capacity:
            raise HTTPException(
                status.HTTP_409_CONFLICT,
                f"capacity exceeded ({used}/{ev.capacity})",
            )
    reg = EventRegistration(
        tenant_id=scope.tenant_id,
        event_id=ev.id,
        member_id=payload.member_id,
        name=payload.name,
        phone=payload.phone,
        qty=qty,
        amount_cents=ev.price_cents * qty,
        ticket_code=_gen_ticket_code(),
        status="registered",
    )
    db.add(reg)
    await db.commit()
    await db.refresh(reg)
    return reg


@router.post(
    "/registrations/check-in", response_model=RegistrationRead
)
async def check_in(
    db: DbSession,
    scope: StoreAdminDep,
    code: str = Query(..., description="ticket code to redeem"),
):
    reg = (
        await db.execute(
            select(EventRegistration).where(
                EventRegistration.tenant_id == scope.tenant_id,
                EventRegistration.ticket_code == code.strip().upper(),
            )
        )
    ).scalar_one_or_none()
    if not reg:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "ticket not found")
    if reg.status == "cancelled":
        raise HTTPException(status.HTTP_409_CONFLICT, "ticket cancelled")
    if reg.status == "checked_in":
        raise HTTPException(status.HTTP_409_CONFLICT, "ticket already checked in")
    reg.status = "checked_in"
    reg.checked_in_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(reg)
    return reg


@router.post(
    "/registrations/{reg_id}/cancel", response_model=RegistrationRead
)
async def cancel_registration(
    reg_id: str, db: DbSession, scope: StoreAdminDep
):
    reg = await db.get(EventRegistration, reg_id)
    if not reg or reg.tenant_id != scope.tenant_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "registration not found")
    reg.status = "cancelled"
    await db.commit()
    await db.refresh(reg)
    return reg
