import requests
from urllib.parse import urljoin
from bs4 import BeautifulSoup

from .generic import HEADERS, clean_text

def fetch_paraf():
    url = "https://www.paraf.com.tr/content/parafcard/tr/kampanyalar/_jcr_content/root/responsivegrid/filter.filtercampaigns.all.json"
    res = requests.get(url, headers=HEADERS, timeout=25)
    res.raise_for_status()
    data = res.json()

    items = []
    for x in data:
        page_url = "https://www.paraf.com.tr" + x["url"] if x["url"].startswith("/") else x["url"]
        image_url = x.get("teaserImage")
        items.append({
            "external_id": x["url"],
            "title": x["title"],
            "description": x.get("description"),
            "image_url": urljoin("https://www.paraf.com.tr", image_url) if image_url else None,
            "url": page_url,
        })

    return items


def fetch_paraf_premium():
    url = "https://www.paraf.com.tr/tr/kart-cesitleri/Paraf-Premium.html"
    response = requests.get(url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    items = []
    seen = set()
    for card in soup.select(".teaser--card-list-grid-item, .teaser--prop-list-grid-item"):
        title_el = card.select_one("h2")
        link = card.select_one("a[href]")
        image = card.select_one("img")
        if not title_el or not link:
            continue

        title = clean_text(title_el.get_text(" ", strip=True))
        href = link.get("href")
        detail_url = urljoin(url, href)
        if not title or detail_url in seen:
            continue

        description = clean_text(card.get_text(" ", strip=True))
        description = description.replace(title, "", 1).replace("Keşfet", "").strip()
        image_url = None
        if image:
            image_url = image.get("src") or image.get("data-src")

        seen.add(detail_url)
        items.append(
            {
                "bank": "Paraf Premium",
                "external_id": detail_url,
                "title": title,
                "description": description or None,
                "image_url": urljoin(url, image_url) if image_url else None,
                "url": detail_url,
            }
        )

    return items
