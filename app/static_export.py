import json
from datetime import date, datetime
from pathlib import Path

from app.core.db import get_stats, list_campaigns
from app.dashboard import enrich_campaigns, bank_label


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
    row["is_active"] = bool(row.get("is_active"))
    row["favorite"] = False
    return row


def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    campaigns = enrich_campaigns(list_campaigns(active_only=False), set())
    payload = {
        "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "stats": get_stats(),
        "campaigns": [serialize_campaign(item) for item in campaigns],
    }
    output_path = DATA_DIR / "campaigns.json"
    output_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Exported {len(payload['campaigns'])} campaigns to {output_path}")


if __name__ == "__main__":
    main()
