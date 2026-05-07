from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select

from ...core.deps import AdminDep, DbSession
from ...core.security import hash_password
from ...models import User

router = APIRouter(prefix="/users", tags=["users"])


class UserRead(BaseModel):
    id: str
    username: str
    display_name: str
    role: str
    store_id: str | None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    username: str
    password: str
    display_name: str
    role: str = "cashier"
    store_id: str | None = None
    is_active: bool = True


class UserUpdate(BaseModel):
    display_name: str | None = None
    role: str | None = None
    store_id: str | None = None
    is_active: bool | None = None
    password: str | None = None


@router.get("", response_model=list[UserRead])
async def list_users(db: DbSession, _: AdminDep) -> list[UserRead]:
    stmt = select(User).where(User.deleted_at.is_(None)).order_by(User.username)
    rows = (await db.execute(stmt)).scalars().all()
    return [UserRead.model_validate(r) for r in rows]


@router.post("", response_model=UserRead, status_code=201)
async def create_user(payload: UserCreate, db: DbSession, _: AdminDep) -> UserRead:
    existing = (await db.execute(select(User).where(User.username == payload.username))).scalar_one_or_none()
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "username already exists")
    user = User(
        username=payload.username,
        password_hash=hash_password(payload.password),
        display_name=payload.display_name,
        role=payload.role,
        store_id=payload.store_id,
        is_active=payload.is_active,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return UserRead.model_validate(user)


@router.patch("/{user_id}", response_model=UserRead)
async def update_user(user_id: str, payload: UserUpdate, db: DbSession, _: AdminDep) -> UserRead:
    user = await db.get(User, user_id)
    if not user or user.deleted_at:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    data = payload.model_dump(exclude_unset=True)
    pwd = data.pop("password", None)
    for k, v in data.items():
        setattr(user, k, v)
    if pwd:
        user.password_hash = hash_password(pwd)
    await db.commit()
    await db.refresh(user)
    return UserRead.model_validate(user)


@router.delete("/{user_id}", status_code=204)
async def delete_user(user_id: str, db: DbSession, _: AdminDep) -> None:
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND)
    user.deleted_at = datetime.now(timezone.utc)
    await db.commit()
