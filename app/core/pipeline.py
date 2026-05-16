from .db import mark_expired_inactive, mark_inactive, upsert_campaign

def run_pipeline(fetch_func, bank_name):
    data = fetch_func()
    active_ids = []
    active_bank = bank_name
    stats = {"inserted": 0, "updated": 0, "no_change": 0, "errors": 0}

    for item in data:
        try:
            item["bank"] = item.get("bank") or bank_name
            active_bank = item["bank"]
            result = upsert_campaign(item)
            print(item["title"], result)
            active_ids.append(item["external_id"])
            if result == "INSERT":
                stats["inserted"] += 1
            elif result == "UPDATED":
                stats["updated"] += 1
            else:
                stats["no_change"] += 1
        except Exception as exc:
            stats["errors"] += 1
            print(f"ERROR {item.get('title', 'unknown')}: {exc}")

    mark_inactive(active_bank, active_ids)
    mark_expired_inactive(active_bank)
    return stats
