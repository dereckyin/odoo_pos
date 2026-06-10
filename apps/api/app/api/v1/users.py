from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select

from ...core.audit import audit
from ...core.deps import (
    DbSession,
    StoreAdminDep,
    TenantAdminDep,
    apply_tenant,
    ensure_same_tenant,
)
from ...core.security import hash_password, hash_secret
from ...models import ALL_ROLES, Store, User

router = APIRouter(prefix="/users", tags=["users"])


_assignable_roles = {r for r in ALL_ROLES if r != "platform_super"}


class UserRead(BaseModel):
    id: str
    tenant_id: str | None
    username: str
    display_name: str
    email: str | None
    role: str
    store_id: str | None
    is_active: bool
    must_change_password: bool
    employee_id: str | None = None
    has_pin: bool = False
    totp_enabled: bool = False
    last_login_at: datetime | None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

    @classmethod
    def of(cls, user: User) -> "UserRead":
        return cls.model_validate(user).model_copy(
            update={"has_pin": bool(user.pin_hash)}
        )


class UserCreate(BaseModel):
    username: str
    password: str
    display_name: str
    email: str | None = None
    role: str = "cashier"
    store_id: str | None = None
    is_active: bool = True
    must_change_password: bool = False
    employee_id: str | None = None
    pin: str | None = None


class UserUpdate(BaseModel):
    display_name: str | None = None
    role: str | None = None
    store_id: str | None = None
    is_active: bool | None = None
    password: str | None = None
    email: str | None = None
    must_change_password: bool | None = None
    employee_id: str | None = None
    pin: str | None = None


def _check_role_assignable(role: str) -> None:
    if role not in _assignable_roles:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"role '{role}' cannot be assigned via this endpoint",
        )


def _validate_pin(pin: str) -> None:
    if not (pin.isdigit() and 4 <= len(pin) <= 12):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "PIN 必須為 4-12 位數字"
        )


async def _assert_employee_id_unique(
    db, *, tenant_id: str | None, employee_id: str, exclude_user_id: str | None = None
) -> None:
    stmt = select(User).where(
        User.tenant_id == tenant_id,
        User.employee_id == employee_id,
        User.deleted_at.is_(None),
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing and existing.id != exclude_user_id:
        raise HTTPException(status.HTTP_409_CONFLICT, "員工 ID 已存在")


@router.get("", response_model=list[UserRead])
async def list_users(db: DbSession, scope: TenantAdminDep) -> list[UserRead]:
    stmt = apply_tenant(
        select(User).where(User.deleted_at.is_(None)), User, scope
    ).order_by(User.username)
    rows = (await db.execute(stmt)).scalars().all()
    return [UserRead.of(r) for r in rows]


@router.post("", response_model=UserRead, status_code=201)
async def create_user(
    payload: UserCreate, db: DbSession, scope: TenantAdminDep
) -> UserRead:
    _check_role_assignable(payload.role)
    existing = (
        await db.execute(
            select(User).where(
                User.tenant_id == scope.tenant_id, User.username == payload.username
            )
        )
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "username already exists")
    if payload.store_id:
        store = await db.get(Store, payload.store_id)
        if not store or store.tenant_id != scope.tenant_id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "store not in tenant")
    if payload.employee_id:
        await _assert_employee_id_unique(
            db, tenant_id=scope.tenant_id, employee_id=payload.employee_id
        )
    pin_hash = None
    if payload.pin:
        _validate_pin(payload.pin)
        pin_hash = hash_secret(payload.pin)
    user = User(
        tenant_id=scope.tenant_id,
        username=payload.username,
        password_hash=hash_password(payload.password),
        display_name=payload.display_name,
        email=payload.email,
        role=payload.role,
        store_id=payload.store_id,
        is_active=payload.is_active,
        must_change_password=payload.must_change_password,
        employee_id=payload.employee_id or None,
        pin_hash=pin_hash,
    )
    db.add(user)
    await audit(db, scope, action="user_create", resource_type="user",
                extra={"role": payload.role}, flush=False)
    await db.commit()
    await db.refresh(user)
    return UserRead.of(user)


@router.patch("/{user_id}", response_model=UserRead)
async def update_user(
    user_id: str, payload: UserUpdate, db: DbSession, scope: TenantAdminDep
) -> UserRead:
    user = await db.get(User, user_id)
    if not user or user.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, user)
    data = payload.model_dump(exclude_unset=True)
    if "role" in data:
        _check_role_assignable(data["role"])
    pwd = data.pop("password", None)
    pin = data.pop("pin", None)
    if "employee_id" in data:
        emp = (data["employee_id"] or None)
        data["employee_id"] = emp
        if emp:
            await _assert_employee_id_unique(
                db, tenant_id=user.tenant_id, employee_id=emp, exclude_user_id=user.id
            )
    for k, v in data.items():
        setattr(user, k, v)
    if pwd:
        user.password_hash = hash_password(pwd)
    if pin is not None:
        if pin == "":
            user.pin_hash = None
        else:
            _validate_pin(pin)
            user.pin_hash = hash_secret(pin)
    await audit(db, scope, action="user_update", resource_type="user",
                resource_id=user_id, flush=False)
    await db.commit()
    await db.refresh(user)
    return UserRead.of(user)


@router.delete("/{user_id}", status_code=204)
async def delete_user(
    user_id: str, db: DbSession, scope: TenantAdminDep
) -> None:
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    ensure_same_tenant(scope, user)
    user.deleted_at = datetime.now(timezone.utc)
    user.is_active = False
    await audit(db, scope, action="user_delete", resource_type="user",
                resource_id=user_id, flush=False)
    await db.commit()


@router.get("/me", response_model=UserRead)
async def me(db: DbSession, scope: StoreAdminDep) -> UserRead:
    """Convenience endpoint so the SPA can fetch the current user's full
    profile (incl. tenant assignment) when it just has a JWT."""
    user = await db.get(User, scope.user_id)
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    return UserRead.of(user)
