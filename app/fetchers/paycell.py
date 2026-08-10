"""Paycell (Turkcell dijital cüzdan) kampanya fetcher'ı.

Paycell sitesi bir Next.js SPA'sı — kampanyalar HTML'de değil, arkadaki
JSON API'den geliyor: /be/api/getCampaigns. Bu API sade bir GET ile (çerez/
auth gerektirmeden) tüm aktif kampanyaları yapılandırılmış JSON döndürür;
başlık, açıklama, başlangıç/bitiş tarihi, sektör ve görsel hazır gelir —
HTML ayıklamaya gerek yok. Yalnız HERKESE AÇIK kampanyalar alınır
(isSegmented=True olanlar kişiye özeldir, uygulamada "bende çıkmıyor"
şikâyetine yol açar; alınmaz). Süresi bitenler (isFinished=True) de atlanır.
"""

import requests
from bs4 import BeautifulSoup

API_URL = "https://paycell.com.tr/be/api/getCampaigns?limit=200&page=1"
DETAIL_BASE = "https://paycell.com.tr/kampanyalar/"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
    ),
    "Accept": "application/json",
}


def _strip_html(html):
    if not html:
        return ""
    text = BeautifulSoup(html, "html.parser").get_text(" ", strip=True)
    return " ".join(text.split())


def fetch_paycell():
    response = requests.get(API_URL, headers=HEADERS, timeout=25)
    response.raise_for_status()
    campaigns = (response.json() or {}).get("campaigns", [])

    items = []
    for campaign in campaigns:
        # Yalnız herkese açık + aktif kampanyalar.
        if campaign.get("isFinished") or campaign.get("isSegmented"):
            continue

        title = (campaign.get("name") or "").strip()
        campaign_id = campaign.get("id")
        if not title or not campaign_id:
            continue

        slug = campaign.get("slug") or ""
        detail_url = DETAIL_BASE + slug if slug else "https://paycell.com.tr/kampanyalar"
        summary = " ".join((campaign.get("description") or "").split())
        conditions = _strip_html(campaign.get("content"))

        items.append(
            {
                "provider_type": "cuzdan",
                "bank": "Paycell",
                "bank_label": "Paycell",
                "external_id": campaign_id,
                "title": title,
                # Kısa açıklama hem gösterim hem ödül/kategori tespiti için.
                "description": summary or conditions[:320],
                "summary": summary or None,
                "conditions": conditions or None,
                "image_url": campaign.get("campaignUrl"),
                "url": detail_url,
                "source_url": detail_url,
                # Tarihler API'den hazır ISO (YYYY-MM-DD) gelir — regex gerekmez.
                "valid_from": campaign.get("startDate"),
                "valid_to": campaign.get("endDate"),
            }
        )

    return items
