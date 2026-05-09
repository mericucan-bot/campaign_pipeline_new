from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

from .generic import HEADERS, clean_text, fetch_detail_summary


def fetch_axess(max_pages=30):
    base_url = "https://www.axess.com.tr/axess/kampanya/8/395/kampanyalar"
    ajax_url = "https://www.axess.com.tr/ajax/kampanya-ajax.aspx"
    session = requests.Session()
    session.headers.update(
        {
            **HEADERS,
            "Referer": base_url,
            "X-Requested-With": "XMLHttpRequest",
        }
    )

    items = []
    seen = set()
    for page in range(1, max_pages + 1):
        response = session.get(
            ajax_url,
            params={
                "checkBox": "[0]",
                "searchWord": '""',
                "page": str(page),
            },
            timeout=(10, 60),
        )
        response.raise_for_status()
        response.encoding = "utf-8"
        soup = BeautifulSoup(response.text, "html.parser")
        cards = soup.select(".grid-3")
        if not cards:
            break

        for card in cards:
            link = card.select_one('a[href*="/kampanyalar/"], a[href*="/kampanyadetay/"]')
            if not link:
                continue
            detail_url = urljoin(base_url, link.get("href"))
            if detail_url in seen:
                continue
            seen.add(detail_url)

            title = clean_text((card.select_one(".textArea p") or card).get_text(" ", strip=True))
            detail = fetch_axess_detail(session, detail_url)
            if detail.get("title"):
                title = detail["title"]
            if not title:
                continue

            items.append(
                {
                    "bank": "Akbank Axess",
                    "external_id": detail_url,
                    "title": title,
                    "description": detail.get("description"),
                    "image_url": detail.get("image_url") or first_image(base_url, card),
                    "url": detail_url,
                }
            )

        if len(cards) < 9:
            break

    return items


def fetch_axess_detail(session, url):
    try:
        response = session.get(url, timeout=(10, 60))
        response.raise_for_status()
        response.encoding = "utf-8"
    except requests.RequestException:
        return {}

    soup = BeautifulSoup(response.text, "html.parser")
    title_el = soup.select_one(".pageTitle") or soup.select_one("h2") or soup.select_one("title")
    title = clean_text(title_el.get_text(" ", strip=True) if title_el else "")
    title = title.replace("| Axess", "").strip()
    description = ""
    description_el = soup.select_one(".cmsContent, .campaignDetail, .detailText, .contentText")
    if description_el:
        first_paragraph = description_el.select_one("p")
        description = clean_text(
            first_paragraph.get_text(" ", strip=True)
            if first_paragraph
            else description_el.get_text(" ", strip=True)
        )

    image = None
    for img in soup.select("img"):
        src = img.get("src") or img.get("data-src")
        if src and "CmsCampaign" in src:
            image = urljoin(url, src)
            break

    return {
        "title": title,
        "description": description or None,
        "image_url": image,
    }


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
    base_url = "https://www.bankkart.com.tr/kampanyalar"
    response = requests.get(base_url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    category_urls = [base_url]
    for link in soup.select('a[href^="/kampanyalar/"]'):
        href = (link.get("href") or "").split("#", 1)[0].rstrip("/")
        parts = [part for part in href.split("/") if part]
        if len(parts) == 2:
            full_url = urljoin(base_url, href)
            if full_url not in category_urls:
                category_urls.append(full_url)

    items = []
    seen = set()
    for url in category_urls:
        page_soup = soup if url == base_url else BeautifulSoup(
            requests.get(url, headers=HEADERS, timeout=(10, 60)).text,
            "html.parser",
        )
        for card in page_soup.select("section.col-md-3 .block"):
            item = card_item("Ziraat Bankkart", url, card)
            if not item or item["external_id"] in seen:
                continue
            item["title"] = item["title"].split(" Son Gün ")[0].strip()
            seen.add(item["external_id"])
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
                "description": fetch_detail_summary(full_url),
                "image_url": first_image(url, link),
                "url": full_url,
            }
        )
    return items


def fetch_qnb_cardfinans():
    url = "https://www.qnbcard.com.tr/kampanyalar"
    response = requests.get(url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    items = []
    seen = set()
    for card in soup.select("#campaignBody .box-item"):
        link = card.select_one('a[href^="/kampanyalar/"]')
        title_el = card.select_one("figcaption")
        title = clean_text(title_el.get_text(" ", strip=True) if title_el else "")
        if not link or not title or title.lower() == "biten kampanyalar":
            continue

        detail_url = urljoin(url, link.get("href"))
        if "/biten-kampanyalar" in detail_url or detail_url in seen:
            continue

        seen.add(detail_url)
        items.append(
            {
                "bank": "QNB CardFinans",
                "external_id": detail_url,
                "title": title,
                "description": fetch_detail_summary(detail_url),
                "image_url": first_image(url, card),
                "url": detail_url,
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
            detail_url = urljoin("https://www.worldcard.com.tr", detail_url) if detail_url else None
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
                    "description": fetch_detail_summary(detail_url, session=session)
                    or clean_text(item.get("DaysLeft") or ""),
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
                "description": fetch_detail_summary(full_url),
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
            "description": fetch_detail_summary(full_url),
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
        "description": fetch_detail_summary(full_url),
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
