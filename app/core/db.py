import hashlib
import re
import sqlite3
import unicodedata
from datetime import date, datetime

from supabase import create_client

from .config import DB_PATH, USE_SUPABASE, SUPABASE_KEY, SUPABASE_URL


supabase = create_client(SUPABASE_URL, SUPABASE_KEY) if USE_SUPABASE else None

EXCLUDED_BANKS = {"HSBC", "ING", "Odeabank", "DenizBank", "QNB Finansbank", "TEB", "Halkbank"}
EXCLUDED_URL_PARTS = ["yapikredi.com.tr"]

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

CATEGORIES = {
    "Market": ["market", "supermarket", "migros", "carrefour", "sok", "a101", "bim", "gida"],
    "Akaryakit": ["akaryakit", "yakit", "benzin", "petrol", "shell", "opet", "bp", "aytemiz", "total"],
    "Restoran": ["restoran", "yemek", "cafe", "kahve", "burger", "pizza", "getir", "yemeksepeti"],
    "Giyim": ["giyim", "moda", "ayakkabi", "tekstil", "lc waikiki", "boyner", "defacto"],
    "Seyahat": ["tatil", "otel", "ucak", "seyahat", "havalimani", "lounge", "yurt disi", "yurtdisi", "harc"],
    "Online": ["online", "e-ticaret", "eticaret", "internet", "amazon", "trendyol", "hepsiburada", "n11"],
    "Elektronik": ["elektronik", "teknoloji", "telefon", "bilgisayar", "beyaz esya"],
    "Saglik": ["saglik", "eczane", "hastane", "medikal"],
    "Aidat/Harc": ["aidat", "harc", "vergi", "mtv"],
    "Premium": ["premium", "lounge", "otopark", "prime", "ayricalik"],
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


def now_iso():
    return datetime.utcnow().isoformat()


def generate_hash(item):
    raw = "|".join(
        [
            item.get("title") or "",
            item.get("description") or "",
            item.get("image_url") or "",
            item.get("url") or "",
        ]
    )
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def get_connection():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_local_db():
    with get_connection() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS campaigns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                bank TEXT NOT NULL,
                bank_label TEXT,
                external_id TEXT NOT NULL,
                title TEXT NOT NULL,
                summary TEXT,
                description TEXT,
                conditions TEXT,
                image_url TEXT,
                url TEXT,
                source_url TEXT,
                category TEXT,
                reward_type TEXT,
                reward_value REAL,
                valid_from TEXT,
                valid_to TEXT,
                opportunity_score INTEGER,
                hash TEXT NOT NULL,
                version INTEGER NOT NULL DEFAULT 1,
                first_seen TEXT NOT NULL,
                last_seen TEXT NOT NULL,
                last_updated TEXT NOT NULL,
                is_active INTEGER NOT NULL DEFAULT 1,
                UNIQUE(bank, external_id)
            )
            """
        )
        ensure_local_columns(conn)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_campaigns_bank ON campaigns(bank)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_campaigns_active ON campaigns(is_active)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_campaigns_valid_to ON campaigns(valid_to)")
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS favorites (
                campaign_id INTEGER PRIMARY KEY,
                created_at TEXT NOT NULL
            )
            """
        )


def ensure_local_columns(conn):
    existing = {row["name"] for row in conn.execute("PRAGMA table_info(campaigns)").fetchall()}
    columns = {
        "bank_label": "TEXT",
        "summary": "TEXT",
        "conditions": "TEXT",
        "source_url": "TEXT",
        "category": "TEXT",
        "reward_type": "TEXT",
        "reward_value": "REAL",
        "valid_from": "TEXT",
        "valid_to": "TEXT",
        "opportunity_score": "INTEGER",
    }
    for name, column_type in columns.items():
        if name not in existing:
            conn.execute(f"ALTER TABLE campaigns ADD COLUMN {name} {column_type}")


def normalize_item(item):
    bank = item["bank"]
    description = item.get("description")
    text = " ".join([item.get("title") or "", description or ""])
    category = item.get("category") or classify_category(text)
    reward_type, reward_value = detect_reward(text)
    valid_to = item.get("valid_to") or extract_deadline(text)
    source_url = item.get("source_url") or item.get("url") or item.get("external_id")
    summary = item.get("summary") or build_summary(description)

    return {
        "bank_label": item.get("bank_label") or BANK_LABELS.get(bank, bank),
        "bank": item["bank"],
        "external_id": item["external_id"],
        "title": item["title"],
        "summary": summary,
        "description": item.get("description"),
        "conditions": item.get("conditions"),
        "image_url": item.get("image_url"),
        "url": item.get("url") or item.get("external_id"),
        "source_url": source_url,
        "category": category,
        "reward_type": item.get("reward_type") or reward_type,
        "reward_value": item.get("reward_value") or reward_value,
        "valid_from": item.get("valid_from"),
        "valid_to": valid_to,
        "opportunity_score": item.get("opportunity_score") or calculate_opportunity_score(
            text,
            reward_type,
            reward_value,
            valid_to,
        ),
    }


def upsert_campaign(item):
    return upsert_supabase(item) if USE_SUPABASE else upsert_local(item)


def upsert_local(item):
    init_local_db()
    clean_item = normalize_item(item)
    item_hash = generate_hash(clean_item)
    timestamp = now_iso()

    with get_connection() as conn:
        existing = conn.execute(
            "SELECT * FROM campaigns WHERE bank = ? AND external_id = ?",
            (clean_item["bank"], clean_item["external_id"]),
        ).fetchone()

        if not existing:
            conn.execute(
                """
                INSERT INTO campaigns (
                    bank, bank_label, external_id, title, summary, description, conditions,
                    image_url, url, source_url, category, reward_type, reward_value,
                    valid_from, valid_to, opportunity_score, hash, version,
                    first_seen, last_seen, last_updated, is_active
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, 1)
                """,
                (
                    clean_item["bank"],
                    clean_item["bank_label"],
                    clean_item["external_id"],
                    clean_item["title"],
                    clean_item["summary"],
                    clean_item["description"],
                    clean_item["conditions"],
                    clean_item["image_url"],
                    clean_item["url"],
                    clean_item["source_url"],
                    clean_item["category"],
                    clean_item["reward_type"],
                    clean_item["reward_value"],
                    clean_item["valid_from"] or timestamp,
                    clean_item["valid_to"],
                    clean_item["opportunity_score"],
                    item_hash,
                    timestamp,
                    timestamp,
                    timestamp,
                ),
            )
            return "INSERT"

        if existing["hash"] == item_hash:
            conn.execute(
                """
                UPDATE campaigns
                SET bank_label = ?, summary = ?, conditions = ?, source_url = ?,
                    category = ?, reward_type = ?, reward_value = ?,
                    valid_from = COALESCE(valid_from, ?), valid_to = ?,
                    opportunity_score = ?, last_seen = ?, is_active = 1
                WHERE id = ?
                """,
                (
                    clean_item["bank_label"],
                    clean_item["summary"],
                    clean_item["conditions"],
                    clean_item["source_url"],
                    clean_item["category"],
                    clean_item["reward_type"],
                    clean_item["reward_value"],
                    clean_item["valid_from"] or existing["first_seen"],
                    clean_item["valid_to"],
                    clean_item["opportunity_score"],
                    timestamp,
                    existing["id"],
                ),
            )
            return "NO_CHANGE"

        conn.execute(
            """
            UPDATE campaigns
            SET bank_label = ?, title = ?, summary = ?, description = ?, conditions = ?,
                image_url = ?, url = ?, source_url = ?, category = ?, reward_type = ?,
                reward_value = ?, valid_from = COALESCE(valid_from, ?), valid_to = ?,
                opportunity_score = ?, hash = ?, version = ?, last_seen = ?,
                last_updated = ?, is_active = 1
            WHERE id = ?
            """,
            (
                clean_item["bank_label"],
                clean_item["title"],
                clean_item["summary"],
                clean_item["description"],
                clean_item["conditions"],
                clean_item["image_url"],
                clean_item["url"],
                clean_item["source_url"],
                clean_item["category"],
                clean_item["reward_type"],
                clean_item["reward_value"],
                clean_item["valid_from"] or existing["first_seen"],
                clean_item["valid_to"],
                clean_item["opportunity_score"],
                item_hash,
                existing["version"] + 1,
                timestamp,
                timestamp,
                existing["id"],
            ),
        )
        return "UPDATED"


def upsert_supabase(item):
    clean_item = normalize_item(item)
    item_hash = generate_hash(clean_item)
    existing = (
        supabase.table("campaigns")
        .select("*")
        .eq("bank", clean_item["bank"])
        .eq("external_id", clean_item["external_id"])
        .execute()
    )

    timestamp = now_iso()

    if not existing.data:
        insert_data = {
            **clean_item,
            "hash": item_hash,
            "version": 1,
            "first_seen": timestamp,
            "last_seen": timestamp,
            "last_updated": timestamp,
            "is_active": True,
        }

        supabase.table("campaigns").insert(insert_data).execute()
        return "INSERT"

    db_item = existing.data[0]

    if db_item["hash"] == item_hash:
        supabase.table("campaigns").update(
            {
                "bank_label": clean_item["bank_label"],
                "summary": clean_item["summary"],
                "conditions": clean_item["conditions"],
                "source_url": clean_item["source_url"],
                "category": clean_item["category"],
                "reward_type": clean_item["reward_type"],
                "reward_value": clean_item["reward_value"],
                "valid_from": clean_item["valid_from"] or db_item.get("first_seen"),
                "valid_to": clean_item["valid_to"],
                "opportunity_score": clean_item["opportunity_score"],
                "last_seen": timestamp,
                "is_active": True,
            }
        ).eq("id", db_item["id"]).execute()
        return "NO_CHANGE"

    supabase.table("campaigns").update(
        {
            **clean_item,
            "hash": item_hash,
            "version": db_item["version"] + 1,
            "last_seen": timestamp,
            "last_updated": timestamp,
            "is_active": True,
        }
    ).eq("id", db_item["id"]).execute()

    return "UPDATED"


def mark_inactive(bank, active_external_ids):
    return mark_inactive_supabase(bank, active_external_ids) if USE_SUPABASE else mark_inactive_local(bank, active_external_ids)


def mark_inactive_local(bank, active_external_ids):
    init_local_db()
    timestamp = now_iso()
    active_set = set(active_external_ids)

    with get_connection() as conn:
        rows = conn.execute("SELECT id, external_id FROM campaigns WHERE bank = ?", (bank,)).fetchall()
        for row in rows:
            if row["external_id"] not in active_set:
                conn.execute(
                    "UPDATE campaigns SET is_active = 0, last_seen = ? WHERE id = ?",
                    (timestamp, row["id"]),
                )


def mark_inactive_supabase(bank, active_external_ids):
    existing = supabase.table("campaigns").select("id, external_id").eq("bank", bank).execute()
    timestamp = now_iso()
    active_set = set(active_external_ids)

    for row in existing.data:
        if row["external_id"] not in active_set:
            supabase.table("campaigns").update({"is_active": False, "last_seen": timestamp}).eq(
                "id", row["id"]
            ).execute()


def list_campaigns(bank=None, search=None, active_only=False):
    if USE_SUPABASE:
        try:
            return list_campaigns_supabase(bank=bank, search=search, active_only=active_only)
        except Exception as exc:
            print(f"Supabase list failed, falling back to local SQLite: {exc}")
            return list_campaigns_local(bank=bank, search=search, active_only=active_only)
    return list_campaigns_local(bank=bank, search=search, active_only=active_only)


def list_campaigns_local(bank=None, search=None, active_only=False):
    init_local_db()
    query = "SELECT * FROM campaigns WHERE 1 = 1"
    params = []

    if EXCLUDED_BANKS:
        placeholders = ",".join("?" for _ in EXCLUDED_BANKS)
        query += f" AND bank NOT IN ({placeholders})"
        params.extend(sorted(EXCLUDED_BANKS))
    for url_part in EXCLUDED_URL_PARTS:
        query += " AND COALESCE(url, '') NOT LIKE ? AND COALESCE(external_id, '') NOT LIKE ?"
        params.extend([f"%{url_part}%", f"%{url_part}%"])
    if active_only:
        query += " AND is_active = 1"
    if bank:
        query += " AND bank = ?"
        params.append(bank)
    query += " ORDER BY is_active DESC, last_seen DESC, title ASC"

    with get_connection() as conn:
        rows = [dict(row) for row in conn.execute(query, params).fetchall()]

    if search:
        needle = normalize_search(search)
        rows = [
            row
            for row in rows
            if needle
            in normalize_search(
                " ".join(
                    [
                        row.get("title") or "",
                        row.get("description") or "",
                        row.get("bank") or "",
                    ]
                )
            )
        ]

    return rows


def list_campaigns_supabase(bank=None, search=None, active_only=False):
    query = supabase.table("campaigns").select("*").order("last_seen", desc=True)
    if active_only:
        query = query.eq("is_active", True)
    if bank:
        query = query.eq("bank", bank)
    result = query.execute()
    data = [
        row
        for row in (result.data or [])
        if row.get("bank") not in EXCLUDED_BANKS
        and not any(part in (row.get("url") or row.get("external_id") or "") for part in EXCLUDED_URL_PARTS)
    ]

    if search:
        needle = normalize_search(search)
        data = [
            row
            for row in data
            if needle
            in normalize_search(
                " ".join(
                    [
                        row.get("title") or "",
                        row.get("description") or "",
                        row.get("bank") or "",
                    ]
                )
            )
        ]
    return data


def get_stats():
    campaigns = list_campaigns()
    active = [item for item in campaigns if bool(item.get("is_active"))]
    banks = sorted({item["bank"] for item in campaigns})
    return {
        "total": len(campaigns),
        "active": len(active),
        "inactive": len(campaigns) - len(active),
        "banks": banks,
        "bank_count": len(banks),
        "storage": "Supabase" if USE_SUPABASE else "Local SQLite",
    }


def get_favorite_ids():
    if USE_SUPABASE:
        return set()

    init_local_db()
    with get_connection() as conn:
        return {row["campaign_id"] for row in conn.execute("SELECT campaign_id FROM favorites").fetchall()}


def toggle_favorite(campaign_id):
    if USE_SUPABASE:
        return False

    init_local_db()
    with get_connection() as conn:
        existing = conn.execute(
            "SELECT campaign_id FROM favorites WHERE campaign_id = ?",
            (campaign_id,),
        ).fetchone()
        if existing:
            conn.execute("DELETE FROM favorites WHERE campaign_id = ?", (campaign_id,))
            return False

        conn.execute(
            "INSERT INTO favorites (campaign_id, created_at) VALUES (?, ?)",
            (campaign_id, now_iso()),
        )
        return True


def add_manual_campaign(title, description=None, url=None, image_url=None, bank="Manuel Favori"):
    if USE_SUPABASE:
        raise RuntimeError("Manual campaign entry is only supported with local SQLite for now.")

    init_local_db()
    clean_item = {
        "bank": bank,
        "external_id": "manual-" + hashlib.sha256(
            "|".join([title or "", description or "", url or "", image_url or ""]).encode("utf-8")
        ).hexdigest()[:20],
        "title": title,
        "description": description,
        "image_url": image_url,
        "url": url,
    }
    item_hash = generate_hash(clean_item)
    timestamp = now_iso()

    with get_connection() as conn:
        existing = conn.execute(
            "SELECT id FROM campaigns WHERE bank = ? AND external_id = ?",
            (clean_item["bank"], clean_item["external_id"]),
        ).fetchone()
        if existing:
            campaign_id = existing["id"]
            conn.execute(
                """
                UPDATE campaigns
                SET title = ?, description = ?, image_url = ?, url = ?, hash = ?,
                    last_seen = ?, last_updated = ?, is_active = 1
                WHERE id = ?
                """,
                (
                    clean_item["title"],
                    clean_item["description"],
                    clean_item["image_url"],
                    clean_item["url"],
                    item_hash,
                    timestamp,
                    timestamp,
                    campaign_id,
                ),
            )
        else:
            cursor = conn.execute(
                """
                INSERT INTO campaigns (
                    bank, external_id, title, description, image_url, url, hash,
                    version, first_seen, last_seen, last_updated, is_active
                ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, 1)
                """,
                (
                    clean_item["bank"],
                    clean_item["external_id"],
                    clean_item["title"],
                    clean_item["description"],
                    clean_item["image_url"],
                    clean_item["url"],
                    item_hash,
                    timestamp,
                    timestamp,
                    timestamp,
                ),
            )
            campaign_id = cursor.lastrowid

        conn.execute(
            "INSERT OR IGNORE INTO favorites (campaign_id, created_at) VALUES (?, ?)",
            (campaign_id, timestamp),
        )
        return campaign_id


def normalize_search(value):
    value = (value or "").casefold()
    value = value.replace("ı", "i").replace("ğ", "g").replace("ü", "u")
    value = value.replace("ş", "s").replace("ö", "o").replace("ç", "c")
    value = value.replace("yurtdisi", "yurt disi").replace("yurtdışı", "yurt disi")
    value = value.replace("ı", "i").replace("ğ", "g").replace("ü", "u")
    value = value.replace("ş", "s").replace("ö", "o").replace("ç", "c")
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    return " ".join(value.split())


def build_summary(description, max_chars=320):
    summary = " ".join((description or "").split())
    if len(summary) <= max_chars:
        return summary or None
    return summary[:max_chars].rsplit(" ", 1)[0].rstrip(" .,;") + "..."


def classify_category(text):
    haystack = normalize_search(text)
    for label, keywords in CATEGORIES.items():
        if any(normalize_search(keyword) in haystack for keyword in keywords):
            return label
    return "Genel"


def detect_reward(text):
    normalized = normalize_search(text)
    money = re.search(r"\b(\d{2,5})\s*(?:tl|₺)\s*(?:chip|para|parafpara|bonus|worldpuan|maxipuan|puan|iade|indirim)?", normalized)
    percent = re.search(r"%\s?(\d{1,2}(?:[.,]\d+)?)", text)
    installment = re.search(r"\b(\d{1,2})\s*(?:taksit|ay)\b", normalized)

    if installment:
        return "Taksit", float(installment.group(1))
    if percent:
        return "Indirim", float(percent.group(1).replace(",", "."))
    if "puan" in normalized or "bonus" in normalized or "chip" in normalized:
        return "Puan", float(money.group(1)) if money else None
    if money:
        return "Indirim", float(money.group(1))
    return "Firsat", None


def extract_deadline(text):
    normalized = normalize_search(text)
    candidates = []
    current_year = date.today().year

    for day, month, year in re.findall(r"\b(\d{1,2})[./](\d{1,2})[./](20\d{2})\b", normalized):
        candidates.append(safe_date(int(year), int(month), int(day)))

    for day, month_name, year in re.findall(r"\b(\d{1,2})\s+([a-z]+)\s+(20\d{2})\b", normalized):
        month = MONTHS.get(month_name)
        if month:
            candidates.append(safe_date(int(year), month, int(day)))

    for day, month_name in re.findall(r"\b(\d{1,2})\s+([a-z]+)(?:\s+tarihine|\s+arasında|\s+arası|\s+sonuna)?\b", normalized):
        month = MONTHS.get(month_name)
        if month:
            candidates.append(safe_date(current_year, month, int(day)))

    valid = [item for item in candidates if item]
    if not valid:
        return None
    future = [item for item in valid if item >= date.today()]
    return max(future or valid).isoformat()


def safe_date(year, month, day):
    try:
        return date(year, month, day)
    except ValueError:
        return None


def calculate_opportunity_score(text, reward_type, reward_value, valid_to):
    score = 40
    normalized = normalize_search(text)
    if reward_value:
        score += min(30, int(float(reward_value) // 100) if reward_type != "Taksit" else int(float(reward_value) * 3))
    if any(keyword in normalized for keyword in ["market", "akaryakit", "restoran", "online", "seyahat"]):
        score += 10
    if valid_to:
        try:
            days_left = (date.fromisoformat(valid_to) - date.today()).days
            if 0 <= days_left <= 7:
                score += 10
        except ValueError:
            pass
    return max(0, min(score, 100))
