"""Маълумоти намунавиро барои версияи намоишии бе сервер (GitHub Pages) содир мекунад.

python -m tools.export_demo ../frontend/assets/demo/data.json
"""
import json
import os
import shutil
import sys
import tempfile

os.environ["TILLO_DATA_DIR"] = tempfile.mkdtemp(prefix="tillo_demo_")

from app import catalog, gold  # noqa: E402
from app.db import get_conn, init_db, listing_to_dict  # noqa: E402
from app.seed import SEED_PHOTOS, seed_if_empty  # noqa: E402
from pathlib import Path  # noqa: E402


def main(out: str) -> None:
    init_db()
    seed_if_empty()
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT l.*, u.name AS seller_name, u.is_shop AS is_shop FROM listings l JOIN users u ON u.id = l.user_id"
        ).fetchall()
        users = [
            {"id": u["id"], "name": u["name"], "phone": u["phone"], "is_shop": bool(u["is_shop"])}
            for u in conn.execute("SELECT * FROM users").fetchall()
        ]
    # Нархи воқеии лаҳзаи содирот; дар браузер онро нархи зинда иваз мекунад.
    q = gold.get_quote()
    data = {
        "meta": {
            "categories": catalog.CATEGORIES,
            "metals": catalog.METALS,
            "probas": catalog.PROBAS,
            "stones": catalog.STONES,
            "conditions": catalog.CONDITIONS,
            "cities": catalog.CITIES,
        },
        "quote": {**q, "live": False},
        "users": users,
        # В демо (GitHub Pages) фото лежат рядом с сайтом: web/demo/N.jpg
        "listings": [
            {**d, "images": [u.replace("/uploads/seed_", "demo/") for u in d["images"]]}
            for d in (listing_to_dict(r) for r in rows)
        ],
    }
    web_demo = Path(out).resolve().parents[2] / "web" / "demo"
    web_demo.mkdir(parents=True, exist_ok=True)
    for photo in SEED_PHOTOS.glob("*.jpg"):
        shutil.copyfile(photo, web_demo / photo.name)
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, separators=(",", ":"))
    print(f"{len(data['listings'])} listings -> {out}")


if __name__ == "__main__":
    main(sys.argv[1])
