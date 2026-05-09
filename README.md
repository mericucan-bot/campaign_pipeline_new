# Campaign Pipeline

Turkiye'deki banka kampanyalarini tarayan ve dashboard'da gosteren yerel uygulama.

## Tek tik calistirma

Windows'ta `run_dashboard.bat` dosyasina cift tiklayin.

Mac'te Terminal'i proje klasorunde acip su komutu calistirin:

```bash
./run_dashboard.sh
```

Bu dosya:

- `.env` yoksa `.env.example` dosyasindan olusturur
- `.venv` sanal ortamini kurar
- Python paketlerini yukler
- dashboard'u `http://127.0.0.1:5050` adresinde acar

Supabase bilgisi girilmezse veriler yerel SQLite veritabanina yazilir:

`data/campaigns.db`

Supabase kullanmak isterseniz `supabase_schema.sql` dosyasindaki tabloyu Supabase SQL editor'de calistirin ve `.env` icine proje URL/key bilgilerinizi yazin.

Pipeline veriyi yazmak icin `SUPABASE_SERVICE_KEY` kullanir. Bu key gizlidir; telefona, web istemcisine veya repo'ya konmaz. iOS uygulama sadece okuma icin `SUPABASE_ANON_KEY` / publishable key kullanir.

```env
SUPABASE_URL=https://proje-ref.supabase.co
SUPABASE_SERVICE_KEY=service-role-veya-secret-key
SUPABASE_ANON_KEY=anon-veya-publishable-key
```

Public okuma testini calistirmak icin:

```bash
python -m app.check_public_read
```

## Sadece veri cekmek

`run_pipeline.bat` dosyasina cift tiklayin.

Mac'te:

```bash
./run_pipeline.sh
```

## Internete yayinlama: GitHub Actions + GitHub Pages

Bu repo artik statik dashboard olarak GitHub Pages'e yayinlanabilir.

Eklenen dosyalar:

- `.github/workflows/deploy-pages.yml`
- `app/static_export.py`
- `docs/index.html`
- `docs/assets/app.js`
- `docs/assets/styles.css`
- `docs/data/campaigns.json`

Workflow su islemleri yapar:

- 6 saatte bir otomatik calisir
- `python -m app.main` ile kampanyalari ceker
- `python -m app.static_export` ile `docs/data/campaigns.json` uretir
- Onceki `docs/data/campaigns.json` dosyasini okuyup artik yeni taramada gorunmeyen kampanyalari pasif isaretler
- Guncel `docs/data/campaigns.json` dosyasini repo'ya geri commit eder
- `docs/` klasorunu GitHub Pages'e deploy eder

GitHub'da gerekli ayar:

1. Repoyu GitHub'a push edin.
2. Repository `Settings > Pages` bolumune girin.
3. `Build and deployment > Source` alanini `GitHub Actions` yapin.
4. `Actions` sekmesinden `Deploy Kampanya Radar` workflow'unu elle calistirin.

Sonrasinda GitHub size su formda bir internet adresi verir:

`https://kullaniciadi.github.io/repo-adi/`

Not: GitHub Pages statik calisir. Bu nedenle internetteki versiyonda `Simdi Tara` butonu yoktur; veriler GitHub Actions calistikca guncellenir. Favoriler tarayici hafizasinda saklanir.

## Dashboard ozellikleri

- Benim Kartlarim filtresi: Axess, Maximum, Paraf, Paraf Premium, Vakif ve YKB kampanyalarini one cikarir.
- Banka tarama sagligi: banka bazli aktif/pasif sayisini ve son gorulme tarihini gosterir.
- Detay penceresi: kart icindeki bilgiyi dashboard'dan ayrilmadan okumayi saglar.
- Manuel favori kampanya: elle eklenen kampanyalari direkt favorilere alir.
- Sayfa basina don: uzun listelerde hizli yukari cikis saglar.
- Tekillestirme: ayni banka icinde ayni URL veya ayni basliga sahip tekrar eden kampanyalari gizler.
- Tarih etiketi: yakalanabilen tarihleri `Son katilim`, `Son X gun`, `Bugun bitiyor` formatinda gosterir.

### Telegram hata bildirimi

Workflow hata verirse Telegram mesaji gonderebilir. Basarili calismalarda mesaj atmaz.

GitHub repo icinde:

1. `Settings > Secrets and variables > Actions`
2. `New repository secret`
3. Su iki secret'i ekleyin:
   - `TELEGRAM_BOT_TOKEN`
   - `TELEGRAM_CHAT_ID`

Secret isimleri tam bu sekilde olmalidir. Token ve chat id dosyalara yazilmaz, sadece GitHub Secrets icinde saklanir.

## Elle calistirma

Mac:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m app.dashboard
```

Windows:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\activate
python -m pip install -r requirements.txt
python -m app.dashboard
```

Python 3.9 veya daha yeni surum yeterlidir.

## Docker ile calistirma

```powershell
docker-compose up --build
```

## Banka kaynaklari

Hazir kaynaklar:

- Paraf
- Paraf Premium (`https://www.paraf.com.tr/tr/kart-cesitleri/Paraf-Premium.html`)
- Akbank Axess (`https://www.axess.com.tr/axess/kampanya/8/393/kampanyalar`)
- Garanti BBVA Bonus
- Is Bankasi Maximum (`https://www.maximum.com.tr/kampanyalar`)
- Yapi Kredi World
- Ziraat Bankkart
- VakifBank (`https://www.vakifkart.com.tr/kampanyalar`)
- Kuveyt Turk Saglam Kart
- On Kart
- N Kolay
- Halkbank
- DenizBank Bonus
- QNB CardFinans
- TEB Bonus (`https://www.teb.com.tr/sizin-icin/kampanyalar/`)

Paraf JSON kaynagi kullanir. Diger bankalar resmi kampanya liste sayfalarindan genel HTML tarama ile okunur; banka siteleri tasarim degistirirse ilgili fetcher secicileri iyilestirilebilir.
