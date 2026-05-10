# Yayina Hazirlik Master Plani

## 1. Urun cekirdegi

- Kampanya listeleme, arama, kategori/banka filtreleri ve siralama calisir durumda olmali.
- Favoriler, kartlarim ve kazanc takip ekranlari temel kullanici degerini olusturur.
- Kampanya detayinda kaynak, son tarih, katilim ve kazanc bilgileri net gosterilir.

## 2. Veri ve guvenlik

- Mobil uygulama sadece public read yetkisiyle kampanya okur.
- Scraper ve yazma islemleri service role key ile sadece backend/automation tarafinda calisir.
- RLS politikalari yayin oncesi tekrar denetlenir.
- Kullanici verileri icin ayri profil, kartlarim, favoriler ve katilim tablolari planlanir.

## 3. Hesap sistemi

- Supabase Auth ile e-posta, Apple ve Google girisi eklenir.
- Yerel kayitlar kullanici giris yaptiginda bulut profiline senkronlanir.
- Misafir kullanim korunur; kullanici kayit olmadan kampanya gezebilir.

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
