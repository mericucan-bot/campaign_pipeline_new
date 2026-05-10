# Kullanici Hesabi ve Senkron Plani

## Amac

Uygulama ilk asamada misafir kullanimi destekler. Kullanici giris yaptiginda yerel veriler Supabase kullanici profilindeki verilerle senkronlanir. Bu sayede iOS, ileride Android ve web ayni kullanici verisini okuyabilir.

## Supabase tablolari

`supabase_user_schema.sql` su tablolari ekler:

- `profiles`: kullanici profili ve plan bilgisi.
- `user_cards`: kullanicinin sahip oldugu banka/kart secimleri.
- `user_favorites`: kullanicinin favori kampanyalari.
- `campaign_participations`: katildim, harcadim, kazandim takip verileri.

## Guvenlik modeli

- `campaigns` herkes tarafindan sadece okunur.
- Kullanici tablolari sadece `auth.uid()` ile kendi satirlarini okur/yazar.
- Scraper ve pipeline yazma islemleri mobil uygulamadan ayridir.
- Service role key sadece backend, local pipeline veya GitHub Actions tarafinda kullanilir.

## Mobil senkron akisi

1. Uygulama misafir modda acilir.
2. Favoriler, kartlarim ve kazanc takibi cihazda tutulur.
3. Kullanici giris yaparsa:
   - Supabase oturumu acilir.
   - Yerel `Kartlarim`, favoriler ve katilim verileri kullanici tablolarina yazilir.
   - Sonraki acilislarda bulut verisi okunur.
4. Kullanici cikis yaparsa:
   - Bulut verisi korunur.
   - Cihazdaki misafir verisi ayrica tutulabilir veya temizlenebilir.

## Giris yontemleri

- Apple ile giris: iOS yayin icin gerekli olabilir.
- Google ile giris: iOS ve Android icin ortak hesap akisi.
- E-posta ile giris: basit yedek giris yontemi.

## Ucretli uyelik hazirligi

- `profiles.plan` ilk asamada `free` olarak tutulur.
- Ileride `free`, `premium`, `trial` gibi degerler kullanilabilir.
- App Store ve Google Play abonelik durumlari backend tarafinda dogrulanip profile yazilmalidir.
