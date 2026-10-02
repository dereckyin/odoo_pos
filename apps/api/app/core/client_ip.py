"""Resolve the real client IP behind Caddy -> nginx -> api.

The API container is only reachable through the nginx container, so the
socket peer is always a private address. Forwarded headers are honoured only
when the peer is private/loopback; walking X-Forwarded-For from the right and
skipping private hops yields the address Caddy saw, which a client cannot
spoof by sending its own X-Forwarded-For (that ends up further left).
"""
import ipaddress
from collections.abc import Mapping


def _is_internal(ip: str) -> bool:
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        return False
    return addr.is_private or addr.is_loopback or addr.is_link_local


def resolve_client_ip(peer: str, headers: Mapping[str, str]) -> str:
    if not peer or not _is_internal(peer):
        return peer or "unknown"
    forwarded = [h.strip() for h in (headers.get("x-forwarded-for") or "").split(",") if h.strip()]
    for hop in reversed(forwarded):
        if not _is_internal(hop):
            try:
                ipaddress.ip_address(hop)
            except ValueError:
                break
            return hop
    real_ip = (headers.get("x-real-ip") or "").strip()
    if real_ip and not _is_internal(real_ip):
        return real_ip
    if forwarded:
        return forwarded[0]
    return peer


def request_client_ip(request) -> str:
    peer = request.client.host if request.client else ""
    return resolve_client_ip(peer, {k.lower(): v for k, v in request.headers.items()})
