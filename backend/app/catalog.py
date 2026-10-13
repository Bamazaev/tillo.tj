"""Маълумоти доимӣ: категорияҳо, металлҳо, пробаҳо, сангҳо, шаҳрҳо."""

CATEGORIES = [
    {"slug": "rings", "name": "Ангуштарин"},
    {"slug": "earrings", "name": "Гӯшвора"},
    {"slug": "chains", "name": "Занҷир"},
    {"slug": "pendants", "name": "Овеза ва гарданбанд"},
    {"slug": "bracelets", "name": "Дастпона"},
    {"slug": "sets", "name": "Гарнитур"},
    {"slug": "wedding", "name": "Арӯсӣ"},
    {"slug": "watches", "name": "Соатҳо"},
    {"slug": "bullion", "name": "Хиштча ва танга"},
    {"slug": "gems", "name": "Сангҳои қиматбаҳо"},
    {"slug": "silver", "name": "Нуқра"},
    {"slug": "antique", "name": "Антиқа"},
]

METALS = [
    {"slug": "gold", "name": "Тиллои зард"},
    {"slug": "white_gold", "name": "Тиллои сафед"},
    {"slug": "rose_gold", "name": "Тиллои гулобӣ"},
    {"slug": "platinum", "name": "Платина"},
    {"slug": "silver", "name": "Нуқра"},
    {"slug": "none", "name": "Бе металл"},
]

GOLD_METALS = {"gold", "white_gold", "rose_gold"}

PROBAS = [375, 500, 583, 585, 750, 875, 916, 925, 950, 958, 999]

STONES = [
    {"slug": "none", "name": "Бе санг"},
    {"slug": "diamond", "name": "Бриллиант"},
    {"slug": "emerald", "name": "Зумуррад"},
    {"slug": "ruby", "name": "Ёқут"},
    {"slug": "sapphire", "name": "Сапфир"},
    {"slug": "spinel", "name": "Лаъли Бадахшон"},
    {"slug": "pearl", "name": "Марворид"},
    {"slug": "topaz", "name": "Топаз"},
    {"slug": "zirconia", "name": "Фианит"},
]

CONDITIONS = [
    {"slug": "new", "name": "Нав"},
    {"slug": "used", "name": "Истифодашуда"},
]

CITIES = [
    "Душанбе", "Хуҷанд", "Бохтар", "Кӯлоб", "Истаравшан", "Хоруғ",
    "Турсунзода", "Панҷакент", "Исфара", "Ваҳдат", "Ҳисор", "Конибодом",
]

SORTS = {
    "new": "l.featured DESC, l.created_at DESC, l.id DESC",
    "price_asc": "l.price ASC, l.id DESC",
    "price_desc": "l.price DESC, l.id DESC",
    "popular": "l.views DESC, l.id DESC",
}

CATEGORY_SLUGS = {c["slug"] for c in CATEGORIES}
METAL_SLUGS = {m["slug"] for m in METALS}
STONE_SLUGS = {s["slug"] for s in STONES}
CONDITION_SLUGS = {c["slug"] for c in CONDITIONS}
