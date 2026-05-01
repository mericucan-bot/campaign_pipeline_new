from .cards import fetch_bankkart, fetch_kuveytturk, fetch_maximum, fetch_nkolay, fetch_on_kart, fetch_teb_bonus, fetch_worldcard
from .generic import fetch_campaign_listing
from .paraf import fetch_paraf, fetch_paraf_premium
from .vakifkart import fetch_vakifkart


BANK_SOURCES = [
    {
        "name": "akbank",
        "url": "https://www.axess.com.tr/axess/kampanya/8/393/kampanyalar",
        "display": "Akbank Axess",
    },
    {
        "name": "garanti",
        "url": "https://www.bonus.com.tr/kampanyalar",
        "display": "Garanti BBVA Bonus",
    },
    {
        "name": "denizbank",
        "url": "https://www.denizbonus.com/bonus-kampanyalari",
        "display": "DenizBank Bonus",
    },
    {
        "name": "qnb",
        "url": "https://www.qnbcard.com.tr/kampanyalar",
        "display": "QNB CardFinans",
    },
]


def _generic_fetcher(source):
    return lambda: fetch_campaign_listing(source["display"], source["url"])


BANK_FETCHERS = {
    "Paraf": fetch_paraf,
    "Paraf Premium": fetch_paraf_premium,
    "VakifBank": fetch_vakifkart,
    "Is Bankasi Maximum": fetch_maximum,
    "Ziraat Bankkart": fetch_bankkart,
    "On Kart": fetch_on_kart,
    "N Kolay": fetch_nkolay,
    "TEB Bonus": fetch_teb_bonus,
    "Yapi Kredi World": fetch_worldcard,
    "Kuveyt Turk Saglam Kart": fetch_kuveytturk,
}

for source in BANK_SOURCES:
    BANK_FETCHERS[source["display"]] = _generic_fetcher(source)
