"""Book catalog lookup by barcode (TAAZE for 11-digit prodId)."""
from __future__ import annotations

from dataclasses import dataclass

from .taaze_client import (
    TaazeProduct,
    TaazeProductError,
    TaazeProductNotFoundError,
    fetch_taaze_product,
)


class UnsupportedBarcodeError(ValueError):
    pass


class BookLookupNotFoundError(LookupError):
    pass


@dataclass(frozen=True)
class BookLookupResult:
    title: str
    author: str
    publisher: str
    isbn: str | None
    list_price_cents: int
    sale_price_cents: int | None
    barcode_kind: str
    category_main: str | None = None
    category_sub: str | None = None
    image_url: str | None = None
    pages: int | None = None
    publish_date: str | None = None
    translator: str | None = None
    is_second_hand: bool = False
    sale_disc: int | None = None
    source: str = "taaze"


def classify_barcode(code: str) -> str:
    digits = code.strip()
    if len(digits) == 11 and digits.isdigit():
        return "internal_11"
    if len(digits) == 8 and digits.isdigit():
        return "external_8"
    raise UnsupportedBarcodeError("條碼須為 11 碼（TAAZE 商品編號）或 8 碼（他社）數字")


def _taaze_to_result(taaze: TaazeProduct, barcode_kind: str) -> BookLookupResult:
    sell_cents = taaze.sale_price_cents or taaze.list_price_cents
    return BookLookupResult(
        title=taaze.title,
        author=taaze.author,
        publisher=taaze.publisher,
        isbn=taaze.isbn,
        list_price_cents=taaze.list_price_cents,
        sale_price_cents=taaze.sale_price_cents,
        barcode_kind=barcode_kind,
        category_main=taaze.category_main,
        category_sub=taaze.category_sub,
        image_url=taaze.image_url,
        pages=taaze.pages,
        publish_date=taaze.publish_date,
        translator=taaze.translator,
        is_second_hand=taaze.is_second_hand,
        sale_disc=taaze.sale_disc,
        source="taaze",
    )


def _mock_external_lookup(barcode: str) -> BookLookupResult:
    """Placeholder for 8-digit non-TAAZE barcodes until another source is wired."""
    seed = sum(ord(c) for c in barcode)
    titles = ["二手書店見聞錄", "城市裡的慢速閱讀", "餐桌上的文學史"]
    authors = ["陳美玲", "張維中", "馮客"]
    publishers = ["聯經", "時報", "遠流"]
    price_major = 120 + (seed % 15) * 10
    return BookLookupResult(
        title=titles[seed % len(titles)],
        author=authors[seed % len(authors)],
        publisher=publishers[seed % len(publishers)],
        isbn=None,
        list_price_cents=price_major * 100,
        sale_price_cents=None,
        barcode_kind="external_8",
        category_main="他社書籍",
        category_sub="未分類",
        source="mock_external",
    )


def lookup_barcode(code: str) -> BookLookupResult:
    barcode = code.strip()
    kind = classify_barcode(barcode)

    if kind == "internal_11":
        try:
            taaze = fetch_taaze_product(barcode)
        except TaazeProductNotFoundError as e:
            raise BookLookupNotFoundError(str(e)) from e
        except TaazeProductError as e:
            raise BookLookupNotFoundError(str(e)) from e
        return _taaze_to_result(taaze, kind)

    return _mock_external_lookup(barcode)


def default_sell_price_cents(lookup: BookLookupResult) -> int:
    """POS 預設售價：優先 TAAZE salePrice，否則 listPrice。"""
    if lookup.sale_price_cents and lookup.sale_price_cents > 0:
        return lookup.sale_price_cents
    return lookup.list_price_cents
