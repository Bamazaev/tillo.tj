"""Tillo.tj API — бозори тилло, ҷавоҳирот ва сангҳои қиматбаҳо."""
import json
import os
import secrets
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import Depends, FastAPI, File, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field, field_validator

from . import catalog, gold
from .auth import (
    create_session,
    current_user,
    hash_password,
    normalize_phone,
    optional_user,
    public_user,
    verify_password,
)
from .db import BASE_DIR, UPLOAD_DIR, get_conn, init_db, listing_to_dict
from .seed import seed_if_empty

WEB_DIR = Path(os.environ.get("TILLO_WEB_DIR", BASE_DIR.parent / "frontend" / "build" / "web"))
MAX_UPLOAD = 6 * 1024 * 1024
IMAGE_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    gold.refresh_async()
    if os.environ.get("TILLO_SEED", "1") == "1":
        seed_if_empty()
    yield


app = FastAPI(title="Tillo.tj API", version="1.0.0", lifespan=lifespan)
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("TILLO_CORS", "*").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


# ---------- схемаҳо ----------

class RegisterIn(BaseModel):
    name: str = Field(min_length=2, max_length=60)
    phone: str
    password: str = Field(min_length=6, max_length=100)
    is_shop: bool = False


class LoginIn(BaseModel):
    phone: str
    password: str


class ListingIn(BaseModel):
    title: str = Field(min_length=3, max_length=120)
    description: str = Field(default="", max_length=4000)
    category: str
    metal: str
    proba: int | None = None
    weight: float | None = Field(default=None, gt=0, le=100_000)
    stone: str = "none"
    condition: str = "new"
    price: int = Field(gt=0, le=10_000_000_000)
    city: str
    phone: str | None = None
    images: list[str] = Field(default_factory=list, max_length=10)

    @field_validator("category")
    @classmethod
    def _cat(cls, v):
        if v not in catalog.CATEGORY_SLUGS:
            raise ValueError("Неверная категория")
        return v

    @field_validator("metal")
    @classmethod
    def _metal(cls, v):
        if v not in catalog.METAL_SLUGS:
            raise ValueError("Неверный металл")
        return v

    @field_validator("proba")
    @classmethod
    def _proba(cls, v):
        if v is not None and v not in catalog.PROBAS:
            raise ValueError("Неверная проба")
        return v

    @field_validator("stone")
    @classmethod
    def _stone(cls, v):
        if v not in catalog.STONE_SLUGS:
            raise ValueError("Неверный камень")
        return v

    @field_validator("condition")
    @classmethod
    def _cond(cls, v):
        if v not in catalog.CONDITION_SLUGS:
            raise ValueError("Неверное состояние")
        return v

    @field_validator("city")
    @classmethod
    def _city(cls, v):
        if v not in catalog.CITIES:
            raise ValueError("Неверный город")
        return v

    @field_validator("images")
    @classmethod
    def _images(cls, v):
        for url in v:
            if not url.startswith("/uploads/"):
                raise ValueError("Фото нужно сначала загрузить")
        return v


# ---------- маълумоти умумӣ ----------

@app.get("/api/health")
def health():
    return {"ok": True}


@app.get("/api/meta")
def meta():
    with get_conn() as conn:
        counts = dict(conn.execute("SELECT category, COUNT(*) FROM listings GROUP BY category").fetchall())
    return {
        "categories": [{**c, "count": counts.get(c["slug"], 0)} for c in catalog.CATEGORIES],
        "metals": catalog.METALS,
        "probas": catalog.PROBAS,
        "stones": catalog.STONES,
        "conditions": catalog.CONDITIONS,
        "cities": catalog.CITIES,
    }


@app.get("/api/gold-price")
def gold_price():
    return gold.get_quote()


# ---------- аутентификатсия ----------

@app.post("/api/auth/register")
def register(body: RegisterIn):
    phone = normalize_phone(body.phone)
    with get_conn() as conn:
        if conn.execute("SELECT 1 FROM users WHERE phone = ?", (phone,)).fetchone():
            raise HTTPException(409, "Этот номер уже зарегистрирован")
        cur = conn.execute(
            "INSERT INTO users(name, phone, password_hash, is_shop) VALUES (?, ?, ?, ?)",
            (body.name.strip(), phone, hash_password(body.password), int(body.is_shop)),
        )
        row = conn.execute("SELECT * FROM users WHERE id = ?", (cur.lastrowid,)).fetchone()
    return {"token": create_session(row["id"]), "user": public_user(row)}


@app.post("/api/auth/login")
def login(body: LoginIn):
    phone = normalize_phone(body.phone)
    with get_conn() as conn:
        row = conn.execute("SELECT * FROM users WHERE phone = ?", (phone,)).fetchone()
    if not row or not verify_password(body.password, row["password_hash"]):
        raise HTTPException(401, "Неверный номер или пароль")
    return {"token": create_session(row["id"]), "user": public_user(row)}


@app.get("/api/auth/me")
def me(user: dict = Depends(current_user)):
    return user


# ---------- эълонҳо ----------

LISTING_SELECT = """
SELECT l.*, u.name AS seller_name, u.is_shop AS is_shop
FROM listings l JOIN users u ON u.id = l.user_id
"""


@app.get("/api/listings")
def list_listings(
    q: str | None = None,
    category: str | None = None,
    metal: str | None = None,
    proba: int | None = None,
    stone: str | None = None,
    city: str | None = None,
    condition: str | None = None,
    min_price: int | None = None,
    max_price: int | None = None,
    featured: bool | None = None,
    mine: bool = False,
    ids: str | None = Query(default=None, description="Рӯйхати id бо вергул (барои дӯстдоштаҳо)"),
    sort: str = "new",
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=24, ge=1, le=60),
    user: dict | None = Depends(optional_user),
):
    where, args = [], []
    if q:
        where.append("(ulower(l.title) LIKE ? OR ulower(l.description) LIKE ?)")
        args += [f"%{q.strip().lower()}%"] * 2
    for col, val in (("category", category), ("metal", metal), ("proba", proba),
                     ("stone", stone), ("city", city), ("condition", condition)):
        if val not in (None, ""):
            where.append(f"l.{col} = ?")
            args.append(val)
    if min_price is not None:
        where.append("l.price >= ?")
        args.append(min_price)
    if max_price is not None:
        where.append("l.price <= ?")
        args.append(max_price)
    if featured is not None:
        where.append("l.featured = ?")
        args.append(int(featured))
    if mine:
        if not user:
            raise HTTPException(401, "Сначала войдите")
        where.append("l.user_id = ?")
        args.append(user["id"])
    if ids is not None:
        id_list = [int(x) for x in ids.split(",") if x.strip().isdigit()][:100]
        if not id_list:
            return {"items": [], "total": 0, "page": page, "per_page": per_page}
        where.append(f"l.id IN ({','.join('?' * len(id_list))})")
        args += id_list

    clause = (" WHERE " + " AND ".join(where)) if where else ""
    order = catalog.SORTS.get(sort, catalog.SORTS["new"])
    with get_conn() as conn:
        total = conn.execute(f"SELECT COUNT(*) FROM listings l{clause}", args).fetchone()[0]
        rows = conn.execute(
            f"{LISTING_SELECT}{clause} ORDER BY {order} LIMIT ? OFFSET ?",
            [*args, per_page, (page - 1) * per_page],
        ).fetchall()
    return {"items": [listing_to_dict(r) for r in rows], "total": total, "page": page, "per_page": per_page}


@app.get("/api/listings/{listing_id}")
def get_listing(listing_id: int):
    with get_conn() as conn:
        conn.execute("UPDATE listings SET views = views + 1 WHERE id = ?", (listing_id,))
        row = conn.execute(f"{LISTING_SELECT} WHERE l.id = ?", (listing_id,)).fetchone()
        if not row:
            raise HTTPException(404, "Объявление не найдено")
        similar = conn.execute(
            f"{LISTING_SELECT} WHERE l.category = ? AND l.id != ? ORDER BY l.featured DESC, l.views DESC LIMIT 8",
            (row["category"], listing_id),
        ).fetchall()
    item = listing_to_dict(row)
    item["metal_value"] = gold.metal_value(gold.get_quote(), item["metal"], item["proba"], item["weight"])
    item["similar"] = [listing_to_dict(r) for r in similar]
    return item


@app.post("/api/listings", status_code=201)
def create_listing(body: ListingIn, user: dict = Depends(current_user)):
    phone = normalize_phone(body.phone) if body.phone else user["phone"]
    with get_conn() as conn:
        cur = conn.execute(
            """INSERT INTO listings(user_id, title, description, category, metal, proba, weight,
                                    stone, condition, price, city, phone, images)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (user["id"], body.title.strip(), body.description.strip(), body.category, body.metal,
             body.proba, body.weight, body.stone, body.condition, body.price, body.city, phone,
             json.dumps(body.images)),
        )
        row = conn.execute(f"{LISTING_SELECT} WHERE l.id = ?", (cur.lastrowid,)).fetchone()
    return listing_to_dict(row)


@app.delete("/api/listings/{listing_id}", status_code=204)
def delete_listing(listing_id: int, user: dict = Depends(current_user)):
    with get_conn() as conn:
        row = conn.execute("SELECT user_id, images FROM listings WHERE id = ?", (listing_id,)).fetchone()
        if not row:
            raise HTTPException(404, "Объявление не найдено")
        if row["user_id"] != user["id"]:
            raise HTTPException(403, "Это не ваше объявление")
        conn.execute("DELETE FROM listings WHERE id = ?", (listing_id,))
    for url in json.loads(row["images"]):
        (UPLOAD_DIR / Path(url).name).unlink(missing_ok=True)


@app.post("/api/uploads", status_code=201)
async def upload_image(file: UploadFile = File(...), user: dict = Depends(current_user)):
    ext = IMAGE_TYPES.get(file.content_type or "")
    if not ext:
        raise HTTPException(415, "Только JPG, PNG или WEBP")
    data = await file.read(MAX_UPLOAD + 1)
    if len(data) > MAX_UPLOAD:
        raise HTTPException(413, "Фото больше 6 МБ")
    name = f"{user['id']}_{secrets.token_hex(8)}{ext}"
    (UPLOAD_DIR / name).write_bytes(data)
    return {"url": f"/uploads/{name}"}


# ---------- сайти Flutter (агар сохта шуда бошад) ----------

if WEB_DIR.is_dir():
    @app.get("/{path:path}", include_in_schema=False)
    def spa(path: str):
        target = (WEB_DIR / path).resolve()
        if path and target.is_file() and WEB_DIR.resolve() in target.parents:
            return FileResponse(target)
        return FileResponse(WEB_DIR / "index.html")
