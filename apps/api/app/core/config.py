from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict

# Sentinel values that must NEVER be used in production. The startup check in
# ``main.py`` rejects these when ``ENV != dev``.
_INSECURE_SECRETS = {"", "change-me", "change-me-in-production", "test-secret"}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    ENV: str = "dev"
    DATABASE_URL: str = "postgresql+asyncpg://pos:pos@localhost:5432/pos"
    REDIS_URL: str = "redis://localhost:6379/0"

    JWT_SECRET: str = "change-me"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TTL_MIN: int = 480
    JWT_REFRESH_TTL_DAYS: int = 90

    # Symmetric encryption key for per-tenant secrets (Fernet-compatible URL-safe
    # base64-encoded 32-byte key). Generate with:
    #   python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
    SECRETS_ENCRYPTION_KEY: str = ""

    CORS_ORIGINS: str = "http://localhost:5173,http://localhost:3000"

    # Rate limiting
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_STORAGE_URI: str = ""  # falls back to REDIS_URL when empty

    # CAPTCHA (hCaptcha / Cloudflare Turnstile). Empty key => skipped (dev mode).
    CAPTCHA_PROVIDER: str = ""  # "" | "hcaptcha" | "turnstile"
    CAPTCHA_SECRET: str = ""

    # Email / OTP. Delivery priority in `core/notify.py`:
    # SES (SES_ACCESS_KEY/SES_SECRET_KEY/SENDER) -> Resend -> SMTP -> stub log.
    SES_ACCESS_KEY: str = ""
    SES_SECRET_KEY: str = ""
    SES_REGION: str = ""
    SENDER: str = ""
    RESEND_API_KEY: str = ""
    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM: str = "no-reply@pos.local"
    EMAIL_OTP_TTL_MIN: int = 15

    # Platform-level invoice/payment fallbacks. Per-tenant credentials live in
    # ``tenant_payment_settings`` / ``tenant_invoice_settings`` and override
    # these. Kept here only for development / single-tenant fallback.
    LINEPAY_CHANNEL_ID: str = ""
    LINEPAY_CHANNEL_SECRET: str = ""
    LINEPAY_BASE_URL: str = "https://sandbox-api-pay.line.me"
    LINEPAY_CONFIRM_URL: str = "http://localhost:8000/payments/linepay/confirm"
    LINEPAY_CANCEL_URL: str = "http://localhost:8000/payments/linepay/cancel"

    NEWEBPAY_MERCHANT_ID: str = ""
    NEWEBPAY_HASH_KEY: str = ""
    NEWEBPAY_HASH_IV: str = ""
    NEWEBPAY_BASE_URL: str = "https://ccore.newebpay.com"

    ECPAY_MERCHANT_ID: str = ""
    ECPAY_HASH_KEY: str = ""
    ECPAY_HASH_IV: str = ""
    ECPAY_BASE_URL: str = "https://payment-stage.ecpay.com.tw"

    EZPAY_MERCHANT_ID: str = ""
    EZPAY_HASH_KEY: str = ""
    EZPAY_HASH_IV: str = ""
    EZPAY_BASE_URL: str = "https://cinv.ezpay.com.tw"

    ECPAY_INVOICE_MERCHANT_ID: str = ""
    ECPAY_INVOICE_HASH_KEY: str = ""
    ECPAY_INVOICE_HASH_IV: str = ""
    ECPAY_INVOICE_BASE_URL: str = "https://einvoice-stage.ecpay.com.tw"

    @property
    def cors_origin_list(self) -> List[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.ENV.lower() in ("prod", "production", "live")

    @property
    def rate_limit_storage_uri(self) -> str:
        # Use slowapi's sync redis backend (limits + redis-py); the async
        # backend would pull in `coredis` for no real benefit on a tiny
        # counter increment.
        return self.RATE_LIMIT_STORAGE_URI or self.REDIS_URL


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()


def validate_settings_or_raise(settings: Settings) -> None:
    """Fail-fast on insecure / missing config when running outside dev.

    Called from ``create_app`` so the process refuses to start with the demo
    JWT secret in production. Dev mode keeps the previous lenient behaviour.
    """
    if settings.is_production:
        if settings.JWT_SECRET in _INSECURE_SECRETS:
            raise RuntimeError(
                "JWT_SECRET is set to a known-insecure default. Set a strong "
                "random JWT_SECRET (>= 32 bytes) before starting in production."
            )
        if not settings.SECRETS_ENCRYPTION_KEY:
            raise RuntimeError(
                "SECRETS_ENCRYPTION_KEY is required in production to encrypt "
                "per-tenant payment / invoice credentials."
            )
