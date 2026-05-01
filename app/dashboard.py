import re
import unicodedata
from datetime import date

from flask import Flask, jsonify, redirect, render_template, request, url_for

from app.core.db import add_manual_campaign, get_favorite_ids, get_stats, list_campaigns, normalize_search, toggle_favorite
from app.core.pipeline import run_pipeline
from app.fetchers.registry import BANK_FETCHERS


app = Flask(__name__)

CATEGORIES = {
    "Market": ["market", "supermarket", "migros", "carrefour", "sok", "a101", "bim", "gida"],
    "Akaryakit": ["akaryakit", "yakit", "benzin", "petrol", "shell", "opet", "bp", "aytemiz", "total"],
    "Restoran": ["restoran", "yemek", "cafe", "kahve", "burger", "pizza", "getir", "yemeksepeti"],
    "Giyim": ["giyim", "moda", "ayakkabi", "tekstil", "lc waikiki", "boyner", "defacto"],
    "Seyahat": ["tatil", "otel", "ucak", "seyahat", "havalimani", "lounge", "yurt disi", "harc", "transfer"],
    "Online": ["online", "e-ticaret", "eticaret", "internet", "amazon", "trendyol", "hepsiburada", "n11"],
    "Elektronik": ["elektronik", "teknoloji", "telefon", "bilgisayar", "beyaz esya"],
    "Saglik": ["saglik", "eczane", "hastane", "medikal"],
}

REWARD_TYPES = {
    "Puan": ["puan", "parafpara", "bonus", "worldpuan", "chip-para", "maxipuan", "bankkart lira"],
    "Indirim": ["indirim", "%", "tl iade", "iade", "cashback"],
    "Taksit": ["taksit", "ertelemeli", "vade"],
    "Ayricalik": ["ucretsiz", "ayricalik", "lounge", "premium", "otopark", "prime"],
}

MONTHS = {
    "ocak": 1,
    "subat": 2,
    "mart": 3,
    "nisan": 4,
    "mayis": 5,
    "haziran": 6,
    "temmuz": 7,
    "agustos": 8,
    "eylul": 9,
    "ekim": 10,
    "kasim": 11,
    "aralik": 12,
}

BANK_LABELS = {
    "Akbank Axess": "Axess",
    "DenizBank Bonus": "DenizBank",
    "Garanti BBVA Bonus": "Garanti",
    "Is Bankasi Maximum": "Maximum",
    "Kuveyt Turk Saglam Kart": "Kuveyt",
    "N Kolay": "N Kolay",
    "On Kart": "On",
    "Paraf": "Paraf",
    "Paraf Premium": "Paraf Premium",
    "QNB CardFinans": "QNB",
    "TEB Bonus": "TEB",
    "VakifBank": "Vakif",
    "Yapi Kredi World": "YKB",
    "Ziraat Bankkart": "Ziraat",
    "Manuel Favori": "Manuel",
}


@app.get("/")
def index():
    bank = request.args.get("bank") or None
    search = request.args.get("q") or None
    active_only = request.args.get("active", "1") == "1"
    selected_category = request.args.get("category") or ""
    selected_reward = request.args.get("reward") or ""
    selected_sort = request.args.get("sort") or "updated"
    favorites_only = request.args.get("favorites") == "1"

    campaigns = list_campaigns(bank=bank, search=search, active_only=active_only)
    favorite_ids = get_favorite_ids()
    campaigns = enrich_campaigns(campaigns, favorite_ids)
    campaigns = apply_dashboard_filters(campaigns, selected_category, selected_reward, favorites_only)
    campaigns = sort_campaigns(campaigns, selected_sort)
    stats = get_stats()
    stats["favorites"] = len(favorite_ids)
    return render_template(
        "dashboard.html",
        campaigns=campaigns,
        stats=stats,
        selected_bank=bank or "",
        search=search or "",
        active_only=active_only,
        selected_category=selected_category,
        selected_reward=selected_reward,
        selected_sort=selected_sort,
        favorites_only=favorites_only,
        categories=sorted(CATEGORIES.keys()),
        reward_types=sorted(REWARD_TYPES.keys()),
        bank_label=bank_label,
    )


@app.get("/api/campaigns")
def api_campaigns():
    campaigns = list_campaigns(
        bank=request.args.get("bank") or None,
        search=request.args.get("q") or None,
        active_only=request.args.get("active") == "1",
    )
    favorite_ids = get_favorite_ids()
    campaigns = enrich_campaigns(campaigns, favorite_ids)
    return jsonify(campaigns)


@app.post("/favorite/<int:campaign_id>")
def favorite(campaign_id):
    is_favorite = toggle_favorite(campaign_id)
    if request.headers.get("accept") == "application/json":
        return jsonify({"id": campaign_id, "favorite": is_favorite})
    return redirect(request.referrer or url_for("index"))


@app.post("/manual")
def manual_campaign():
    title = (request.form.get("title") or "").strip()
    if title:
        add_manual_campaign(
            title=title,
            description=(request.form.get("description") or "").strip() or None,
            url=(request.form.get("url") or "").strip() or None,
            image_url=(request.form.get("image_url") or "").strip() or None,
        )
    return redirect(url_for("index", favorites="1"))


@app.post("/run")
def run_now():
    summaries = {}
    for bank_name, fetcher in BANK_FETCHERS.items():
        try:
            summaries[bank_name] = run_pipeline(fetcher, bank_name)
        except Exception as exc:
            summaries[bank_name] = {"error": str(exc)}

    if request.headers.get("accept") == "application/json":
        return jsonify(summaries)

    return redirect(url_for("index"))


def enrich_campaigns(campaigns, favorite_ids):
    enriched = []
    for campaign in campaigns:
        item = dict(campaign)
        haystack = normalize_search(" ".join([item.get("title") or "", item.get("description") or "", item.get("bank") or ""]))
        item["category"] = classify(haystack, CATEGORIES, "Genel")
        item["reward_type"] = classify(haystack, REWARD_TYPES, "Firsat")
        item["favorite"] = item.get("id") in favorite_ids
        item["brand_code"] = brand_code(item.get("bank") or "")
        item["deadline"] = extract_deadline(item)
        item["deadline_label"] = deadline_label(item["deadline"])
        item["deadline_urgent"] = is_deadline_urgent(item["deadline"])
        item["highlight"] = extract_highlight(item)
        enriched.append(item)
    return enriched


def bank_label(bank):
    return BANK_LABELS.get(bank, bank)


def apply_dashboard_filters(campaigns, category, reward, favorites_only):
    rows = campaigns
    if category:
        rows = [item for item in rows if item.get("category") == category]
    if reward:
        rows = [item for item in rows if item.get("reward_type") == reward]
    if favorites_only:
        rows = [item for item in rows if item.get("favorite")]
    return rows


def sort_campaigns(campaigns, selected_sort):
    if selected_sort == "deadline":
        return sorted(campaigns, key=lambda item: item.get("deadline") or date.max)
    if selected_sort == "gain":
        return sorted(campaigns, key=gain_score, reverse=True)
    if selected_sort == "bank":
        return sorted(campaigns, key=lambda item: ((item.get("bank") or ""), (item.get("title") or "")))
    return campaigns


def classify(haystack, groups, fallback):
    for label, needles in groups.items():
        if any(normalize_search(needle) in haystack for needle in needles):
            return label
    return fallback


def brand_code(bank):
    words = re.findall(r"[A-Za-z0-9]+", strip_accents(bank).upper())
    if not words:
        return "KR"
    if len(words) == 1:
        return words[0][:2]
    return "".join(word[0] for word in words[:2])


def strip_accents(value):
    normalized = unicodedata.normalize("NFKD", value or "")
    return "".join(ch for ch in normalized if not unicodedata.combining(ch))


def extract_deadline(item):
    text = " ".join([item.get("title") or "", item.get("description") or ""])
    normalized = normalize_search(text)
    today = date.today()
    candidates = []

    for day, month, year in re.findall(r"\b(\d{1,2})[./](\d{1,2})[./](20\d{2})\b", normalized):
        candidates.append(safe_date(int(year), int(month), int(day)))

    for day, month_name, year in re.findall(r"\b(\d{1,2})\s+([a-z]+)\s+(20\d{2})\b", normalized):
        month = MONTHS.get(month_name)
        if month:
            candidates.append(safe_date(int(year), month, int(day)))

    future = [item for item in candidates if item and item >= today]
    if future:
        return max(future)
    return max([item for item in candidates if item], default=None)


def safe_date(year, month, day):
    try:
        return date(year, month, day)
    except ValueError:
        return None


def deadline_label(deadline):
    if not deadline:
        return "Tarih kaynakta"
    days = (deadline - date.today()).days
    if days < 0:
        return "Suresi gecmis"
    if days == 0:
        return "Bugun bitiyor"
    if days <= 7:
        return f"Son {days} gun"
    return deadline.strftime("%d.%m.%Y")


def is_deadline_urgent(deadline):
    if not deadline:
        return False
    days = (deadline - date.today()).days
    return 0 <= days <= 2


def extract_highlight(item):
    text = " ".join([item.get("title") or "", item.get("description") or ""])
    compact = " ".join(text.split())
    patterns = [
        r"%\s?\d{1,2}\s?(?:indirim|iade)",
        r"\d{2,5}\s?TL\s?(?:chip-?para|parafpara|bonus|worldpuan|maxipuan|puan|iade|indirim)",
        r"\d{1,2}\s?(?:taksit|ay taksit)",
        r"(?:ücretsiz|ucretsiz)\s+[A-Za-zÇĞİÖŞÜçğıöşü0-9\s]{3,28}",
    ]
    for pattern in patterns:
        match = re.search(pattern, compact, flags=re.IGNORECASE)
        if match:
            return match.group(0).strip(" .,-")
    return ""


def gain_score(item):
    text = normalize_search(" ".join([item.get("title") or "", item.get("description") or ""]))
    numbers = [int(match) for match in re.findall(r"\b\d{2,5}\b", text)]
    return max(numbers, default=0)


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5050, debug=False)
