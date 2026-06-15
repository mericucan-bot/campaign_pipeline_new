from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup


HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    )
}

DETAIL_CACHE = {}


def fetch_campaign_listing(bank, url, selectors=None, limit=500):
    selectors = selectors or {}
    response = requests.get(url, headers=HEADERS, timeout=25)
    response.raise_for_status()
    response.encoding = "utf-8"

    soup = BeautifulSoup(response.text, "html.parser")
    card_selector = selectors.get("card")
    title_selector = selectors.get("title")
    desc_selector = selectors.get("description")

    cards = soup.select(card_selector) if card_selector else soup.select("a[href]")
    items = []
    seen = set()

    for card in cards:
        link = card if card.name == "a" else card.select_one("a[href]")
        if not link:
            continue

        href = link.get("href")
        full_url = urljoin(url, href)
        if full_url in seen:
            continue

        title_el = card.select_one(title_selector) if title_selector else None
        description_el = card.select_one(desc_selector) if desc_selector else None
        image_el = card.select_one("img")

        title = clean_text(title_el.get_text(" ", strip=True) if title_el else link.get_text(" ", strip=True))
        description = clean_text(description_el.get_text(" ", strip=True) if description_el else "")
        image_url = None
        if image_el:
            image_url = image_el.get("src") or image_el.get("data-src")

        if not looks_like_campaign(title, full_url):
            continue

        seen.add(full_url)
        if not description:
            description = fetch_detail_summary(full_url)
        items.append(
            {
                "bank": bank,
                "external_id": full_url,
                "title": title,
                "description": description or None,
                "image_url": urljoin(url, image_url) if image_url else None,
                "url": full_url,
            }
        )

        if len(items) >= limit:
            break

    return items


def fetch_detail_summary(url, session=None, selectors=None, max_chars=460):
    if not urlparse(url).scheme:
        return None
    if url in DETAIL_CACHE:
        return DETAIL_CACHE[url]

    client = session or requests
    selectors = selectors or [
        ".cmsContent",
        ".campaign-detail",
        ".campaignDetail",
        ".detailText",
        ".contentText",
        ".campaign-detail-content",
        ".kampanya-detay",
        ".kampanyaDetay",
        ".detail",
        "article",
        "main",
    ]

    try:
        response = client.get(url, headers=HEADERS, timeout=(8, 20))
        response.raise_for_status()
        response.encoding = "utf-8"
    except requests.RequestException:
        DETAIL_CACHE[url] = None
        return None

    soup = BeautifulSoup(response.text, "html.parser")
    for selector in selectors:
        container = soup.select_one(selector)
        if not container:
            continue
        summary = summarize_container(container, max_chars=max_chars)
        if summary:
            DETAIL_CACHE[url] = summary
            return summary

    for meta_selector in ('meta[property="og:description"]', 'meta[name="description"]'):
        meta = soup.select_one(meta_selector)
        summary = clean_text(meta.get("content") if meta else "")
        if summary:
            summary = truncate_text(summary, max_chars)
            DETAIL_CACHE[url] = summary
            return summary

    DETAIL_CACHE[url] = None
    return None


def summarize_container(container, max_chars=460):
    parts = []
    for element in container.select("p, li"):
        text = clean_text(element.get_text(" ", strip=True))
        if is_useful_detail_text(text):
            parts.append(text)
        if len(" ".join(parts)) >= max_chars:
            break

    if not parts:
        text = clean_text(container.get_text(" ", strip=True))
        return truncate_text(text, max_chars) if is_useful_detail_text(text) else None

    return truncate_text(" ".join(parts), max_chars)


def is_useful_detail_text(text):
    if not text or len(text) < 24:
        return False
    normalized = text.casefold()
    ignored = [
        "çerez",
        "cookie",
        "javascript",
        "menü",
        "arama",
        "detaylı bilgi",
        "hemen başvur",
        "internet şubesi",
        # Footer / yasal / navigasyon çöpü
        "tüm hakları saklıdır",
        "copyright",
        "site haritası",
        "gizlilik sözleşmesi",
        "gizlilik politikası",
        "kurumsal gizlilik",
        "çağrı merkezi",
        # Banka navigasyon menüleri
        "qnb xtra",
        "sanal kart qnb",
    ]
    return not any(item in normalized for item in ignored)


def fetch_og_description(url):
    """Detay sayfasının og:description/meta description metnini döndürür.

    Bazı bankalarda (ör. Garanti) sayfa gövdesi menü/footer ile dolu ama
    og:description temiz kampanya özetini (çoğu zaman tarih ve harcama eşiğiyle)
    içerir. Gömülü HTML etiketleri temizlenir; çöp metin reddedilir.
    """
    if not urlparse(url).scheme:
        return None
    try:
        response = requests.get(url, headers=HEADERS, timeout=(8, 25))
        response.raise_for_status()
        response.encoding = "utf-8"
    except requests.RequestException:
        return None

    soup = BeautifulSoup(response.text, "html.parser")
    for selector in ('meta[property="og:description"]', 'meta[name="description"]'):
        meta = soup.select_one(selector)
        raw = (meta.get("content") if meta else "") or ""
        if not raw:
            continue
        text = clean_text(BeautifulSoup(raw, "html.parser").get_text(" ", strip=True))
        if text and is_useful_detail_text(text):
            return text
    return None


def truncate_text(text, max_chars):
    text = clean_text(text)
    if len(text) <= max_chars:
        return text
    return text[:max_chars].rsplit(" ", 1)[0].rstrip(" .,;") + "..."


def clean_text(value):
    return " ".join((value or "").replace("\xa0", " ").split())


def looks_like_campaign(title, href):
    if not title or len(title) < 8:
        return False

    normalized_title = title.lower()
    ignored_titles = {"kampanyalar", "menuye git", "detayli bilgi", "detaylı bilgi"}
    if normalized_title in ignored_titles:
        return False

    path = urlparse(href).path.lower()
    if "kampanya" not in path and "campaign" not in path:
        return False

    haystack = f"{title} {href}".lower()
    keywords = [
        "kampanya",
        "campaign",
        "bonus",
        "chip",
        "puan",
        "worldpuan",
        "indirim",
        "taksit",
        "f\u0131rsat",
        "firsat",
    ]
    return any(keyword in haystack for keyword in keywords)
