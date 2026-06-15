from .cards import fetch_axess, fetch_bankkart, fetch_garanti, fetch_kuveytturk, fetch_maximum, fetch_nkolay, fetch_on_kart, fetch_qnb_cardfinans, fetch_teb_bonus, fetch_worldcard
from .generic import fetch_campaign_listing
from .paraf import fetch_paraf, fetch_paraf_premium
from .vakifkart import fetch_vakifkart


BANK_SOURCES = [
    {
        "name": "denizbank",
        "url": "https://www.denizbonus.com/bonus-kampanyalari",
        "display": "DenizBank Bonus",
    },
]


def _generic_fetcher(source):
    return lambda: fetch_campaign_listing(source["display"], source["url"])


BANK_FETCHERS = {
    "Akbank Axess": fetch_axess,
    "Paraf": fetch_paraf,
    "Paraf Premium": fetch_paraf_premium,
    "VakifBank": fetch_vakifkart,
    "Is Bankasi Maximum": fetch_maximum,
    "Ziraat Bankkart": fetch_bankkart,
    "On Kart": fetch_on_kart,
    "N Kolay": fetch_nkolay,
    "TEB Bonus": fetch_teb_bonus,
    "QNB CardFinans": fetch_qnb_cardfinans,
    "Yapi Kredi World": fetch_worldcard,
    "Kuveyt Turk Saglam Kart": fetch_kuveytturk,
    "Garanti BBVA Bonus": fetch_garanti,
}

for source in BANK_SOURCES:
    BANK_FETCHERS[source["display"]] = _generic_fetcher(source)
