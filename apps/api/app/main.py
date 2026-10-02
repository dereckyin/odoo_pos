import logging
import os
from pathlib import Path

from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi.errors import RateLimitExceeded

from .api.v1 import api_router
from .core.config import get_settings, validate_settings_or_raise
from .core.ids import IDSMiddleware, SecurityHeadersMiddleware
from .core.ratelimit import limiter, rate_limit_handler


def create_app() -> FastAPI:
    settings = get_settings()
    validate_settings_or_raise(settings)

    logging.basicConfig(level=logging.INFO)

    docs = settings.docs_enabled
    app = FastAPI(
        title="點餐趣 API",
        version="0.2.0",
        description="點餐趣／多租戶 POS SaaS 後端（FastAPI + PostgreSQL）。",
        docs_url="/docs" if docs else None,
        redoc_url="/redoc" if docs else None,
        openapi_url="/openapi.json" if docs else None,
    )

    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, rate_limit_handler)

    # Starlette runs the last-added middleware first: CORS -> headers -> IDS -> app.
    app.add_middleware(IDSMiddleware)
    app.add_middleware(SecurityHeadersMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router)

    # Cursor's embedded Simple Browser (and similar dev UIs) probe ``HEAD /queue``
    # on localhost; without this route uvicorn logs a 404 on every keystroke/focus.
    # Registered only outside strict production.
    if not settings.is_production:

        @app.head("/queue")
        async def _dev_queue_probe() -> Response:
            return Response(status_code=204)

    upload_dir = Path(os.getenv("UPLOAD_DIR", "uploads"))
    upload_dir.mkdir(parents=True, exist_ok=True)
    app.mount("/uploads", StaticFiles(directory=str(upload_dir)), name="uploads")

    @app.get("/")
    async def root() -> dict:
        return {"app": "點餐趣", "env": settings.ENV}

    @app.get("/health")
    async def health() -> dict:
        return {"ok": True}

    @app.get("/readyz")
    async def readyz() -> dict:
        from sqlalchemy import text

        from .core.db import get_session_factory

        ok = True
        details: dict[str, str] = {}
        try:
            factory = get_session_factory()
            async with factory() as db:
                await db.execute(text("SELECT 1"))
            details["db"] = "ok"
        except Exception:  # noqa: BLE001
            ok = False
            logging.getLogger("app.readyz").exception("readiness check failed")
            details["db"] = "error"
        return {"ok": ok, **details}

    return app


app = create_app()
