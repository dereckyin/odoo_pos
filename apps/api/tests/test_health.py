async def test_health(client):
    r = await client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"ok": True}


async def test_root(client):
    r = await client.get("/")
    assert r.status_code == 200
    body = r.json()
    assert body["app"] == "pos-backend"
