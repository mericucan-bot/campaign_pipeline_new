from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

from .generic import HEADERS, clean_text, fetch_detail_summary


BASE_URL = "https://www.vakifkart.com.tr"


def fetch_vakifkart(max_pages=9):
    items = []
    seen = set()

    for page in range(1, max_pages + 1):
        url = f"{BASE_URL}/kampanyalar" if page == 1 else f"{BASE_URL}/kampanyalar/sayfa/{page}"
        print(f"VakifBank page {page}/{max_pages} taraniyor...")
        try:
            response = requests.get(url, headers=HEADERS, timeout=(10, 25))
            response.raise_for_status()
        except requests.RequestException as exc:
            print(f"VakifBank page {page} skipped: {exc}")
            break
        response.encoding = "utf-8"

        page_items = parse_campaigns(response.text, url)
        new_count = 0
        for item in page_items:
            if item["external_id"] in seen:
                continue
            seen.add(item["external_id"])
            items.append(item)
            new_count += 1

        print(f"VakifBank page {page}: {new_count} yeni kampanya")
        if new_count == 0:
            break

    return items


def parse_campaigns(html, page_url):
    soup = BeautifulSoup(html, "html.parser")
    cards = soup.select(".mainKampanyalarDesktop.subPage .list a.item")
    items = []

    for card in cards:
        href = card.get("href")
        title_el = card.select_one(".title span") or card.select_one(".title")
        image_el = card.select_one("img")
        title = clean_text(title_el.get_text(" ", strip=True) if title_el else card.get_text(" ", strip=True))

        if not href or not title:
            continue

        detail_url = urljoin(page_url, href)
        image_url = None
        if image_el:
            image_url = image_el.get("src") or image_el.get("data-src")

        items.append(
            {
                "bank": "VakifBank",
                "external_id": detail_url,
                "title": title,
                "description": fetch_detail_summary(detail_url),
                "image_url": urljoin(page_url, image_url) if image_url else None,
                "url": detail_url,
            }
        )

    return items
