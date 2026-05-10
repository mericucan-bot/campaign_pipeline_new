# Yayina Hazirlik Master Plani

## 1. Urun cekirdegi

- Kampanya listeleme, arama, kategori/banka filtreleri ve siralama calisir durumda olmali.
- Favoriler, kartlarim ve kazanc takip ekranlari temel kullanici degerini olusturur.
- Kampanya detayinda kaynak, son tarih, katilim ve kazanc bilgileri net gosterilir.

### Urun yapılacaklar listesi

- Favorilere hızlı erişim ana sayfada ve liste içinde görünür olmalı; favoriler sadece filtre menüsünde saklı kalmamalı.
- Hesaplayıcı / kazanç takibi favori kampanyalar üzerinden `katıldım`, `harcadım`, `kazandım` akışıyla çalışmalı.
- Dashboard'daki hesaplayıcı mantığı mobilde `Kazançlarım` ekranına taşınmalı.
- Kampanya detay ekranında katılım şartları, son tarih, kazanım türü, banka, kaynak linki ve ana aksiyonlar okunabilir olmalı.
- Veri kalitesi tarafında süresi geçmiş kampanya, yanlış kategori, eksik tarih ve çok uzun açıklama sorunları takip edilmeli.
- VakıfBank ve Yapı Kredi gibi yavaş veya kırılgan scraper kaynakları ayrıca iyileştirilmeli.
- Banka renkleri, yazı karakterleri ve ileride kullanılacak logolar ayrı bir brand kit olarak düzenlenmeli.

## 2. Veri ve guvenlik

- Mobil uygulama sadece public read yetkisiyle kampanya okur.
- Scraper ve yazma islemleri service role key ile sadece backend/automation tarafinda calisir.
- RLS politikalari yayin oncesi tekrar denetlenir.
- Kullanici verileri icin ayri profil, kartlarim, favoriler ve katilim tablolari planlanir.
- `.env`, API key, RLS policy ve Supabase yetkileri App Store/TestFlight oncesi tekrar denetlenir.

## 3. Hesap sistemi

- Supabase Auth ile e-posta, Apple ve Google girisi eklenir.
- Yerel kayitlar kullanici giris yaptiginda bulut profiline senkronlanir.
- Misafir kullanim korunur; kullanici kayit olmadan kampanya gezebilir.
- Kullanici verisi icin `supabase_user_schema.sql` ve `docs/auth-sync-plan.md` temel alinir.

## 4. Gelir modeli

- Ucretsiz plan: reklamli deneyim, temel arama ve filtreler.
- Ucretli plan: reklamsiz deneyim, gelismis takip, kazanc raporlari, bildirimler ve kisisel kart onerileri.
- Abonelikler App Store ve Google Play kurallarina gore platform icinden yonetilir.

## 5. Platform stratejisi

- iOS ilk yayin platformu olur.
- Backend, Supabase semasi ve API mantigi Android ile ortak tutulur.
- Android basladiginda sifirdan veri modeli yazilmaz; ayni kampanya, kullanici ve takip katmanlari kullanilir.

## 6. Yayina hazirlik

- TestFlight ile kapali test yapilir.
- App Store ikon, ekran goruntuleri, gizlilik metni, destek adresi ve aciklama hazirlanir.
- Crash/log takibi, veri yenileme izleme ve temel analitik eklenir.
- Uygulama adi, ikon, splash/intro, bundle identifier ve Apple Developer hesabi yayin oncesi netlestirilir.
