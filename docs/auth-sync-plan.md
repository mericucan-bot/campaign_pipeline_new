# Kullanici Hesabi ve Senkron Plani

## Amac

Uygulama ilk asamada misafir kullanimi destekler. Kullanici giris yaptiginda yerel veriler Supabase kullanici profilindeki verilerle senkronlanir. Bu sayede iOS, ileride Android ve web ayni kullanici verisini okuyabilir.

## Supabase tablolari

`supabase_user_schema.sql` su tablolari ekler:

- `profiles`: kullanici profili ve plan bilgisi.
- `user_cards`: kullanicinin sahip oldugu banka/kart secimleri.
- `user_favorites`: kullanicinin favori kampanyalari.
- `campaign_participations`: katildim, harcadim, kazandim takip verileri.
- `subscription_events`: App Store, Google Play veya ileride web odeme olaylarinin denetim kaydi.

Kampanya iliskileri `campaigns.id` alanina UUID olarak baglanir. Bu, mevcut Supabase kampanya tablosuyla ve ileride Android/web istemcileriyle ortak veri modeli saglar.

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
   - `campaign_participations.reward_expires_at` ve `reminder_enabled` alanlari puan son kullanim hatirlaticilari icin saklanir.
   - Sonraki acilislarda bulut verisi okunur.
   - Ilk iOS senkron servisi eklendi: giris sonrasi ve Hesap ekranindaki manuel senkron butonuyla yerel veriler buluta yazilir, buluttaki veriler cihazla birlestirilir.
4. Kullanici cikis yaparsa:
   - Bulut verisi korunur.
   - Cihazdaki misafir verisi ayrica tutulabilir veya temizlenebilir.

## Giris yontemleri

- Apple ile giris: iOS yayin icin gerekli olabilir.
- Google ile giris: iOS ve Android icin ortak hesap akisi.
- E-posta ile giris: basit yedek giris yontemi.

## Ucretli uyelik hazirligi

- `profiles.plan` ilk asamada `free` olarak tutulur.
- `profiles.plan`, `plan_status`, `trial_ends_at` ve `premium_until` alanlari ucretsiz, deneme ve premium durumlarini temsil eder.
- Ucretsiz planda sinirli takip; premium planda sinirsiz hatirlatici, gelismis kazanc raporu ve kisisel oneriler acilir.
- iOS uygulamasinda merkezi entitlement katmani eklendi: Free planda 1 aktif puan hatirlaticisi, Trial/Premium planda sinirsiz hatirlatici kuralı uygulanir.
- App Store ve Google Play abonelik durumlari backend tarafinda dogrulanip profile yazilmalidir.
- Odeme olaylari `subscription_events` tablosuna yazilir; mobil uygulama bu tabloya dogrudan yazmaz, sadece kendi kayitlarini okuyabilir.
