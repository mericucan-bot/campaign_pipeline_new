import sys

from app.core.pipeline import run_pipeline
from app.fetchers.registry import BANK_FETCHERS


if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")


def main():
    for bank_name, fetcher in BANK_FETCHERS.items():
        print(f"\n=== {bank_name} ===")
        try:
            stats = run_pipeline(fetcher, bank_name)
            print(stats)
        except Exception as exc:
            print(f"{bank_name} failed: {exc}")

if __name__ == "__main__":
    main()
