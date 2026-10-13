import os
import tempfile

import pytest

os.environ["TILLO_DATA_DIR"] = tempfile.mkdtemp(prefix="tillo_test_")

from fastapi.testclient import TestClient  # noqa: E402

from app import gold  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture(autouse=True)
def offline_prices(monkeypatch):
    monkeypatch.setattr(gold, "_fetch", lambda: (dict(gold.FALLBACK), False))
    gold._cache.update(at=0.0, data=None)
    gold._refreshing.clear()


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


def _register(client, phone="+992 93 555 00 11"):
    r = client.post("/api/auth/register", json={"name": "Тест", "phone": phone, "password": "secret1"})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token']}"}


def test_meta_and_seed(client):
    meta = client.get("/api/meta").json()
    assert len(meta["categories"]) == 12
    assert sum(c["count"] for c in meta["categories"]) > 40
    assert "Душанбе" in meta["cities"]


def test_gold_price_math(client):
    q = client.get("/api/gold-price").json()
    g = q["gold_per_gram"]
    assert g["999"] > g["750"] > g["585"] > 0
    assert abs(g["585"] - g["999"] * 585 / 999) < 1
    assert q["live"] is False


def test_filters_and_sort(client):
    r = client.get("/api/listings", params={"category": "bullion", "sort": "price_asc"}).json()
    prices = [i["price"] for i in r["items"]]
    assert r["total"] == len(prices) > 0
    assert prices == sorted(prices)
    assert all(i["category"] == "bullion" for i in r["items"])

    r = client.get("/api/listings", params={"q": "БРИЛЛИАНТ"}).json()
    assert r["total"] > 0
    assert any(i["title"].startswith("Бриллиант") for i in r["items"])

    r = client.get("/api/listings", params={"min_price": 50000}).json()
    assert all(i["price"] >= 50000 for i in r["items"])

    r = client.get("/api/listings", params={"per_page": 5, "page": 2}).json()
    assert len(r["items"]) == 5


def test_detail_has_metal_value_and_counts_views(client):
    first = client.get("/api/listings", params={"category": "bullion"}).json()["items"][0]
    d1 = client.get(f"/api/listings/{first['id']}").json()
    d2 = client.get(f"/api/listings/{first['id']}").json()
    assert d2["views"] == d1["views"] + 1
    assert d1["metal_value"] > 0
    assert all(s["category"] == "bullion" for s in d1["similar"])
    assert client.get("/api/listings/999999").status_code == 404


def test_auth_flow(client):
    headers = _register(client, "93 555 00 22")
    me = client.get("/api/auth/me", headers=headers).json()
    assert me["phone"] == "+992935550022"
    assert client.post("/api/auth/register",
                       json={"name": "Тест", "phone": "+992935550022", "password": "secret1"}).status_code == 409
    assert client.post("/api/auth/login",
                       json={"phone": "+992935550022", "password": "wrong!!"}).status_code == 401
    assert client.post("/api/auth/login",
                       json={"phone": "+992935550022", "password": "secret1"}).status_code == 200
    assert client.get("/api/auth/me").status_code == 401
    assert client.post("/api/auth/register",
                       json={"name": "Тест", "phone": "123", "password": "secret1"}).status_code == 422


def test_create_upload_and_delete(client):
    headers = _register(client, "+992935550033")
    png = b"\x89PNG\r\n\x1a\n" + b"0" * 64
    up = client.post("/api/uploads", headers=headers, files={"file": ("a.png", png, "image/png")})
    assert up.status_code == 201
    url = up.json()["url"]
    assert client.get(url).status_code == 200

    bad = client.post("/api/uploads", headers=headers, files={"file": ("a.txt", b"x", "text/plain")})
    assert bad.status_code == 415

    body = {"title": "Ангуштарини нав", "category": "rings", "metal": "gold", "proba": 585,
            "weight": 3.5, "price": 4200, "city": "Душанбе", "images": [url]}
    assert client.post("/api/listings", json=body).status_code == 401
    assert client.post("/api/listings", headers=headers, json={**body, "proba": 123}).status_code == 422
    assert client.post("/api/listings", headers=headers,
                       json={**body, "images": ["http://evil/x.png"]}).status_code == 422

    created = client.post("/api/listings", headers=headers, json=body)
    assert created.status_code == 201
    lid = created.json()["id"]
    assert created.json()["phone"] == "+992935550033"

    mine = client.get("/api/listings", params={"mine": "true"}, headers=headers).json()
    assert [i["id"] for i in mine["items"]] == [lid]

    favs = client.get("/api/listings", params={"ids": f"{lid},1"}).json()
    assert {i["id"] for i in favs["items"]} == {lid, 1}

    other = _register(client, "+992935550044")
    assert client.delete(f"/api/listings/{lid}", headers=other).status_code == 403
    assert client.delete(f"/api/listings/{lid}", headers=headers).status_code == 204
    assert client.get(url).status_code == 404
