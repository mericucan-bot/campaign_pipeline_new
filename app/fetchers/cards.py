import os
import re
from datetime import date
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

from .generic import HEADERS, clean_text, fetch_detail_summary, fetch_og_description


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
                "description": fetch_og_description(detail_url) or fetch_detail_summary(detail_url),
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
    # WAF 'tarpit' (veriyi damla damla göndererek) requests read-timeout'unu
    # atlatıyor; bu yüzden API çağrısını daemon thread'de MUTLAK süreyle sınırla.
    # Aşılırsa thread terk edilir (daemon -> process çıkışını bloklamaz) ve
    # aşağıdaki HTML fallback'e düşülür (listeleme sayfası CI'da tarpit yapmıyor).
    import threading

    result = {}

    def _run():
        try:
            result["items"] = fetch_kuveytturk_api()
        except Exception:
            result["items"] = None

    worker = threading.Thread(target=_run, daemon=True)
    worker.start()
    worker.join(timeout=20)
    if not worker.is_alive() and result.get("items"):
        return result["items"]

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


def fetch_kuveytturk_api(max_pages=8, page_size=24):
    # Kuveyt Türk tam listesi WAF korumalı bir JSON endpoint'inden geliyor.
    # Endpoint TLS/fingerprint'e değil IP'ye bakıyor: TR/residential IP -> 200,
    # datacenter/yurtdışı IP (GitHub Actions) -> bağlantı askıda kalıyor.
    # Sıkı timeout (5,15) + üst fonksiyondaki hata fallback'i ile pipeline ASLA
    # donmaz. KUVEYT_PROXY env tanımlıysa (TR residential proxy) istek oradan
    # geçer -> CI'da da tam liste (74) gelir; yoksa CI HTML fallback'e düşer.
    base_url = "https://www.kuveytturk.com.tr"
    listing_url = f"{base_url}/kampanyalar/kendim-icin"
    api_url = f"{base_url}/ck0d84?12078A5155AB8EB05557BBCAD58BCB84"
    session = requests.Session()
    session.headers.update(
        {
            **HEADERS,
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Referer": listing_url,
            "X-Bone-Language": "tr",
        }
    )
    proxy = os.environ.get("KUVEYT_PROXY")
    proxies = {"http": proxy, "https": proxy} if proxy else None

    items = []
    seen = set()
    for page in range(1, max_pages + 1):
        response = session.get(
            api_url,
            params={"p1": "56"},
            headers={"Page": str(page), "PageSize": str(page_size)},
            timeout=(5, 15),
            proxies=proxies,
        )
        response.raise_for_status()
        data = response.json()
        campaigns = data if isinstance(data, list) else []
        if not campaigns:
            break

        for campaign in campaigns:
            item = kuveytturk_api_item(base_url, campaign)
            if not item or item["external_id"] in seen:
                continue
            seen.add(item["external_id"])
            items.append(item)

        if len(campaigns) < page_size:
            break

    return items


def kuveytturk_api_item(base_url, campaign):
    title = clean_text(campaign.get("Title") or "")
    href = campaign.get("Url") or ""
    if not title or not href:
        return None

    detail_url = urljoin(base_url, href)
    image = campaign.get("Image") or {}
    image_url = image.get("LargeUrl") or image.get("Url")
    description = clean_text(
        BeautifulSoup(campaign.get("ShortDescription") or "", "html.parser").get_text(" ", strip=True)
    )
    return {
        "bank": "Kuveyt Turk Saglam Kart",
        "external_id": detail_url,
        "title": title,
        "description": description or None,
        "image_url": urljoin(base_url, image_url) if image_url else None,
        "url": detail_url,
        "valid_from": kuveytturk_iso_date(campaign.get("StartDate")),
        "valid_to": kuveytturk_iso_date(campaign.get("EndDate")),
    }


def kuveytturk_iso_date(value):
    if not value:
        return None
    match = re.match(r"(\d{4}-\d{2}-\d{2})", str(value))
    return match.group(1) if match else None


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


def fetch_garanti():
    """Garanti BBVA Bonus kampanyaları — özet og:description'dan alınır.

    bonus.com.tr detay sayfasının gövdesi menü/footer ile dolu; og:description
    ise kampanyanın tarih ve harcama eşiğini içeren temiz özetini taşır.
    """
    url = "https://www.bonus.com.tr/kampanyalar"
    response = requests.get(url, headers=HEADERS, timeout=(10, 60))
    response.raise_for_status()
    response.encoding = "utf-8"
    soup = BeautifulSoup(response.text, "html.parser")

    items = []
    seen = set()
    for card in soup.select("li.campaign-box"):
        link = card.select_one('a[href*="/kampanyalar/"]')
        if not link:
            continue
        href = link.get("href") or ""
        if not href or "/sektor/" in href or "/marka/" in href:
            continue
        full_url = urljoin(url, href)
        if full_url in seen:
            continue
        seen.add(full_url)

        title = clean_text(link.get_text(" ", strip=True))
        if not title:
            continue
        image = card.select_one("img")
        image_url = (image.get("src") or image.get("data-src")) if image else None

        items.append(
            {
                "bank": "Garanti BBVA Bonus",
                "external_id": full_url,
                "title": title,
                "description": fetch_og_description(full_url),
                "image_url": urljoin(url, image_url) if image_url else None,
                "url": full_url,
            }
        )

    return items


_TR_MONTHS_NUM = {
    1: "Ocak", 2: "Şubat", 3: "Mart", 4: "Nisan", 5: "Mayıs", 6: "Haziran",
    7: "Temmuz", 8: "Ağustos", 9: "Eylül", 10: "Ekim", 11: "Kasım", 12: "Aralık",
}
_MAX_DETAIL_CACHE = {}


def _iso_date(day, month, year):
    try:
        return date(int(year), int(month), int(day)).isoformat()
    except ValueError:
        return None


def _human_date(day, month, year):
    return f"{int(day)} {_TR_MONTHS_NUM.get(int(month), month)} {year}"


def _first_sentences(text, max_chars=200):
    text = (text or "").strip()
    if not text:
        return ""
    out = ""
    for sentence in re.split(r"(?<=[.!])\s+", text):
        sentence = sentence.strip()
        if not sentence:
            continue
        if out and len(out) + len(sentence) + 1 > max_chars:
            break
        out = (out + " " + sentence).strip()
        if len(out) >= max_chars:
            break
    if len(out) > max_chars:
        out = out[:max_chars].rsplit(" ", 1)[0].rstrip(" .,;") + "…"
    return out


def fetch_maximum_detail(url):
    """Maximum kampanya detay sayfasından açıklama, tarih aralığı ve standart özet çıkarır."""
    if url in _MAX_DETAIL_CACHE:
        return _MAX_DETAIL_CACHE[url]

    result = {"description": None, "summary": None, "valid_from": None, "valid_to": None}
    try:
        response = requests.get(url, headers=HEADERS, timeout=(8, 25))
        response.raise_for_status()
        response.encoding = "utf-8"
    except requests.RequestException:
        _MAX_DETAIL_CACHE[url] = result
        return result

    soup = BeautifulSoup(response.text, "html.parser")

    body_el = soup.select_one("div.campaign-detail-desc")
    if body_el:
        body = body_el.get_text(" ", strip=True)
    else:
        heading = soup.select_one("h1")
        body = heading.get_text(" ", strip=True) if heading else ""

    # Görünmez/boşluk karakterlerini normalize et
    body = re.sub(r"[​‌‍﻿\xa0]+", " ", body)
    body = clean_text(body)

    # Tarih aralığı: önce ayrı div.date, bulunmazsa gövdedeki "KAMPANYA TARİHLERİ : ..."
    date_label = ""
    date_el = soup.select_one("div.date")
    date_source = date_el.get_text(" ", strip=True) if date_el else body
    match = re.search(
        r"(\d{1,2})\.(\d{1,2})\.(\d{4})\s*[-–]\s*(\d{1,2})\.(\d{1,2})\.(\d{4})",
        date_source,
    )
    if match:
        result["valid_from"] = _iso_date(match.group(1), match.group(2), match.group(3))
        result["valid_to"] = _iso_date(match.group(4), match.group(5), match.group(6))
        date_label = (
            f"{_human_date(match.group(1), match.group(2), match.group(3))} – "
            f"{_human_date(match.group(4), match.group(5), match.group(6))}"
        )

    # Gövdeye sızan standart etiketleri temizle (tarih başlığı, "SON X GÜN", "Kampanya Ayrıntıları")
    body = re.sub(
        r"KAMPANYA\s+TARİHLERİ\s*:\s*\d{1,2}\.\d{1,2}\.\d{4}\s*[-–]\s*\d{1,2}\.\d{1,2}\.\d{4}",
        " ", body, flags=re.IGNORECASE,
    )
    body = re.sub(r"SON\s+\d+\s+GÜN", " ", body, flags=re.IGNORECASE)
    body = re.sub(r"Kampanya\s+(?:Ayrıntıları|Detayları)", " ", body, flags=re.IGNORECASE)
    body = re.sub(r"\s+", " ", body).strip()

    offer = _first_sentences(body, max_chars=200)
    if date_label and offer:
        # Başta tarihi zaten gösterdiğimiz için gövdedeki tekrar tarih ifadesini kırp
        offer = re.sub(
            r"^\d{1,2}\s*[-–]\s*\d{1,2}\s+\S+\s+\d{4}\s+tarihleri\s+arasında\s*",
            "",
            offer,
            flags=re.IGNORECASE,
        ).strip()
        offer = offer[:1].upper() + offer[1:] if offer else offer
        result["summary"] = f"{date_label} · {offer}"
    else:
        result["summary"] = offer or (date_label or None)
    result["description"] = body or None

    _MAX_DETAIL_CACHE[url] = result
    return result


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
        detail = fetch_maximum_detail(full_url)
        candidate = {
            "bank": "Is Bankasi Maximum",
            "external_id": full_url,
            "title": title,
            "description": detail["description"],
            "summary": detail["summary"],
            "valid_from": detail["valid_from"],
            "valid_to": detail["valid_to"],
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
