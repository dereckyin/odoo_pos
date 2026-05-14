"""Purchase orders, suppliers, and receive-to-inventory."""

from app.core import db as db_mod
from app.models import Product

from .helpers import build_tenant, login_admin


async def test_purchase_receive_creates_movement_and_level(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_admin(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}

    r = await client.post(
        "/purchasing/suppliers",
        headers=headers,
        json={"code": "V1", "name": "Vendor", "phone": None},
    )
    assert r.status_code == 201, r.text
    supplier_id = r.json()["id"]

    async with factory() as db:
        pid = "prod-po-2"
        db.add(
            Product(
                id=pid,
                tenant_id=bundle.tenant.id,
                sku="X1",
                name="Item",
                price_cents=5,
            )
        )
        await db.commit()

    po_id = "00000000-0000-7000-8000-000000000099"
    line_id = "00000000-0000-7000-8000-000000000098"
    r = await client.post(
        "/purchasing/orders",
        headers=headers,
        json={
            "id": po_id,
            "store_id": bundle.store.id,
            "supplier_id": supplier_id,
            "reference": "T-1",
            "lines": [{"id": line_id, "product_id": pid, "qty_ordered": 10}],
        },
    )
    assert r.status_code == 201, r.text

    r = await client.patch(
        f"/purchasing/orders/{po_id}",
        headers=headers,
        json={"status": "ordered"},
    )
    assert r.status_code == 200, r.text

    r = await client.post(
        f"/purchasing/orders/{po_id}/receive",
        headers=headers,
        json={"lines": [{"line_id": line_id, "qty": 4}]},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["status"] == "partial"
    assert body["lines"][0]["qty_received"] == 4

    r = await client.get("/inventory/levels", params={"store_id": bundle.store.id}, headers=headers)
    rows = r.json()
    hit = next((x for x in rows if x["product_id"] == pid), None)
    assert hit is not None
    assert float(hit["on_hand"]) == 4
