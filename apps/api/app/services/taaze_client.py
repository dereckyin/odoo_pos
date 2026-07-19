"""TAAZE product API client — https://service.taaze.tw/product/{prodId}"""
from __future__ import annotations

import re
from dataclasses import dataclass

import httpx

TAAZE_PRODUCT_URL = "https://service.taaze.tw/product/{prod_id}"
TAAZE_ISBN_URL = "https://service.taaze.tw/isbn/{prod_id}"
TAAZE_COVER_URL = (
    "https://media.taaze.tw/showLargeImage.html?sc={prod_id}&height=200&width=150&fill=f"
)


class TaazeProductNotFoundError(LookupError):
    pass


class TaazeProductError(LookupError):
    pass


@dataclass(frozen=True)
class TaazeProduct:
    prod_id: str
    title: str
    author: str
    publisher: str
    isbn: str | None
    category_main: str | None
    category_sub: str | None
    list_price_cents: int
    sale_price_cents: int | None
    image_url: str
    pages: int | None
    publish_date: str | None
    translator: str | None
    is_second_hand: bool
    sale_disc: int | None


def _parse_price_major(raw: str | int | float | None) -> int:
    if raw is None or raw == "":
        return 0
    try:
        return int(float(str(raw).strip()))
    except (TypeError, ValueError):
        return 0


def _clean_author(raw: str | None) -> str:
    if not raw:
        return "—"
    line = raw.split("\r\n")[0].split("\n")[0].strip()
    line = re.split(r"[（(]", line, maxsplit=1)[0].strip()
    return line or "—"


def _parse_publish_date(raw: str | None) -> str | None:
    if not raw or len(raw) != 8:
        return None
    return f"{raw[0:4]}-{raw[4:6]}-{raw[6:8]}"


def parse_taaze_product_payload(payload: dict) -> TaazeProduct:
    book = payload.get("book_data")
    if not isinstance(book, dict):
        raise TaazeProductNotFoundError("TAAZE 回傳無 book_data")

    prod_id = str(book.get("prodId") or book.get("orgProdId") or book.get("istProdId") or "").strip()
    if not prod_id:
        raise TaazeProductNotFoundError("TAAZE 回傳缺少 prodId")

    title = str(book.get("titleMain") or "").strip()
    if not title:
        raise TaazeProductNotFoundError("TAAZE 回傳缺少書名")

    # TWD amounts in this codebase are stored as whole dollars in `*_cents`
    # (see pos_core Money / admin formatMoney). Do not multiply by 100.
    list_cents = _parse_price_major(book.get("listPrice"))
    sale_major = _parse_price_major(book.get("salePrice"))
    sale_cents = sale_major if sale_major > 0 else None

    isbn = str(book.get("isbn") or book.get("eanCode") or "").strip() or None
    cat_main = str(book.get("catName1") or "").strip() or None
    cat_sub = str(book.get("catName") or "").strip() or None
    publisher = str(book.get("pubNmMain") or "").strip() or "—"
    translator = str(book.get("translator") or "").strip() or None

    pages_raw = book.get("pages")
    pages: int | None = None
    if pages_raw not in (None, ""):
        try:
            pages = int(str(pages_raw))
        except ValueError:
            pages = None

    snd = str(book.get("sndHandFlg") or "").upper() == "Y"

    sale_disc: int | None = None
    disc_raw = book.get("saleDisc")
    if disc_raw not in (None, ""):
        try:
            disc_val = int(float(str(disc_raw).strip()))
            if 0 < disc_val <= 100:
                sale_disc = disc_val
        except (TypeError, ValueError):
            sale_disc = None

    return TaazeProduct(
        prod_id=prod_id,
        title=title,
        author=_clean_author(book.get("author")),
        publisher=publisher,
        isbn=isbn,
        category_main=cat_main,
        category_sub=cat_sub,
        list_price_cents=list_cents if list_cents > 0 else (sale_cents or 0),
        sale_price_cents=sale_cents,
        image_url=TAAZE_COVER_URL.format(prod_id=prod_id),
        pages=pages,
        publish_date=_parse_publish_date(book.get("publishDate")),
        translator=translator,
        is_second_hand=snd,
        sale_disc=sale_disc,
    )


def _fetch_taaze_url(client: httpx.Client, url: str) -> TaazeProduct:
    try:
        resp = client.get(url, headers={"Accept": "application/json"})
    except httpx.HTTPError as e:
        raise TaazeProductError(f"無法連線 TAAZE：{e}") from e

    if resp.status_code == 404:
        raise TaazeProductNotFoundError(f"TAAZE 找不到：{url}")
    if resp.status_code >= 400:
        raise TaazeProductError(f"TAAZE HTTP {resp.status_code}")

    try:
        payload = resp.json()
    except ValueError as e:
        raise TaazeProductError("TAAZE 回傳非 JSON") from e

    return parse_taaze_product_payload(payload)


def fetch_taaze_product(prod_id: str, *, timeout: float = 12.0) -> TaazeProduct:
    code = prod_id.strip()
    urls = (
        TAAZE_PRODUCT_URL.format(prod_id=code),
        TAAZE_ISBN_URL.format(prod_id=code),
    )
    last_not_found: TaazeProductNotFoundError | None = None

    with httpx.Client(timeout=timeout, follow_redirects=True) as client:
        for url in urls:
            try:
                return _fetch_taaze_url(client, url)
            except TaazeProductNotFoundError as e:
                last_not_found = e
                continue

    raise last_not_found or TaazeProductNotFoundError(f"TAAZE 找不到商品 {code}")
