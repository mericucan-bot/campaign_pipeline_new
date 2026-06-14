from pathlib import Path
import os

from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = BASE_DIR / "data"
DB_PATH = DATA_DIR / "campaigns.db"

load_dotenv(BASE_DIR / ".env")

SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
# Workflow ortama anahtarı SUPABASE_SERVICE_KEY adıyla veriyor; geriye dönük
# uyumluluk için SUPABASE_KEY de destekleniyor.
SUPABASE_KEY = (os.getenv("SUPABASE_SERVICE_KEY", "") or os.getenv("SUPABASE_KEY", "")).strip()
USE_SUPABASE = bool(SUPABASE_URL and SUPABASE_KEY)

