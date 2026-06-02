from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    """POS-station login. Requires the workstation's terminal API key
    issued by ``POST /auth/terminals/register`` so a stolen username/password
    cannot operate from an unregistered device."""

    tenant_code: str = Field(min_length=1, max_length=32)
    store_code: str = Field(min_length=1, max_length=32)
    terminal_code: str = Field(min_length=1, max_length=64)
    terminal_api_key: str = Field(min_length=8)
    username: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1)


class AdminLoginRequest(BaseModel):
    """Browser/admin login. The user account itself decides which tenant
    is in scope; no terminal binding is required."""

    tenant_code: str | None = Field(default=None, max_length=32)
    username: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1)


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
    tenant_id: str | None
    tenant_code: str | None
    store_id: str | None
    terminal_id: str | None
    access_token: str
    refresh_token: str
    expires_at: float
    must_change_password: bool = False


class TerminalRegisterRequest(BaseModel):
    store_code: str = Field(min_length=1, max_length=32)
    terminal_code: str = Field(min_length=1, max_length=64)


class TerminalRegisterResponse(BaseModel):
    terminal_id: str
    store_id: str
    api_key: str  # one-shot, not stored in plaintext


class HeartbeatRequest(BaseModel):
    terminal_id: str


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str | None = None


class ChangePasswordRequest(BaseModel):
    old_password: str = Field(min_length=1)
    new_password: str = Field(min_length=8, max_length=128)


# ----- Public store-signup application -------------------------------------

class TenantApplyRequest(BaseModel):
    company_name: str = Field(min_length=2, max_length=128)
    contact_name: str = Field(min_length=1, max_length=64)
    contact_email: EmailStr
    contact_phone: str | None = Field(default=None, max_length=32)
    tax_id: str | None = Field(default=None, max_length=16)
    plan_code: str | None = Field(default=None, max_length=32)
    proposed_subdomain: str | None = Field(
        default=None, min_length=3, max_length=32, pattern=r"^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$"
    )
    address: str | None = Field(default=None, max_length=256)
    note: str | None = Field(default=None, max_length=1024)
    captcha_token: str | None = None


class TenantApplyResponse(BaseModel):
    application_id: str
    contact_email: EmailStr
    status: str
    message: str = "申請已收到，請至信箱輸入驗證碼完成登錄。"


class TenantApplyVerifyRequest(BaseModel):
    application_id: str
    code: str = Field(min_length=4, max_length=8)


class TenantApplyResumeRequest(BaseModel):
    contact_email: EmailStr


class TenantApplyResumeResponse(BaseModel):
    application_id: str
    contact_email: EmailStr
    status: str
    company_name: str
    message: str


class TenantApplicationRead(BaseModel):
    id: str
    company_name: str
    contact_name: str
    contact_email: EmailStr
    contact_phone: str | None
    tax_id: str | None
    plan_code: str | None
    proposed_subdomain: str | None
    address: str | None
    note: str | None
    status: str
    email_verified_at: float | None = None
    reviewed_at: float | None = None
    reject_reason: str | None
    provisioned_tenant_id: str | None

    class Config:
        from_attributes = True


class TenantApplicationApprove(BaseModel):
    plan_code: str = Field(min_length=1, max_length=32)
    tenant_code: str | None = Field(default=None, min_length=2, max_length=32)
    owner_username: str = Field(default="owner", min_length=3, max_length=64)


class TenantDirectCreateRequest(BaseModel):
    company_name: str = Field(min_length=2, max_length=128)
    contact_name: str = Field(min_length=1, max_length=64)
    contact_email: EmailStr
    contact_phone: str | None = Field(default=None, max_length=32)
    tax_id: str | None = Field(default=None, max_length=16)
    plan_code: str = Field(min_length=1, max_length=32)
    tenant_code: str = Field(min_length=2, max_length=32, pattern=r"^[a-z0-9][a-z0-9-]{0,30}[a-z0-9]$")
    owner_username: str = Field(default="admin", min_length=3, max_length=64)
    address: str | None = Field(default=None, max_length=256)
    seed_default_products: bool = False
    seed_default_promotions: bool = False


class TenantDirectCreateResponse(BaseModel):
    tenant_id: str
    tenant_code: str
    owner_username: str
    one_time_password: str


class TenantApplicationReject(BaseModel):
    reason: str = Field(min_length=1, max_length=512)
