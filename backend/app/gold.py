"""Нархи зиндаи тилло/нуқра (USD/oz) ва қурби доллар ба сомонӣ.

Манбаъҳо бе калид: api.gold-api.com ва open.er-api.com. Натиҷа 15 дақиқа
кеш мешавад; агар интернет набошад, охирин нарх ё қимати пешфарз бармегардад.
"""
import json
import threading
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone

TROY_OUNCE_G = 31.1034768
CACHE_SECONDS = 15 * 60
TIMEOUT = 4

FALLBACK = {"xau": 4150.0, "xag": 50.0, "tjs": 9.25}

_lock = threading.Lock()
_cache: dict = {"at": 0.0, "data": None}


def _get_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": "tillo.tj/1.0"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return json.loads(resp.read().decode("utf-8"))


def _metal_price(symbol: str) -> float:
    """USD/oz: аввал gold-api.com, агар ҷавоб надиҳад — Swissquote (миёнаи bid/ask)."""
    try:
        return float(_get_json(f"https://api.gold-api.com/price/{symbol}")["price"])
    except Exception:
        data = _get_json(f"https://forex-data-feed.swissquote.com/public-quotes/bboquotes/instrument/{symbol}/USD")
        quote = data[0]["spreadProfilePrices"][0]
        return (float(quote["bid"]) + float(quote["ask"])) / 2


def _fetch() -> tuple[dict, bool]:
    """Се манбаъ ба таври параллелӣ."""
    jobs = {
        "xau": lambda: _metal_price("XAU"),
        "xag": lambda: _metal_price("XAG"),
        "tjs": lambda: float(_get_json("https://open.er-api.com/v6/latest/USD")["rates"]["TJS"]),
    }
    values, live = dict(FALLBACK), True
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = {k: pool.submit(fn) for k, fn in jobs.items()}
        for key, fut in futures.items():
            try:
                values[key] = fut.result()
            except Exception:
                live = False
    return values, live


def build_quote(xau: float, xag: float, tjs: float, live: bool) -> dict:
    gram_999 = xau / TROY_OUNCE_G * tjs
    silver_gram = xag / TROY_OUNCE_G * tjs
    gold = {str(p): round(gram_999 * p / 1000, 2) for p in (999, 958, 916, 875, 750, 585, 583, 500, 375)}
    silver = {str(p): round(silver_gram * p / 1000, 2) for p in (999, 925, 875)}
    return {
        "usd_per_oz": round(xau, 2),
        "silver_usd_per_oz": round(xag, 2),
        "tjs_per_usd": round(tjs, 4),
        "gold_per_gram": gold,
        "silver_per_gram": silver,
        "live": live,
        "updated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }


_refreshing = threading.Event()


def _refresh() -> None:
    try:
        values, live = _fetch()
        with _lock:
            prev = _cache["data"]
            if not live and prev and prev.get("live"):
                # Интернет қатъ шуд — охирин нархи зиндаро нигоҳ медорем.
                _cache["at"] = time.time()
                return
            _cache.update(at=time.time(), data=build_quote(values["xau"], values["xag"], values["tjs"], live))
    finally:
        _refreshing.clear()


def refresh_async() -> threading.Thread | None:
    """Навсозӣ дар фон; агар аллакай равон бошад — ҳеҷ."""
    if _refreshing.is_set():
        return None
    _refreshing.set()
    thread = threading.Thread(target=_refresh, daemon=True)
    thread.start()
    return thread


def get_quote(wait: float = 8.0) -> dict:
    """Ҳеҷ гоҳ дароз интизор намешавад: кеш → нархи кӯҳна + навсозӣ дар фон → нархи захиравӣ."""
    with _lock:
        data, at = _cache["data"], _cache["at"]
    if data and time.time() - at < CACHE_SECONDS:
        return data
    thread = refresh_async()
    if data:
        return data
    if thread:
        thread.join(wait)
    with _lock:
        if _cache["data"]:
            return _cache["data"]
    return build_quote(FALLBACK["xau"], FALLBACK["xag"], FALLBACK["tjs"], live=False)


def metal_value(quote: dict, metal: str, proba: int | None, weight: float | None) -> float | None:
    """Арзиши тахминии металл аз рӯи вазн (бе кор ва санг)."""
    if not proba or not weight:
        return None
    if metal in ("gold", "white_gold", "rose_gold"):
        per_999 = quote["gold_per_gram"]["999"]
    elif metal == "silver":
        per_999 = quote["silver_per_gram"]["999"]
    else:
        return None
    return round(per_999 * proba / 1000 * weight, 2)
