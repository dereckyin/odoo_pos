from typing import Annotated

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from .db import get_db
from .security import decode_token


class CurrentUser:
    def __init__(self, *, user_id: str, username: str, role: str, store_id: str, terminal_id: str | None):
        self.user_id = user_id
        self.username = username
        self.role = role
        self.store_id = store_id
        self.terminal_id = terminal_id

    @property
    def is_admin(self) -> bool:
        return self.role == "admin"


async def current_user(
    authorization: Annotated[str | None, Header()] = None,
) -> CurrentUser:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "missing bearer token")
    token = authorization.split(" ", 1)[1]
    try:
        claims = decode_token(token)
    except ValueError as e:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, str(e))
    if claims.get("type") == "refresh":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "refresh token cannot access resources")
    return CurrentUser(
        user_id=claims["sub"],
        username=claims.get("username", ""),
        role=claims.get("role", "cashier"),
        store_id=claims.get("store_id", ""),
        terminal_id=claims.get("terminal_id"),
    )


async def require_admin(user: Annotated[CurrentUser, Depends(current_user)]) -> CurrentUser:
    if not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "admin only")
    return user


DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUserDep = Annotated[CurrentUser, Depends(current_user)]
AdminDep = Annotated[CurrentUser, Depends(require_admin)]
