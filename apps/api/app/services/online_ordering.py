"""Per-store settings for the unified shopping (/shopping/) public channel."""
from __future__ import annotations

from typing import Any

from ..models import Store

# Defaults when online ordering is enabled but fields are omitted.
DEFAULT_ENABLED_SETTINGS: dict[str, Any] = {
    "enabled": True,
    "supports_pickup": True,
    "supports_dine_in": True,
    "supports_delivery": False,
    "payment_counter": True,
    "payment_online": False,
    "min_order_cents": 0,
    "delivery_fee_cents": 0,
}

DEFAULT_DISABLED_SETTINGS: dict[str, Any] = {
    **DEFAULT_ENABLED_SETTINGS,
    "enabled": False,
}


def read_online_ordering(store: Store) -> dict[str, Any]:
    """Return normalised online-ordering settings for a store."""
    raw = store.online_ordering_json or {}
    enabled = bool(raw.get("enabled", False))
    base = dict(DEFAULT_ENABLED_SETTINGS if enabled else DEFAULT_DISABLED_SETTINGS)
    for key in DEFAULT_ENABLED_SETTINGS:
        if key in raw and raw[key] is not None:
            if key in ("min_order_cents", "delivery_fee_cents"):
                try:
                    base[key] = max(0, int(raw[key]))
                except (TypeError, ValueError):
                    pass
            elif key == "enabled":
                base[key] = enabled
            else:
                base[key] = bool(raw[key])
    return base


def is_online_ordering_enabled(store: Store) -> bool:
    return bool(read_online_ordering(store).get("enabled"))


def normalize_online_ordering_patch(payload: dict[str, Any] | None) -> dict[str, Any] | None:
    """Validate/normalise a PATCH payload; return None to clear the field."""
    if payload is None:
        return None
    out = dict(DEFAULT_DISABLED_SETTINGS)
    for key in DEFAULT_ENABLED_SETTINGS:
        if key in payload and payload[key] is not None:
            if key in ("min_order_cents", "delivery_fee_cents"):
                try:
                    out[key] = max(0, int(payload[key]))
                except (TypeError, ValueError):
                    out[key] = 0
            else:
                out[key] = bool(payload[key])
    # If enabling with no fulfillment modes, keep pickup+dine_in defaults.
    if out["enabled"] and not (
        out["supports_pickup"] or out["supports_dine_in"] or out["supports_delivery"]
    ):
        out["supports_pickup"] = True
        out["supports_dine_in"] = True
    if out["enabled"] and not (out["payment_counter"] or out["payment_online"]):
        out["payment_counter"] = True
    return out
