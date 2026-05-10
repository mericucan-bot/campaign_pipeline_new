# Yayina Hazirlik Master Plani

## 1. Urun cekirdegi

- Kampanya listeleme, arama, kategori/banka filtreleri ve siralama calisir durumda olmali.
- Favoriler, kartlarim ve kazanc takip ekranlari temel kullanici degerini olusturur.
- Kampanya detayinda kaynak, son tarih, katilim ve kazanc bilgileri net gosterilir.

### Urun yapılacaklar listesi

- Favorilere hızlı erişim ana sayfada ve liste içinde görünür olmalı; favoriler sadece filtre menüsünde saklı kalmamalı.
- Hesaplayıcı / kazanç takibi favori kampanyalar üzerinden `katıldım`, `harcadım`, `kazandım` akışıyla çalışmalı.
- Dashboard'daki hesaplayıcı mantığı mobilde `Kazançlarım` ekranına taşınmalı.
- Katıldım akışına puan/ödül son kullanım takibi eklenmeli; kullanıcı tutar ve son kullanım tarihi girince 7 gün, 3 gün ve son gün yerel bildirimleri planlanmalı. Temel iOS yerel bildirim akışı eklendi; yayın öncesi gerçek cihazda izin, saat ve tekrar senaryoları test edilecek.
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
- Ilk uygulama adiminda e-posta/sifre girisi Supabase Auth REST uclariyla baglanir; Google ve Apple girisi yayin ayarlariyla birlikte eklenir.
- Yerel kayitlar kullanici giris yaptiginda bulut profiline senkronlanir.
- Misafir kullanim korunur; kullanici kayit olmadan kampanya gezebilir.
- Kullanici verisi icin `supabase_user_schema.sql` ve `docs/auth-sync-plan.md` temel alinir.

## 4. Gelir modeli

- Ucretsiz plan: reklamli deneyim, temel arama ve filtreler.
- Ucretsiz plan: kullanici degeri gostermek icin sinirli takip sunar; 1 aktif kampanya hatirlaticisi, favoriler ve temel kartlarim filtresi acik kalir.
- Ucretli plan: reklamsiz deneyim, sinirsiz kampanya hatirlaticisi, 7/3/son gun coklu bildirimleri, gelismis kazanc raporlari, gecmis takip arsivi ve kisisel kart onerileri sunar.
- Odeme altyapisi gelmeden hatirlatici akisi merkezi entitlement katmanina baglanir; Free planda 1 aktif hatirlatici, Premium/Trial planda sinirsiz hatirlatici kurali uygulanir.
- Abonelikler App Store ve Google Play kurallarina gore platform icinden yonetilir.
- iOS abonelik icin ilk tercih RevenueCat veya dogrudan StoreKit 2 olur. RevenueCat, makbuz dogrulama, yenileme ve platformlar arasi abonelik durumunu kolaylastirdigi icin Android hedefi de dusunuldugunde degerlendirilir.
- iOS tarafinda aylik/yillik Premium urun ID'leri ve StoreKit odeme hazirlik servisi eklendi; App Store Connect urunleri tanimlanmadan gercek satin alma butonu aktif edilmeyecek.
- Apple komisyonu ve kucuk isletme programi yayin oncesi kontrol edilir; fiyatlandirma App Store Connect uzerinden tanimlanir.

## 5. Platform stratejisi

- iOS ilk yayin platformu olur.
- Backend, Supabase semasi ve API mantigi Android ile ortak tutulur.
- Android basladiginda sifirdan veri modeli yazilmaz; ayni kampanya, kullanici ve takip katmanlari kullanilir.

## 6. Yayina hazirlik

- TestFlight ile kapali test yapilir.
- App Store ikon, ekran goruntuleri, gizlilik metni, destek adresi ve aciklama hazirlanir.
- Crash/log takibi, veri yenileme izleme ve temel analitik eklenir.
- Uygulama adi, ikon, splash/intro, bundle identifier ve Apple Developer hesabi yayin oncesi netlestirilir.
- Privacy policy zorunludur. Politikada e-posta hesabi, favoriler/kartlarim/katilim verileri, bildirimler, Supabase kullanimi, ileride reklam/abonelik ve varsa analitik verileri aciklanir.
- App Store icin 1024x1024 PNG ikon, farkli cihaz ekran goruntuleri, destek URL'si, pazarlama metni ve uygulama gizlilik cevaplari hazirlanir.
- Onboarding ilk acilista 2-3 ekrani gecmeyecek sekilde tutulur: kampanya kesfi, kartlarim/kisisellestirme ve hatirlatici/kazanc takibi degeri anlatilir.
- iOS ilk acilis onboarding'i 3 deger ekranina ayrildi ve tamamlaninca tekrar zorunlu gosterilmeyecek sekilde saklanir.
- Gizlilik politikasi, destek sayfasi ve App Store hazirlik notlari icin taslak dokumanlar `docs/privacy-policy-draft.md`, `docs/support-page-draft.md` ve `docs/app-store-prep.md` olarak eklendi.
- App Store URL'leri icin webde acilabilir `docs/privacy.html` ve `docs/support.html` sayfalari eklendi; ana sayfa footer'ina baglantilari kondu.
- Apple Developer hesabi, bundle identifier, signing certificate/provisioning ve App Store Connect kaydi yayin oncesi tamamlanir.
- Yerel test sonrasi TestFlight ic test, sonra sinirli dis test, en son App Store incelemesi hedeflenir.
- Bu proje SwiftUI native iOS oldugu icin Expo/EAS yerine Xcode archive ve App Store Connect dagitim akisi kullanilir.

### Yayin sirasi

1. Supabase auth, RLS ve kullanici veri senkronunu tamamla.
2. Ucretsiz/premium limit kurallarini uygulama icinde merkezi bir entitlement katmanina bagla.
3. RevenueCat veya StoreKit 2 ile abonelik/paywall akisini ekle. StoreKit hazirlik katmani eklendi; siradaki canli adim App Store Connect'te urunleri acmak veya RevenueCat projesi baglamak.
4. Privacy policy, destek sayfasi, ikon, ekran goruntuleri ve onboarding metinlerini hazirla.
5. TestFlight ile gercek cihazda bildirim, hesap, senkron, abonelik ve veri yenileme testlerini yap.
6. App Store Connect uzerinden incelemeye gonder.
