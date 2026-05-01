import hashlib
import sqlite3
import unicodedata
from datetime import datetime

from supabase import create_client

from .config import DB_PATH, USE_SUPABASE, SUPABASE_KEY, SUPABASE_URL


supabase = create_client(SUPABASE_URL, SUPABASE_KEY) if USE_SUPABASE else None

EXCLUDED_BANKS = {"HSBC", "ING", "Odeabank", "DenizBank", "QNB Finansbank", "TEB", "Halkbank"}
EXCLUDED_URL_PARTS = ["yapikredi.com.tr"]


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
                external_id TEXT NOT NULL,
                title TEXT NOT NULL,
                description TEXT,
                image_url TEXT,
                url TEXT,
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
        conn.execute("CREATE INDEX IF NOT EXISTS idx_campaigns_bank ON campaigns(bank)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_campaigns_active ON campaigns(is_active)")
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS favorites (
                campaign_id INTEGER PRIMARY KEY,
                created_at TEXT NOT NULL
            )
            """
        )


def normalize_item(item):
    return {
        "bank": item["bank"],
        "external_id": item["external_id"],
        "title": item["title"],
        "description": item.get("description"),
        "image_url": item.get("image_url"),
        "url": item.get("url") or item.get("external_id"),
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
            return "INSERT"

        if existing["hash"] == item_hash:
            conn.execute(
                "UPDATE campaigns SET last_seen = ?, is_active = 1 WHERE id = ?",
                (timestamp, existing["id"]),
            )
            return "NO_CHANGE"

        conn.execute(
            """
            UPDATE campaigns
            SET title = ?, description = ?, image_url = ?, url = ?, hash = ?,
                version = ?, last_seen = ?, last_updated = ?, is_active = 1
            WHERE id = ?
            """,
            (
                clean_item["title"],
                clean_item["description"],
                clean_item["image_url"],
                clean_item["url"],
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
        supabase.table("campaigns").update({"last_seen": timestamp, "is_active": True}).eq(
            "id", db_item["id"]
        ).execute()
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
        return list_campaigns_supabase(bank=bank, search=search, active_only=active_only)
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
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if not unicodedata.combining(ch))
    return " ".join(value.split())
