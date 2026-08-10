"""Vodafone Pay (GSM dijital cüzdan) kampanya fetcher'ı.

Paycell'in aksine Vodafone Pay statik HTML sunar: /kampanyalar listesinde her
kampanya bir <a href="/kampanyalar/slug"> linkidir. Liste sayfasında başlık/
tarih yok, o yüzden her kampanyanın detay sayfasından og:title (başlık),
gövdeden kısa açıklama ve "…tarihine kadar geçerlidir" metninden bitiş tarihi
çıkarılır. Bankalardaki (Garanti/Maximum) detay-başına ayıklama pattern'iyle
aynıdır. Ödül tipi/kategori normalize_item içindeki detect_reward/
classify_category tarafından metinden belirlenir.
"""

import re

import requests
from bs4 import BeautifulSoup

BASE = "https://www.vodafonepay.com.tr"
LIST_URL = BASE + "/kampanyalar"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
    ),
}

_DATE_RE = re.compile(r"\b(\d{1,2})\.(\d{1,2})\.(20\d{2})\b")
# Liste/menü çöpü olan paragrafları ele (gerçek kampanya açıklaması değil).
_NAV_MARKERS = ("kampanyalar blog", "sıkça sorulan", "geri dön", "ürünler kampanyalar")


def _clean(text):
    return " ".join((text or "").split())


def _latest_end_date(text):
    """Metindeki tarihlerden bitiş tarihini seç: gelecekteki en ileri tarih
    (yoksa en ileri tarih). ISO (YYYY-MM-DD) döner."""
    from datetime import date

    dates = []
    for day, month, year in _DATE_RE.findall(text):
        try:
            dates.append(date(int(year), int(month), int(day)))
        except ValueError:
            continue
    if not dates:
        return None
    today = date.today()
    future = [d for d in dates if d >= today]
    return max(future or dates).isoformat()


# og:title'ın kampanyaya özel değil, sitenin genel başlığı geldiği sayfalar.
_GENERIC_TITLES = {"vodafone pay", "vodafone", "kampanyalar"}


def _parse_detail(session, url):
    response = session.get(url, headers=HEADERS, timeout=(8, 20))
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")

    og_title = soup.find("meta", attrs={"property": "og:title"})
    title = _clean(og_title["content"]) if og_title and og_title.get("content") else ""
    # " | ..." kuyruğunu (site sloganı/marka) at.
    title = title.split("|")[0].strip()

    og_image = soup.find("meta", attrs={"property": "og:image"})
    image = og_image["content"] if og_image and og_image.get("content") else None

    paragraphs = [_clean(p.get_text(" ", strip=True)) for p in soup.find_all("p")]
    paragraphs = [
        p for p in paragraphs
        if p and len(p) >= 25 and not any(m in p.casefold() for m in _NAV_MARKERS)
    ]

    # Özet: faydayı anlatan paragrafı (%, TL, iade geçen) tercih et; yoksa ilk
    # anlamlı paragraf.
    summary = ""
    for para in paragraphs:
        low = para.casefold()
        if "%" in para or " tl" in low or "iade" in low or "indirim" in low:
            summary = para
            break
    if not summary and paragraphs:
        summary = paragraphs[0]

    # og:title jenerikse başlığı özetten türet (ilk cümle).
    if not title or title.casefold() in _GENERIC_TITLES:
        first_sentence = re.split(r"[.!?]", summary, maxsplit=1)[0].strip()
        title = first_sentence[:80] or title

    # Tarih tüm sayfa metninden aranır (koşullar bazen <p> dışında).
    valid_to = _latest_end_date(soup.get_text(" ", strip=True))
    return title, summary, valid_to, image


def fetch_vodafonepay():
    session = requests.Session()
    response = session.get(LIST_URL, headers=HEADERS, timeout=25)
    response.raise_for_status()
    soup = BeautifulSoup(response.text, "html.parser")

    seen = set()
    items = []
    for anchor in soup.find_all("a", href=True):
        href = anchor["href"]
        if not href.startswith("/kampanyalar/"):
            continue
        slug = href.rstrip("/").rsplit("/", 1)[-1]
        if not slug or slug in seen:
            continue
        seen.add(slug)

        url = BASE + href
        try:
            title, summary, valid_to, image = _parse_detail(session, url)
        except requests.RequestException:
            continue
        if not title:
            continue

        items.append(
            {
                "provider_type": "cuzdan",
                "bank": "Vodafone Pay",
                "bank_label": "Vodafone Pay",
                "external_id": slug,
                "title": title,
                "description": summary or title,
                "summary": summary or None,
                "image_url": image,
                "url": url,
                "source_url": url,
                "valid_to": valid_to,
            }
        )

    return items
