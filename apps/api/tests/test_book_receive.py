"""Consignment book inbound API."""
from unittest.mock import patch

import pytest

from app.core import db as db_mod
from app.services.book_lookup import BookLookupResult

from .helpers import build_tenant, login_admin, login_pos


def _mock_lookup(barcode: str) -> BookLookupResult:
    return BookLookupResult(
        title="測試書籍",
        author="測試作者",
        publisher="測試社",
        isbn="9780000000000",
        list_price_cents=300,
        sale_price_cents=240,
        barcode_kind="internal_11",
        category_main="文學",
        category_sub="小說",
        sale_disc=80,
        source="taaze",
    )


@pytest.mark.asyncio
async def test_receive_book_by_barcode_creates_inventory(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_admin(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}
    barcode = "11101042331"

    with patch("app.services.book_receive.lookup_barcode", side_effect=_mock_lookup):
        r = await client.post(
            "/books/receive",
            headers=headers,
            json={"barcode": barcode, "store_id": bundle.store.id, "qty": 2},
        )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["name"] == "測試書籍"
    assert body["on_hand"] == 2

    with patch("app.services.book_receive.lookup_barcode", side_effect=_mock_lookup):
        r2 = await client.post(
            "/books/receive",
            headers=headers,
            json={"barcode": barcode, "store_id": bundle.store.id, "qty": 1},
        )
    assert r2.status_code == 200
    assert r2.json()["on_hand"] == 3


@pytest.mark.asyncio
async def test_rereceive_keeps_isbn_cover_when_isbn_lookup_fails(app, client):
    from dataclasses import replace

    from app.services.taaze_client import TAAZE_COVER_URL

    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_admin(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}
    barcode = "81301768663"
    canonical = replace(_mock_lookup(barcode), image_url=TAAZE_COVER_URL.format(prod_id="11100858846"))
    fallback = replace(_mock_lookup(barcode), image_url=TAAZE_COVER_URL.format(prod_id=barcode))

    for lookup in (canonical, fallback):
        with patch("app.services.book_receive.lookup_barcode", return_value=lookup):
            r = await client.post(
                "/books/receive",
                headers=headers,
                json={"barcode": barcode, "store_id": bundle.store.id, "qty": 1},
            )
        assert r.status_code == 200, r.text

    assert "sc=11100858846" in r.json()["image_url"]
    assert r.json()["on_hand"] == 2


@pytest.mark.asyncio
async def test_logcode_adds_stock_to_same_isbn_and_creates_new_titles(app, client):
    from dataclasses import replace

    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_admin(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}

    async def receive(code: str, lookup: BookLookupResult):
        with patch("app.services.book_receive.lookup_barcode", return_value=lookup):
            return await client.post(
                "/books/receive",
                headers=headers,
                json={"barcode": code, "store_id": bundle.store.id, "qty": 1},
            )

    isbn = "9789861365145"
    by_prod = replace(_mock_lookup(""), isbn=isbn, prod_id="81301768663", sale_price_cents=240)
    first = await receive("81301768663", by_prod)
    assert first.status_code == 200, first.text

    # Another copy of the same title, scanned by LOGCODE: stock +1, its own price kept.
    by_logcode = replace(
        _mock_lookup(""), isbn=isbn, prod_id="11100858846", sale_price_cents=277,
        barcode_kind="logcode_18",
    )
    second = await receive(isbn + "24119", by_logcode)
    assert second.status_code == 200, second.text
    body = second.json()
    assert body["id"] == first.json()["id"]
    assert body["on_hand"] == 2
    assert body["price_cents"] == 240
    assert isbn + "24119" in body["barcodes"]

    # A title not in the store yet: product keyed by TAAZE prodId, LOGCODE kept as barcode.
    other = replace(
        _mock_lookup(""), isbn="9789571347653", prod_id="11100212439", barcode_kind="logcode_18",
    )
    third = await receive("978957134765320436", other)
    assert third.status_code == 200, third.text
    assert third.json()["sku"] == "11100212439"
    assert set(third.json()["barcodes"]) == {"11100212439", "978957134765320436"}


@pytest.mark.asyncio
async def test_list_books_returns_on_hand_without_store_filter(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_admin(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}
    barcode = "11101042331"

    with patch("app.services.book_receive.lookup_barcode", side_effect=_mock_lookup):
        r = await client.post(
            "/books/receive",
            headers=headers,
            json={"barcode": barcode, "store_id": bundle.store.id, "qty": 2},
        )
    assert r.status_code == 200, r.text

    r_list = await client.get("/books", headers=headers)
    assert r_list.status_code == 200, r_list.text
    books = r_list.json()
    assert len(books) == 1
    assert books[0]["on_hand"] == 2


@pytest.mark.asyncio
async def test_books_scan_endpoint_removed(app, client):
    factory = db_mod.get_session_factory()
    bundle = await build_tenant(factory)
    token = await login_pos(client, bundle)
    headers = {"Authorization": f"Bearer {token}"}
    r = await client.post("/books/scan", headers=headers, json={"barcode": "11101042331"})
    assert r.status_code == 404
