import json
from datetime import date, datetime
from pathlib import Path

from app.core.db import is_current_or_undated, list_campaigns
from app.dashboard import build_bank_health, dedupe_campaigns, enrich_campaigns, bank_label


BASE_DIR = Path(__file__).resolve().parents[1]
DOCS_DIR = BASE_DIR / "docs"
DATA_DIR = DOCS_DIR / "data"


def serialize_campaign(item):
    row = dict(item)
    deadline = row.get("deadline")
    if isinstance(deadline, date):
        row["deadline"] = deadline.isoformat()
    else:
        row["deadline"] = None
    row["bank_label"] = bank_label(row.get("bank") or "")
    row["is_active"] = bool(row.get("is_active")) and is_current_or_undated(row)
    row["favorite"] = False
    return row


def campaign_key(item):
    return f"{item.get('bank') or ''}|{item.get('external_id') or item.get('url') or item.get('title') or ''}"


def load_previous_campaigns(output_path):
    if not output_path.exists():
        return []
    try:
        payload = json.loads(output_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []
    return payload.get("campaigns") or []


def merge_with_previous(current_campaigns, previous_campaigns):
    merged = []
    current_keys = set()

    for item in current_campaigns:
        current_keys.add(campaign_key(item))
        merged.append(item)

    for item in previous_campaigns:
        key = campaign_key(item)
        if key in current_keys:
            continue
        archived = dict(item)
        archived["is_active"] = False
        archived["deadline_urgent"] = False
        archived["deadline_label"] = archived.get("deadline_label") or "Pasif"
        merged.append(archived)

    return merged


def build_stats(campaigns):
    active = [item for item in campaigns if bool(item.get("is_active")) and is_current_or_undated(item)]
    banks = sorted({item["bank"] for item in campaigns if item.get("bank")})
    return {
        "total": len(campaigns),
        "active": len(active),
        "inactive": len(campaigns) - len(active),
        "banks": banks,
        "bank_count": len(banks),
        "storage": "GitHub Pages JSON",
    }


def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    output_path = DATA_DIR / "campaigns.json"
    previous_campaigns = load_previous_campaigns(output_path)
    current_campaigns = [
        serialize_campaign(item)
        for item in dedupe_campaigns(enrich_campaigns(list_campaigns(active_only=False), set()))
    ]
    campaigns = merge_with_previous(current_campaigns, previous_campaigns)
    payload = {
        "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "stats": build_stats(campaigns),
        "health": build_bank_health(campaigns),
        "campaigns": campaigns,
    }
    output_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Exported {len(payload['campaigns'])} campaigns to {output_path}")


if __name__ == "__main__":
    main()
