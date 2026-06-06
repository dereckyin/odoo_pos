from app.services.book_lookup import lookup_barcode
from app.services.taaze_client import parse_taaze_product_payload

SAMPLE_PAYLOAD = {
    "book_data": {
        "prodId": "11101042331",
        "titleMain": "台灣超越日本，真的嗎？：鳳梨、便當、台積電，台日社會文化多樣交流的觀察與思索",
        "author": "野島剛",
        "pubNmMain": "時報文化出版企業股份有限公司",
        "isbn": "9786263965393",
        "eanCode": "9786263965393",
        "catName1": "社會科學",
        "catName": "文化研究",
        "listPrice": "350",
        "salePrice": "276",
        "publishDate": "20240806",
        "pages": "232",
        "sndHandFlg": "Y",
        "saleDisc": "79",
        "translator": "",
    }
}


def test_parse_taaze_product_payload():
    payload = SAMPLE_PAYLOAD
    product = parse_taaze_product_payload(payload)
    assert product.prod_id == "11101042331"
    assert "台灣超越日本" in product.title
    assert product.author == "野島剛"
    assert product.publisher == "時報文化出版企業股份有限公司"
    assert product.isbn == "9786263965393"
    assert product.category_main == "社會科學"
    assert product.category_sub == "文化研究"
    assert product.list_price_cents == 35000
    assert product.sale_price_cents == 27600
    assert product.pages == 232
    assert product.publish_date == "2024-08-06"
    assert product.is_second_hand is True
    assert product.sale_disc == 79
    assert "11101042331" in product.image_url


def test_lookup_barcode_invalid_length():
    import pytest

    from app.services.book_lookup import UnsupportedBarcodeError

    with pytest.raises(UnsupportedBarcodeError):
        lookup_barcode("12345")
