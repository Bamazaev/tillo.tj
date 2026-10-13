"""Маълумоти намунавӣ барои базаи холӣ. Пароли ҳамаи ҳисобҳои демо: tillo123"""
import json
import random
import shutil
from pathlib import Path

from .auth import hash_password
from .db import BASE_DIR, UPLOAD_DIR, get_conn
from .gold import FALLBACK, TROY_OUNCE_G

SELLERS = [
    ("Ювелир Сомон", "+992900000001", True),
    ("Gold House Душанбе", "+992900000002", True),
    ("Ювелирный дом Худжанд", "+992900000003", True),
    ("Бадахшанский лал", "+992900000004", True),
    ("Фарзона", "+992900000005", False),
    ("Шерзод", "+992900000006", False),
]

# (сарлавҳа, категория, металл, проба, вазн, санг, тавсиф)
ITEMS = [
    ("Обручальное кольцо с бриллиантом 0.5 карат", "wedding", "white_gold", 750, 4.2, "diamond",
     "Натуральный бриллиант, сертификат GIA. Есть размеры 16–19."),
    ("Классическое золотое кольцо", "rings", "gold", 585, 3.1, "none",
     "Золото 585 пробы, полированная поверхность. На каждый день."),
    ("Мужской перстень с рубином", "rings", "gold", 750, 9.8, "ruby",
     "Ручная работа, натуральный рубин. Восточный дизайн."),
    ("Кольцо из розового золота «Роза»", "rings", "rose_gold", 585, 2.7, "zirconia",
     "Розовое золото с фианитами. Отличный подарок."),
    ("Кольцо с колумбийским изумрудом", "rings", "gold", 750, 5.4, "emerald",
     "Изумруд 1.2 карата в окружении мелких бриллиантов."),
    ("Серьги «Звезда» с бриллиантами", "earrings", "white_gold", 750, 3.6, "diamond",
     "Два бриллианта по 0.25 карата. Английский замок."),
    ("Бухарские золотые серьги", "earrings", "gold", 583, 6.2, "none",
     "Национальный орнамент, работа бухарских мастеров."),
    ("Серьги с жемчугом", "earrings", "gold", 585, 2.9, "pearl",
     "Натуральный морской жемчуг, 8 мм."),
    ("Детские серьги", "earrings", "gold", 585, 1.4, "zirconia",
     "Лёгкие и безопасные, детский замок."),
    ("Цепь «Бисмарк» 55 см", "chains", "gold", 585, 18.5, "none",
     "Прочное плетение, мужская модель."),
    ("Тонкая женская цепочка 45 см", "chains", "gold", 585, 3.3, "none",
     "Плетение «Сингапур», с блеском."),
    ("Цепь «Картье», золото 750", "chains", "gold", 750, 24.0, "none",
     "Большой вес, итальянская работа."),
    ("Цепочка из белого золота с подвеской", "chains", "white_gold", 585, 4.8, "diamond",
     "В комплекте подвеска с бриллиантом."),
    ("Подвеска «Сердце» с бадахшанской шпинелью", "pendants", "gold", 585, 2.2, "spinel",
     "Натуральная шпинель (лал) Бадахшана, розово‑красный цвет."),
    ("Свадебное национальное ожерелье", "pendants", "gold", 583, 42.0, "ruby",
     "Традиционное таджикское ожерелье для свадьбы. Ручная работа."),
    ("Подвеска «Аятуль Курси»", "pendants", "gold", 585, 3.9, "none",
     "Гладкая гравировка с обеих сторон."),
    ("Колье с сапфиром и бриллиантами", "pendants", "white_gold", 750, 11.5, "sapphire",
     "Синий сапфир из Шри‑Ланки, 2 карата."),
    ("Теннисный браслет с бриллиантами", "bracelets", "white_gold", 750, 12.3, "diamond",
     "42 бриллианта, общий вес 3 карата."),
    ("Жёсткий золотой браслет", "bracelets", "gold", 585, 15.6, "none",
     "Классический браслет, размер 18 см."),
    ("Браслет‑цепочка с топазом", "bracelets", "gold", 585, 7.1, "topaz",
     "Небесно‑голубой топаз."),
    ("Мужской браслет «Бисмарк»", "bracelets", "gold", 585, 28.0, "none",
     "Массивный и надёжный, 21 см."),
    ("Гарнитур «Царица»: серьги + кольцо + подвеска", "sets", "gold", 750, 16.4, "emerald",
     "Полный комплект в подарочной коробке."),
    ("Бухарский свадебный гарнитур", "sets", "gold", 583, 58.0, "ruby",
     "Ожерелье, серьги, браслет и тиллокош."),
    ("Жемчужный гарнитур", "sets", "white_gold", 585, 9.2, "pearl",
     "Белый жемчуг, классический стиль."),
    ("Пара обручальных колец", "wedding", "gold", 585, 8.6, "none",
     "Два кольца, гравировка бесплатно."),
    ("Свадебный тиллокош", "wedding", "gold", 583, 21.0, "ruby",
     "Традиционный тиллокош с рубинами и жемчугом."),
    ("Помолвочное кольцо «Солитер»", "wedding", "platinum", 950, 5.0, "diamond",
     "Платина и бриллиант 1 карат, цвет F, чистота VS1."),
    ("Часы Rolex Datejust 36, золото 750", "watches", "gold", 750, 95.0, "none",
     "Оригинал, с документами и коробкой. 2021 год."),
    ("Женские золотые часы с бриллиантами", "watches", "rose_gold", 585, 22.0, "diamond",
     "Швейцарский механизм, золотой браслет."),
    ("Часы Omega Constellation", "watches", "gold", 750, 64.0, "none",
     "Отличное состояние, после обслуживания."),
    ("Слиток золота 10 г, 999.9", "bullion", "gold", 999, 10.0, "none",
     "Банковский слиток с сертификатом. Надёжная инвестиция."),
    ("Слиток золота 50 г, 999.9", "bullion", "gold", 999, 50.0, "none",
     "PAMP Suisse, в оригинальной упаковке."),
    ("Золотая монета «Георгий Победоносец»", "bullion", "gold", 999, 7.78, "none",
     "Инвестиционная монета, 1/4 унции."),
    ("Слиток золота 100 г", "bullion", "gold", 999, 100.0, "none",
     "Крупный слиток с серийным номером."),
    ("Монета «Krugerrand» 1 унция", "bullion", "gold", 916, 33.93, "none",
     "ЮАР, 22 карата."),
    ("Бриллиант 1.01 карат", "gems", "none", None, 0.2, "diamond",
     "Огранка «Round», цвет G, чистота VS2, сертификат GIA."),
    ("Бадахшанская шпинель 4.5 карата", "gems", "none", None, 0.9, "spinel",
     "Редкий камень с Памира. Тёплый красный цвет."),
    ("Натуральный изумруд 2.3 карата", "gems", "none", None, 0.46, "emerald",
     "Глубокий зелёный цвет, без масляной обработки."),
    ("Цейлонский синий сапфир 3 карата", "gems", "none", None, 0.6, "sapphire",
     "Цвет «Royal Blue», есть сертификат."),
    ("Натуральный жемчуг, 50 штук", "gems", "none", None, 30.0, "pearl",
     "Для ювелиров, размер 6–7 мм."),
    ("Серебряная цепь 925, 60 см", "silver", "silver", 925, 22.0, "none",
     "Стерлинговое серебро, плетение «Рамка»."),
    ("Серебряное кольцо с агатом", "silver", "silver", 925, 9.0, "none",
     "Ручная работа мастеров Истаравшана."),
    ("Памирское серебряное ожерелье", "silver", "silver", 875, 48.0, "spinel",
     "Традиционное бадахшанское украшение со шпинелью."),
    ("Золотое ожерелье XIX века", "antique", "gold", 583, 36.0, "ruby",
     "Музейная вещь с семейной историей."),
    ("Золотая бухарская монета (тилля)", "antique", "gold", 916, 4.5, "none",
     "Историческая монета Бухарского эмирата."),
    ("Антикварное европейское кольцо", "antique", "gold", 750, 6.3, "topaz",
     "XX век, стиль ар‑деко."),
]

STONE_PREMIUM = {
    "none": 0, "zirconia": 150, "topaz": 900, "pearl": 1500, "spinel": 6500,
    "ruby": 7000, "emerald": 9000, "sapphire": 9500, "diamond": 14000,
}

CITIES_WEIGHTED = ["Душанбе"] * 5 + ["Хуҷанд"] * 3 + ["Бохтар", "Кӯлоб", "Истаравшан", "Хоруғ", "Панҷакент", "Исфара"]


def _price(category: str, metal: str, proba: int | None, weight: float, stone: str, rnd: random.Random) -> int:
    gram_999 = FALLBACK["xau"] / TROY_OUNCE_G * FALLBACK["tjs"]
    silver_999 = FALLBACK["xag"] / TROY_OUNCE_G * FALLBACK["tjs"]
    if category == "gems":
        base = STONE_PREMIUM[stone] * rnd.uniform(1.5, 4.0)
    elif metal == "silver":
        base = silver_999 * (proba or 925) / 1000 * weight * rnd.uniform(2.5, 4.0)
    else:
        markup = 1.04 if category == "bullion" else rnd.uniform(1.2, 1.55)
        if metal == "platinum":
            markup *= 0.8
        base = gram_999 * (proba or 585) / 1000 * weight * markup
        base += STONE_PREMIUM[stone] * rnd.uniform(0.6, 2.2)
        if category in ("watches", "antique"):
            base *= rnd.uniform(1.4, 2.0)
    return int(round(base / 10) * 10)


# Суратҳои озод (Public Domain / CC0) аз Wikimedia Commons; манбаъҳо — CREDITS.md.
SEED_PHOTOS = BASE_DIR / "seed_photos"


def seed_images(n: int) -> list[str]:
    """Сурати эълони n-умро ба uploads нусха мекунад (агар бошад)."""
    src = SEED_PHOTOS / f"{n}.jpg"
    if not src.exists():
        return []
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    name = f"seed_{n}.jpg"
    if not (UPLOAD_DIR / name).exists():
        shutil.copyfile(src, UPLOAD_DIR / name)
    return [f"/uploads/{name}"]


def seed_if_empty() -> None:
    with get_conn() as conn:
        if conn.execute("SELECT COUNT(*) FROM listings").fetchone()[0]:
            return
        rnd = random.Random(2026)
        pw = hash_password("tillo123")
        user_ids = []
        for name, phone, shop in SELLERS:
            row = conn.execute("SELECT id FROM users WHERE phone = ?", (phone,)).fetchone()
            if row:
                user_ids.append((row["id"], phone, shop))
                continue
            cur = conn.execute(
                "INSERT INTO users(name, phone, password_hash, is_shop) VALUES (?, ?, ?, ?)",
                (name, phone, pw, int(shop)),
            )
            user_ids.append((cur.lastrowid, phone, shop))

        for i, (title, cat, metal, proba, weight, stone, desc) in enumerate(ITEMS):
            uid, phone, shop = user_ids[i % len(user_ids)]
            if cat == "gems" and stone in ("spinel",):
                uid, phone, shop = user_ids[3]
            condition = "used" if cat == "antique" or (not shop and rnd.random() < 0.6) else "new"
            conn.execute(
                """INSERT INTO listings(user_id, title, description, category, metal, proba, weight,
                       stone, condition, price, city, phone, images, featured, views, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now', ?))""",
                (uid, title, desc, cat, metal, proba, weight, stone, condition,
                 _price(cat, metal, proba, weight, stone, rnd),
                 "Хоруғ" if stone == "spinel" else rnd.choice(CITIES_WEIGHTED),
                 phone, json.dumps(seed_images(i + 1)), int(i % 4 == 0), rnd.randint(12, 900),
                 f"-{rnd.randint(0, 60 * 24 * 20)} minutes"),
            )
