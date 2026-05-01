from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

from .generic import HEADERS, clean_text


def fetch_on_kart():
    url = "https://on.com.tr/kampanyalar"
    response = requests.get(url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    items = []
    for card in soup.select(".campaign-card"):
        item = card_item("On Kart", url, card)
        if item:
            items.append(item)
    return items


def fetch_bankkart():
    url = "https://www.bankkart.com.tr/kampanyalar"
    response = requests.get(url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    items = []
    for card in soup.select("section.col-md-3 .block"):
        item = card_item("Ziraat Bankkart", url, card)
        if item:
            item["title"] = item["title"].split(" Son Gün ")[0].strip()
            items.append(item)
    return items


def fetch_nkolay():
    url = "https://www.nkolay.com/kampanyalar"
    response = requests.get(url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    items = []
    seen = set()
    for link in soup.select('a[href*="kampanyalar/"]'):
        text = clean_text(link.get_text(" ", strip=True)).replace("Devamını oku", "").strip()
        if not text or "Sona Erdi" in text:
            continue
        href = link.get("href")
        full_url = urljoin(url, href)
        if full_url in seen:
            continue
        seen.add(full_url)
        items.append(
            {
                "bank": "N Kolay",
                "external_id": full_url,
                "title": text,
                "description": None,
                "image_url": first_image(url, link),
                "url": full_url,
            }
        )
    return items


def fetch_worldcard(max_pages=40):
    url = "https://www.worldcard.com.tr/api/campaigns"
    session = requests.Session()
    session.headers.update(
        {
            **HEADERS,
            "Accept": "application/json, text/javascript, */*; q=0.01",
            "Referer": "https://www.worldcard.com.tr/kampanyalar",
            "X-Requested-With": "XMLHttpRequest",
        }
    )

    items = []
    seen = set()
    for page in range(1, max_pages + 1):
        response = session.get(url, headers={"Page": str(page)}, timeout=(10, 60))
        response.raise_for_status()
        data = response.json()
        page_items = data.get("Items") or []
        if not page_items:
            break

        for item in page_items:
            detail_url = item.get("Url")
            title = clean_text(item.get("Title") or item.get("PageTitle") or item.get("SpotTitle"))
            if not detail_url or not title or detail_url in seen:
                continue
            seen.add(detail_url)
            image_url = item.get("ImageUrl")
            items.append(
                {
                    "bank": "Yapi Kredi World",
                    "external_id": detail_url,
                    "title": title,
                    "description": clean_text(item.get("DaysLeft") or ""),
                    "image_url": urljoin("https://www.worldcard.com.tr", image_url) if image_url else None,
                    "url": detail_url,
                }
            )

    return items


def fetch_kuveytturk():
    url = "https://www.kuveytturk.com.tr/kampanyalar/kendim-icin"
    response = requests.get(url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    items = []
    seen = set()
    for card in soup.select(".campaign-item"):
        item = card_item("Kuveyt Turk Saglam Kart", url, card)
        if not item or item["external_id"] in seen:
            continue
        seen.add(item["external_id"])
        items.append(item)
    return items


def fetch_teb_bonus():
    url = "https://www.teb.com.tr/sizin-icin/kampanyalar/"
    response = requests.get(url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    items = []
    seen = set()
    for link in soup.select(".kampanyaBoxContainer a[href]"):
        title = clean_text(link.get_text(" ", strip=True))
        if not title:
            continue
        href = link.get("href")
        full_url = urljoin(url, href)
        if full_url in seen:
            continue
        seen.add(full_url)
        items.append(
            {
                "bank": "TEB Bonus",
                "external_id": full_url,
                "title": title,
                "description": None,
                "image_url": first_image(url, link),
                "url": full_url,
            }
        )
    return items


def fetch_maximum():
    url = "https://www.maximum.com.tr/kampanyalar"
    response = requests.get(url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    items_by_url = {}
    category_slugs = {
        "seyahat-kampanyalari",
        "akaryakit-kampanyalari",
        "giyim-aksesuar-kampanyalari",
        "market-kampanyalari",
        "beyaz-esya-kampanyalari",
        "mobilya-dekorasyon-kampanyalari",
        "online-alisveris-ve-eticaret-kampanyalari",
        "arac-kiralama-kampanyalari",
        "bireysel",
        "ets-kampanyalari",
        "elektronik-kampanyalari",
        "egitim-kirtasiye-kampanyalari",
        "otomotiv-kampanyalari",
        "vergi-odemeleri",
        "maximum-mobil-kampanyalari",
        "diger-kampanyalar",
        "yeme-icme-restaurant-kampanyalari",
        "maximum-pati-kart-kampanyalari",
        "spor-kampanyalari",
        "bankamatik-kampanyalari",
    }
    for link in soup.select('a[href^="/kampanyalar/"]'):
        title = clean_text(link.get_text(" ", strip=True))
        href = link.get("href")
        slug = href.split("#", 1)[0].rstrip("/").rsplit("/", 1)[-1]
        if (
            not title
            or "#gecmis" in href
            or title == "Detaylı Bilgi"
            or "Geçmiş Kampanyalar" in title
            or slug in category_slugs
        ):
            continue
        full_url = urljoin(url, href)
        title = title.replace("Son 30 Gün", "").replace("Detaylı Bilgi", "").strip()
        candidate = {
            "bank": "Is Bankasi Maximum",
            "external_id": full_url,
            "title": title,
            "description": None,
            "image_url": first_image_near(url, link),
            "url": full_url,
        }
        current = items_by_url.get(full_url)
        if not current or len(candidate["title"]) < len(current["title"]):
            items_by_url[full_url] = candidate
    return list(items_by_url.values())


def card_item(bank, page_url, card):
    link = card.select_one("a[href]")
    if not link:
        return None

    title_el = card.select_one(".card-title, .title, h2, h3, h4, h5")
    title = clean_text(title_el.get_text(" ", strip=True) if title_el else card.get_text(" ", strip=True))
    title = title.replace("Detaylı Bilgi", "").replace("DETAYLAR", "").strip()
    if not title:
        return None

    href = link.get("href")
    full_url = urljoin(page_url, href)
    return {
        "bank": bank,
        "external_id": full_url,
        "title": title,
        "description": None,
        "image_url": first_image(page_url, card),
        "url": full_url,
    }


def first_image(page_url, element):
    source = element.select_one("source[srcset]")
    if source:
        srcset = source.get("srcset")
        if srcset:
            src = srcset.split(",", 1)[0].strip().split(" ", 1)[0]
            return urljoin(page_url, src)

    image = element.select_one("img")
    if not image:
        return None
    src = (
        image.get("data-src")
        or image.get("data-original")
        or image.get("data-lazy")
        or image.get("src")
    )
    if src and "transparent" in src:
        return None
    return urljoin(page_url, src) if src else None


def first_image_near(page_url, element, levels=6):
    current = element
    for _ in range(levels):
        if not current:
            break
        image_url = first_image(page_url, current)
        if image_url:
            return image_url
        current = current.parent
    return None
