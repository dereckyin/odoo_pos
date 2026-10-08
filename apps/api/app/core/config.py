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

    # SMS (Twilio-compatible). Empty creds => stub log + dev_code echo fallback.
    SMS_PROVIDER: str = ""  # "" | "twilio"
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_FROM_NUMBER: str = ""

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

    # Physical bookstore partner API (TAAZE app via my_api). Only SHA-256 hex
    # digests of the partner keys are configured; comma-separate several to
    # rotate with an overlap window.
    BOOKSTORE_PARTNER_TENANT_CODE: str = ""
    BOOKSTORE_PARTNER_KEY_SHA256: str = ""
    BOOKSTORE_PARTNER_ALLOWED_IPS: str = ""
    BOOKSTORE_SIGNING_SECRET: str = ""
    BOOKSTORE_PUBLIC_BASE_URL: str = ""
    BOOKSTORE_RETURN_URL_PREFIXES: str = ""
    BOOKSTORE_RESERVATION_MINUTES: int = 5
    BOOKSTORE_EXIT_PASS_MINUTES: int = 30
    BOOKSTORE_CASH_RESERVATION_MINUTES: int = 15
    BOOKSTORE_PRESENCE_HOURS: int = 4
    BOOKSTORE_DOOR_QR_DAYS: int = 180
    BOOKSTORE_MAX_PENDING_PER_CUSTOMER: int = 2
    BOOKSTORE_MAX_LINES: int = 20
    BOOKSTORE_MAX_QTY_PER_LINE: int = 5
    BOOKSTORE_ECPAY_CHOOSE_PAYMENT: str = "Credit"
    # After cash/online pay, POST checkout_id to my_api so 讀冊 can write ORDER_MAS.
    # Empty URL disables the callback (App JWT settle is the backup).
    TAAZE_SETTLE_URL: str = ""
    TAAZE_SETTLE_SECRET: str = ""
    # 連正式 Oracle 時務必保持 false：不套用會員折抵、不開發票。
    # 連上 192.168.100.169 測試庫並打開 my_api 同名旗標後再設 true。
    BOOKSTORE_MEMBER_SYNC_ENABLED: bool = False
    # 本站雲端發票：不要再用 POS 的 ezPay/ECPay 開第二張。
    BOOKSTORE_SKIP_POS_INVOICE: bool = True

    # Intrusion detection (same rule model as my_api). A request is blocked when
    # the summed severity of matched rules reaches the threshold; an IP that
    # does so IDS_SUSPICIOUS_HIT_LIMIT times within the window is banned.
    IDS_ENABLED: bool = True
    IDS_LOG_ONLY: bool = False
    IDS_BLOCK_THRESHOLD: int = 70
    IDS_MAX_BODY_SCAN_BYTES: int = 8192
    IDS_SUSPICIOUS_WINDOW_SECONDS: int = 600
    IDS_SUSPICIOUS_HIT_LIMIT: int = 3
    IDS_IP_BLOCK_SECONDS: int = 1800
    IDS_INCIDENT_LOG_PATH: str = "logs/ids_incidents.jsonl"
    # Signed gateway / LINE callbacks carry free text and must never be dropped.
    IDS_WHITELIST_PATHS: str = (
        "/health,/readyz,/line/webhook/*,/public/marketplace/payments/webhook/*,"
        "/public/bookstore/payments/*"
    )
    IDS_WHITELIST_IPS: str = ""

    SECURITY_HEADERS: bool = True
    # None => docs on in dev, off in production.
    ENABLE_DOCS: bool | None = None

    @property
    def ids_whitelist_paths(self) -> list[str]:
        return [p.strip() for p in self.IDS_WHITELIST_PATHS.split(",") if p.strip()]

    @property
    def ids_whitelist_ips(self) -> list[str]:
        return [p.strip() for p in self.IDS_WHITELIST_IPS.split(",") if p.strip()]

    @property
    def docs_enabled(self) -> bool:
        return (not self.is_production) if self.ENABLE_DOCS is None else self.ENABLE_DOCS

    @property
    def bookstore_partner_key_hashes(self) -> list[str]:
        return [h.strip().lower() for h in self.BOOKSTORE_PARTNER_KEY_SHA256.split(",") if h.strip()]

    @property
    def bookstore_allowed_ips(self) -> list[str]:
        return [i.strip() for i in self.BOOKSTORE_PARTNER_ALLOWED_IPS.split(",") if i.strip()]

    @property
    def bookstore_return_url_prefixes(self) -> list[str]:
        return [p.strip() for p in self.BOOKSTORE_RETURN_URL_PREFIXES.split(",") if p.strip()]

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
        if "*" in settings.cors_origin_list:
            raise RuntimeError(
                "CORS_ORIGINS must list explicit origins in production "
                "(credentials are allowed, so '*' is unsafe)."
            )
        if settings.bookstore_partner_key_hashes:
            if len(settings.BOOKSTORE_SIGNING_SECRET) < 32:
                raise RuntimeError(
                    "BOOKSTORE_SIGNING_SECRET (>= 32 chars) is required when the "
                    "bookstore partner API is enabled."
                )
            if not settings.bookstore_allowed_ips:
                raise RuntimeError(
                    "BOOKSTORE_PARTNER_ALLOWED_IPS is required when the bookstore "
                    "partner API is enabled in production."
                )
            if not settings.bookstore_return_url_prefixes:
                raise RuntimeError(
                    "BOOKSTORE_RETURN_URL_PREFIXES is required when the bookstore "
                    "partner API is enabled in production."
                )
