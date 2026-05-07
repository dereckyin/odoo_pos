from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    ENV: str = "dev"
    DATABASE_URL: str = "postgresql+asyncpg://pos:pos@localhost:5432/pos"
    REDIS_URL: str = "redis://localhost:6379/0"

    JWT_SECRET: str = "change-me"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TTL_MIN: int = 30
    JWT_REFRESH_TTL_DAYS: int = 30

    CORS_ORIGINS: str = "http://localhost:5173,http://localhost:3000"

    # LINE Pay
    LINEPAY_CHANNEL_ID: str = ""
    LINEPAY_CHANNEL_SECRET: str = ""
    LINEPAY_BASE_URL: str = "https://sandbox-api-pay.line.me"
    LINEPAY_CONFIRM_URL: str = "http://localhost:8000/payments/linepay/confirm"
    LINEPAY_CANCEL_URL: str = "http://localhost:8000/payments/linepay/cancel"

    # NewebPay
    NEWEBPAY_MERCHANT_ID: str = ""
    NEWEBPAY_HASH_KEY: str = ""
    NEWEBPAY_HASH_IV: str = ""
    NEWEBPAY_BASE_URL: str = "https://ccore.newebpay.com"

    # ECPay (payment)
    ECPAY_MERCHANT_ID: str = "2000132"
    ECPAY_HASH_KEY: str = "5294y06JbISpM5x9"
    ECPAY_HASH_IV: str = "v77hoKGq4kWxNNIS"
    ECPAY_BASE_URL: str = "https://payment-stage.ecpay.com.tw"

    # Ezpay invoice
    EZPAY_MERCHANT_ID: str = ""
    EZPAY_HASH_KEY: str = ""
    EZPAY_HASH_IV: str = ""
    EZPAY_BASE_URL: str = "https://cinv.ezpay.com.tw"

    # ECPay invoice
    ECPAY_INVOICE_MERCHANT_ID: str = ""
    ECPAY_INVOICE_HASH_KEY: str = ""
    ECPAY_INVOICE_HASH_IV: str = ""
    ECPAY_INVOICE_BASE_URL: str = "https://einvoice-stage.ecpay.com.tw"

    @property
    def cors_origin_list(self) -> List[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
