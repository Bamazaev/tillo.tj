"""Барои ҳар эълони намунавӣ аз Wikimedia Commons сурати озод (PD/CC0) меҷӯяд.

python -m tools.find_photos candidates.json
"""
import json
import sys
import time
import urllib.parse
import urllib.request

API = "https://commons.wikimedia.org/w/api.php"
FREE = ("public domain", "cc0", "pd")


def search(query: str, limit: int = 30) -> list[dict]:
    params = {
        "action": "query", "format": "json", "generator": "search", "gsrsearch": f"{query} filetype:bitmap",
        "gsrnamespace": 6, "gsrlimit": limit, "prop": "imageinfo",
        "iiprop": "url|extmetadata|mime|size", "iiurlwidth": 900,
    }
    req = urllib.request.Request(f"{API}?{urllib.parse.urlencode(params)}", headers={"User-Agent": "tillo.tj/1.0 (demo photos)"})
    with urllib.request.urlopen(req, timeout=30) as r:
        pages = json.load(r).get("query", {}).get("pages", {}).values()
    out = []
    for p in sorted(pages, key=lambda p: p.get("index", 0)):
        ii = p["imageinfo"][0]
        lic = ii.get("extmetadata", {}).get("LicenseShortName", {}).get("value", "")
        if ii["mime"] != "image/jpeg" or not any(f in lic.lower() for f in FREE):
            continue
        w, h = ii["width"], ii["height"]
        if min(w, h) < 600 or max(w, h) / min(w, h) > 1.8:
            continue
        out.append({"title": p["title"], "thumb": ii["thumburl"], "page": ii["descriptionurl"], "license": lic})
    return out


if __name__ == "__main__":
    queries = json.load(open(sys.argv[1], encoding="utf-8"))
    try:
        result = json.load(open(sys.argv[2], encoding="utf-8"))
    except FileNotFoundError:
        result = {}
    for key, q in queries.items():
        if result.get(key):
            continue
        for attempt in range(4):
            try:
                result[key] = search(q)[:6]
                break
            except Exception as e:  # noqa: BLE001
                result[key] = []
                print(key, "ERR", e)
                time.sleep(10 * (attempt + 1))
        time.sleep(2)
        print(key, q, len(result[key]))
    json.dump(result, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
