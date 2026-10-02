"""Signature-based intrusion detection middleware (same model as my_api).

Each request's path, query, a few headers and (for JSON / form / text bodies)
the body values are matched against ``ids_rules.RULES``. Matched severities
are summed: at or above ``IDS_BLOCK_THRESHOLD`` the request gets a 403 and
counts as a strike; ``IDS_SUSPICIOUS_HIT_LIMIT`` strikes within the window
ban the IP for ``IDS_IP_BLOCK_SECONDS``. Every match is written to a JSONL
incident log. Secrets (passwords, tokens, OTPs) are never scanned or logged.

Implemented as plain ASGI so the request body can be buffered and replayed
without Starlette's BaseHTTPMiddleware quirks.
"""
from __future__ import annotations

import json
import logging
import os
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any
from urllib.parse import parse_qsl, unquote

from .client_ip import resolve_client_ip
from .config import get_settings
from .ids_rules import RULES, Rule

logger = logging.getLogger("app.ids")

_SCANNABLE_TYPES = ("application/json", "application/x-www-form-urlencoded", "text/")
_SENSITIVE_KEYS = {
    "password", "new_password", "old_password", "current_password", "pin", "otp", "code",
    "token", "access_token", "refresh_token", "secret", "api_key", "hash_key", "hash_iv",
    "authorization", "captcha", "captcha_token", "presence_token",
}
_MAX_SCAN_CHARS = 8192
_MAX_BUFFER_BYTES = 2 * 1024 * 1024


@dataclass
class Match:
    rule_id: str
    category: str
    severity: int
    target: str
    excerpt: str


@dataclass
class Detection:
    risk_score: int = 0
    matches: list[Match] = field(default_factory=list)


def _flatten(value: Any, out: list[str], depth: int = 0) -> None:
    if depth > 8 or len(out) > 500:
        return
    if isinstance(value, dict):
        for k, v in value.items():
            key = str(k)
            out.append(key)
            if key.lower() in _SENSITIVE_KEYS:
                continue
            _flatten(v, out, depth + 1)
    elif isinstance(value, list):
        for v in value:
            _flatten(v, out, depth + 1)
    elif isinstance(value, str):
        out.append(value)


def _body_text(content_type: str, body: bytes, limit: int) -> str:
    raw = body[:limit].decode("utf-8", errors="ignore")
    parts: list[str] = []
    if "application/json" in content_type:
        try:
            _flatten(json.loads(body.decode("utf-8")), parts)
            return "\n".join(parts)[:_MAX_SCAN_CHARS]
        except (ValueError, UnicodeDecodeError):
            return raw[:_MAX_SCAN_CHARS]
    if "application/x-www-form-urlencoded" in content_type:
        for k, v in parse_qsl(raw, keep_blank_values=True):
            parts.append(k)
            if k.lower() not in _SENSITIVE_KEYS:
                parts.append(v)
        return "\n".join(parts)[:_MAX_SCAN_CHARS]
    return raw[:_MAX_SCAN_CHARS]


def detect(fields: dict[str, str], rules: list[Rule] = RULES) -> Detection:
    fields = {**fields, "any": "\n".join(fields.values())}
    result = Detection()
    for rule in rules:
        text = fields.get(rule.target, fields["any"])
        m = rule.pattern.search(text)
        if not m:
            continue
        start, end = max(m.start() - 30, 0), min(m.end() + 30, len(text))
        result.risk_score += rule.severity
        result.matches.append(Match(rule.rule_id, rule.category, rule.severity, rule.target, text[start:end]))
    return result


class _StrikeStore:
    """IP strike counters and bans; Redis when available (shared by workers),
    otherwise per-process memory."""

    def __init__(self) -> None:
        self._mem: dict[str, tuple[int, float]] = {}
        self._redis = None
        self._redis_failed = False

    def _client(self):
        if self._redis is not None or self._redis_failed:
            return self._redis
        s = get_settings()
        uri = s.rate_limit_storage_uri if s.RATE_LIMIT_ENABLED else ""
        if not uri.startswith(("redis://", "rediss://")):
            self._redis_failed = True
            return None
        try:
            import redis.asyncio as aioredis

            self._redis = aioredis.from_url(uri, socket_timeout=0.5, socket_connect_timeout=0.5)
        except Exception:  # noqa: BLE001
            self._redis_failed = True
        return self._redis

    def _mem_get(self, key: str) -> int:
        val = self._mem.get(key)
        if not val:
            return 0
        if val[1] < time.time():
            self._mem.pop(key, None)
            return 0
        return val[0]

    async def is_banned(self, ip: str) -> bool:
        r = self._client()
        if r is not None:
            try:
                return bool(await r.exists(f"ids:ban:{ip}"))
            except Exception:  # noqa: BLE001
                self._redis, self._redis_failed = None, True
        return self._mem_get(f"ban:{ip}") > 0

    async def strike(self, ip: str) -> bool:
        """Record a blocked request; return True when the IP just got banned."""
        s = get_settings()
        r = self._client()
        if r is not None:
            try:
                key = f"ids:strike:{ip}"
                hits = await r.incr(key)
                if hits == 1:
                    await r.expire(key, s.IDS_SUSPICIOUS_WINDOW_SECONDS)
                if hits >= s.IDS_SUSPICIOUS_HIT_LIMIT:
                    await r.set(f"ids:ban:{ip}", 1, ex=s.IDS_IP_BLOCK_SECONDS)
                    return True
                return False
            except Exception:  # noqa: BLE001
                self._redis, self._redis_failed = None, True
        hits = self._mem_get(f"strike:{ip}") + 1
        expires = self._mem.get(f"strike:{ip}", (0, time.time() + s.IDS_SUSPICIOUS_WINDOW_SECONDS))[1]
        self._mem[f"strike:{ip}"] = (hits, expires)
        if hits >= s.IDS_SUSPICIOUS_HIT_LIMIT:
            self._mem[f"ban:{ip}"] = (1, time.time() + s.IDS_IP_BLOCK_SECONDS)
            return True
        return False

    def reset(self) -> None:
        self._mem.clear()


strike_store = _StrikeStore()


def _write_incident(record: dict) -> None:
    logger.warning("ids %s", json.dumps(record, ensure_ascii=False))
    path = get_settings().IDS_INCIDENT_LOG_PATH
    if not path:
        return
    try:
        directory = os.path.dirname(path)
        if directory:
            os.makedirs(directory, exist_ok=True)
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(json.dumps(record, ensure_ascii=False) + "\n")
    except OSError:
        logger.exception("ids incident log write failed")


def _path_whitelisted(path: str, patterns: list[str]) -> bool:
    for p in patterns:
        if p.endswith("*") and path.startswith(p[:-1]):
            return True
        if path == p:
            return True
    return False


async def _deny(send, incident_id: str) -> None:
    body = json.dumps({"detail": "request blocked", "incident_id": incident_id}).encode()
    await send({
        "type": "http.response.start",
        "status": 403,
        "headers": [(b"content-type", b"application/json"), (b"content-length", str(len(body)).encode())],
    })
    await send({"type": "http.response.body", "body": body})


class IDSMiddleware:
    def __init__(self, app) -> None:
        self.app = app

    async def __call__(self, scope, receive, send):
        s = get_settings()
        if scope["type"] != "http" or not s.IDS_ENABLED:
            return await self.app(scope, receive, send)

        path: str = scope.get("path", "")
        method = scope.get("method", "")
        headers = {k.decode("latin-1").lower(): v.decode("latin-1") for k, v in scope.get("headers", [])}
        client = scope.get("client") or ("", 0)
        ip = resolve_client_ip(client[0] or "", headers)
        if _path_whitelisted(path, s.ids_whitelist_paths) or ip in s.ids_whitelist_ips:
            return await self.app(scope, receive, send)

        if await strike_store.is_banned(ip):
            incident_id = uuid.uuid4().hex
            _write_incident({
                "incident_id": incident_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "ip": ip, "method": method, "path": path, "action": "ip_banned", "risk_score": 0, "matches": [],
            })
            return await _deny(send, incident_id)

        content_type = headers.get("content-type", "").lower()
        body = b""
        buffered = False
        try:
            declared = int(headers.get("content-length") or 0)
        except ValueError:
            declared = 0
        if any(t in content_type for t in _SCANNABLE_TYPES) and declared <= _MAX_BUFFER_BYTES:
            chunks: list[bytes] = []
            more = True
            while more:
                message = await receive()
                if message["type"] != "http.request":
                    break
                chunks.append(message.get("body", b""))
                more = message.get("more_body", False)
            body = b"".join(chunks)
            buffered = True

        raw_path = scope.get("raw_path") or path.encode()
        query_items = parse_qsl(scope.get("query_string", b"").decode("latin-1"), keep_blank_values=True)
        query_text = "\n".join(
            part for k, v in query_items for part in ((k, v) if k.lower() not in _SENSITIVE_KEYS else (k,))
        )
        fields = {
            "path": path + "\n" + unquote(raw_path.decode("latin-1")),
            "query": query_text[:_MAX_SCAN_CHARS],
            "headers": "\n".join(headers.get(h, "") for h in ("user-agent", "referer", "x-forwarded-host")),
            "body": _body_text(content_type, body, s.IDS_MAX_BODY_SCAN_BYTES) if body else "",
        }
        detection = detect(fields)

        blocked = detection.risk_score >= s.IDS_BLOCK_THRESHOLD
        if detection.matches:
            incident_id = uuid.uuid4().hex
            banned = await strike_store.strike(ip) if blocked else False
            action = ("blocked" if not s.IDS_LOG_ONLY else "observe_only") if blocked else "allowed"
            _write_incident({
                "incident_id": incident_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "ip": ip,
                "method": method,
                "path": path,
                "user_agent": headers.get("user-agent", "")[:256],
                "action": action,
                "ip_banned": banned,
                "risk_score": detection.risk_score,
                "matches": [m.__dict__ for m in detection.matches],
            })
            if blocked and not s.IDS_LOG_ONLY:
                return await _deny(send, incident_id)

        if not buffered:
            return await self.app(scope, receive, send)

        replayed = False

        async def replay():
            nonlocal replayed
            if not replayed:
                replayed = True
                return {"type": "http.request", "body": body, "more_body": False}
            return await receive()

        return await self.app(scope, replay, send)


class SecurityHeadersMiddleware:
    """Baseline response headers (same set my_api sends). Uploaded files get
    a locked-down CSP so nothing served from /uploads can run script."""

    def __init__(self, app) -> None:
        self.app = app

    async def __call__(self, scope, receive, send):
        s = get_settings()
        if scope["type"] != "http" or not s.SECURITY_HEADERS:
            return await self.app(scope, receive, send)
        is_upload = scope.get("path", "").startswith("/uploads/")

        async def send_with_headers(message):
            if message["type"] == "http.response.start":
                existing = {k.lower() for k, _ in message.get("headers", [])}
                extra = [
                    (b"x-content-type-options", b"nosniff"),
                    (b"x-frame-options", b"DENY"),
                    (b"referrer-policy", b"strict-origin-when-cross-origin"),
                ]
                if s.is_production:
                    extra.append((b"strict-transport-security", b"max-age=63072000; includeSubDomains"))
                if is_upload:
                    extra.append((b"content-security-policy", b"default-src 'none'; img-src 'self'; sandbox"))
                message = {
                    **message,
                    "headers": list(message.get("headers", [])) + [(k, v) for k, v in extra if k not in existing],
                }
            await send(message)

        return await self.app(scope, receive, send_with_headers)
