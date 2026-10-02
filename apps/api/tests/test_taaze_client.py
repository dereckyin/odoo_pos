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
    assert product.list_price_cents == 350
    assert product.sale_price_cents == 276
    assert product.pages == 232
    assert product.publish_date == "2024-08-06"
    assert product.is_second_hand is True
    assert product.sale_disc == 79
    assert "11101042331" in product.image_url


def test_parse_taaze_empty_payload_is_not_found():
    import pytest

    from app.services.taaze_client import TaazeProductNotFoundError

    for payload in ([], {}, None):
        with pytest.raises(TaazeProductNotFoundError):
            parse_taaze_product_payload(payload)


def test_813_prod_id_uses_isbn_canonical_cover_and_category():
    import httpx

    from app.services import taaze_client

    def handler(request: httpx.Request) -> httpx.Response:
        path = request.url.path
        if path == "/product/81301768663":
            return httpx.Response(200, json={"book_data": {
                "prodId": "81301768663", "titleMain": "測試書", "isbn": "9789861365145",
                "listPrice": "350", "salePrice": "0", "sndHandFlg": "N",
            }})
        if path == "/isbn/9789861365145":
            return httpx.Response(200, json={
                "prodId": "11100858846", "titleMain": "測試書", "eanCode": "9789861365145",
                "catName1": "心理勵志", "catName": "心靈成長", "pubNmMain": "測試出版",
            })
        return httpx.Response(200, json=[])

    real_client = httpx.Client
    transport = httpx.MockTransport(handler)
    taaze_client.httpx.Client = lambda **kw: real_client(transport=transport, **kw)
    try:
        product = taaze_client.fetch_taaze_product("81301768663")
    finally:
        taaze_client.httpx.Client = real_client

    assert product.prod_id == "81301768663"
    assert product.isbn == "9789861365145"
    assert product.list_price_cents == 350
    assert "sc=11100858846" in product.image_url
    assert product.category_main == "心理勵志"
    assert product.publisher == "測試出版"


def test_lookup_barcode_invalid_length():
    import pytest

    from app.services.book_lookup import UnsupportedBarcodeError

    with pytest.raises(UnsupportedBarcodeError):
        lookup_barcode("12345")
