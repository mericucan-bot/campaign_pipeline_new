import requests

from app.core.config import SUPABASE_ANON_KEY, SUPABASE_URL


def main():
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        raise SystemExit("SUPABASE_URL ve SUPABASE_ANON_KEY .env icinde olmali.")

    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/campaigns",
        params={
            "select": "id,bank,title,summary,category,reward_type,valid_to,opportunity_score",
            "is_active": "eq.true",
            "limit": "3",
        },
        headers={
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        },
        timeout=20,
    )
    print("status", response.status_code)
    response.raise_for_status()
    rows = response.json()
    print("rows", len(rows))
    for row in rows:
        print("-", row.get("bank"), row.get("title"))


if __name__ == "__main__":
    main()
