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
from ...core.security import hash_password
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
    last_login_at: datetime | None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    username: str
    password: str
    display_name: str
    email: str | None = None
    role: str = "cashier"
    store_id: str | None = None
    is_active: bool = True
    must_change_password: bool = False


class UserUpdate(BaseModel):
    display_name: str | None = None
    role: str | None = None
    store_id: str | None = None
    is_active: bool | None = None
    password: str | None = None
    email: str | None = None
    must_change_password: bool | None = None


def _check_role_assignable(role: str) -> None:
    if role not in _assignable_roles:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"role '{role}' cannot be assigned via this endpoint",
        )


@router.get("", response_model=list[UserRead])
async def list_users(db: DbSession, scope: TenantAdminDep) -> list[UserRead]:
    stmt = apply_tenant(
        select(User).where(User.deleted_at.is_(None)), User, scope
    ).order_by(User.username)
    rows = (await db.execute(stmt)).scalars().all()
    return [UserRead.model_validate(r) for r in rows]


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
    )
    db.add(user)
    await audit(db, scope, action="user_create", resource_type="user",
                extra={"role": payload.role}, flush=False)
    await db.commit()
    await db.refresh(user)
    return UserRead.model_validate(user)


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
    for k, v in data.items():
        setattr(user, k, v)
    if pwd:
        user.password_hash = hash_password(pwd)
    await audit(db, scope, action="user_update", resource_type="user",
                resource_id=user_id, flush=False)
    await db.commit()
    await db.refresh(user)
    return UserRead.model_validate(user)


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
    return UserRead.model_validate(user)
