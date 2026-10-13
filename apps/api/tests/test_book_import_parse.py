import pytest

from app.services.book_import import BookImportFormatError, parse_book_import_csv


@pytest.mark.parametrize(
    "raw",
    [
        b"barcode,qty,store_id,store_code\n81301701682,1,,TAINANFAREAST\n",
        b"\xef\xbb\xbfbarcode,qty,store_id,store_code\r\n81301701682,1,,TAINANFAREAST\r\n",
        b"barcode\tqty\tstore_id\tstore_code\r\n81301701682\t1\t\tTAINANFAREAST\r\n",
        b"barcode;qty;store_id;store_code\n81301701682;1;;TAINANFAREAST\n",
        b" Barcode , QTY ,store_id,store_code\n81301701682,1,,TAINANFAREAST\n",
    ],
)
def test_parse_accepts_excel_variants(raw):
    rows = parse_book_import_csv(raw)
    assert len(rows) == 1
    assert rows[0]["barcode"].strip() == "81301701682"
    assert rows[0]["qty"].strip() == "1"
    assert rows[0]["store_code"] == "TAINANFAREAST"


def test_parse_big5_file():
    raw = "barcode,qty,store_id,store_code,備註\n81301701682,1,,TAINANFAREAST,台南\n".encode("cp950")
    rows = parse_book_import_csv(raw)
    assert rows[0]["barcode"] == "81301701682"


def test_parse_without_barcode_header_is_rejected():
    with pytest.raises(BookImportFormatError):
        parse_book_import_csv(b"code,qty\n81301701682,1\n")
