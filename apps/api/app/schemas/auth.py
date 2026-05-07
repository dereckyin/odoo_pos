from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username: str
    password: str
    terminal_code: str = Field(min_length=1)


class AdminLoginRequest(BaseModel):
    username: str
    password: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class SessionRead(BaseModel):
    user_id: str
    username: str
    display_name: str
    role: str
    store_id: str
    terminal_id: str
    access_token: str
    refresh_token: str
    expires_at: float


class TerminalRegisterRequest(BaseModel):
    store_code: str
    terminal_code: str


class TerminalRegisterResponse(BaseModel):
    terminal_id: str
    store_id: str
    api_key: str  # one-shot, not stored in plain text


class HeartbeatRequest(BaseModel):
    terminal_id: str


class RefreshRequest(BaseModel):
    refresh_token: str
