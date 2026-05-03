from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup


HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    )
}


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
