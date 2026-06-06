"""Whether a product participates in inventory movements."""

from __future__ import annotations

from ..models import Product

PRODUCT_KIND_CONSIGNMENT = "consignment_book"


def product_tracks_inventory(product: Product | None) -> bool:
    if product is None:
        return True
    if getattr(product, "product_kind", "regular") == PRODUCT_KIND_CONSIGNMENT:
        return True
    return bool(getattr(product, "track_inventory", True))
