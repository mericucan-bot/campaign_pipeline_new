# Abonelik ve Odeme Kurulum Plani

Bu plan Premium uyeligi App Store'a hazirlamak icindir. Amac odeme ekranini aceleyle acmak degil; once urun ID'leri, hak kurallari, App Store Connect kurulumu ve Supabase senkron modelini netlestirmek.

## 1. Strateji Karari

Ilk iOS surumunde uygulama StoreKit 2 ile App Store urunlerini okuyabilecek sekilde hazirlanir. Android hedefi oldugu icin nihai abonelik dogrulama katmani RevenueCat veya benzeri platformlar arasi bir servisle uyumlu tutulur.

Pratik karar:

- iOS uygulamasinda StoreKit hazirlik servisi korunur.
- Urun ID'leri App Store Connect ile birebir ayni kalir.
- Supabase profilindeki `plan`, `plan_status`, `trial_ends_at`, `premium_until` alanlari uygulamanin merkezi plan kaynagi olur.
- Mobil uygulama sadece satin alma akisini baslatir ve sonucu gosterir.
- Kalici premium yetkisi backend/RevenueCat/App Store dogrulamasindan sonra profile yazilir.

## 2. App Store Connect Urunleri

Planlanan urun ID'leri:

- `com.mericucan.KampanyaRadari.premium.monthly`
- `com.mericucan.KampanyaRadari.premium.yearly`

Onerilen App Store Connect yapisi:

- Subscription Group: `Kampanya Radarı Premium`
- Monthly Product:
  - Product ID: `com.mericucan.KampanyaRadari.premium.monthly`
  - Display Name: `Aylık Premium`
  - Description: `Sınırsız hatırlatıcı, reklamsız kullanım ve gelişmiş kampanya takibi.`
- Yearly Product:
  - Product ID: `com.mericucan.KampanyaRadari.premium.yearly`
  - Display Name: `Yıllık Premium`
  - Description: `Aylık plana göre daha avantajlı Premium kullanım.`

Fiyatlar henuz kesinlestirilmedi. Ilk test icin fiyat seviyesi App Store Connect sandbox/test ortaminda belirlenecek; canli fiyat yayin oncesi tekrar karar verilecek.

## 3. Free ve Premium Haklari

Free plan:

- Kampanya listeleme
- Arama
- Banka/kategori filtreleme
- Kartlarim filtresi
- Favoriler
- Katildim / harcadim / kazandim temel takibi
- 1 aktif puan harcama hatirlaticisi
- Ileride reklamli deneyim

Premium plan:

- Free plandaki her sey
- Sinirsiz aktif puan harcama hatirlaticisi
- Reklamsiz deneyim
- Gelismis kazanc raporlari
- Gecmis takip arsivi
- Kisisel kart/kampanya onerileri
- Ileride Android ile hesap bazli senkron

## 4. Uygulama Icinde Mevcut Hazirlik

Mevcut iOS kodunda:

- `PremiumProductID` aylik/yillik urun ID'lerini tutar.
- `PremiumPurchaseService` StoreKit urunlerini yuklemeye hazirdir.
- Urunler App Store Connect'te acilmadigi surece satin alma baslatilmaz.
- `EntitlementService` Free planda 1 aktif hatirlatici, Premium/Trial planda sinirsiz hatirlatici kuralini uygular.
- `UserProfileService` Supabase profilinden etkili plan durumunu okur.

## 5. Supabase ve Backend Modeli

Mobil uygulama service role key kullanmayacak.

Plan durumu su sekilde tutulur:

- `profiles.plan`: `free`, `trial`, `premium`
- `profiles.plan_status`: `active`, `expired`, `canceled`, `grace_period` gibi durumlar icin genisletilebilir
- `profiles.trial_ends_at`: deneme bitis tarihi
- `profiles.premium_until`: premium bitis tarihi
- `subscription_events`: odeme/dogrulama olaylarinin denetim kaydi

Kalici abonelik yetkisi icin dogru akil:

1. Kullanici App Store'dan satin alir.
2. Satin alma sonucu Apple/RevenueCat tarafinda dogrulanir.
3. Backend veya RevenueCat webhook Supabase profilini gunceller.
4. Uygulama profil bilgisini okuyup Premium haklari acar.

## 6. App Store Connect Kontrol Listesi

Detayli tiklama rehberi: `docs/app-store-connect-guide.md`

- Bundle ID App Store Connect'te acildi.
- Paid Apps Agreements / vergi / banka bilgileri tamamlandi.
- Subscription Group olusturuldu.
- Monthly ve Yearly urun ID'leri eklendi.
- Yerellestirilmis ad/aciklamalar girildi.
- Fiyatlar secildi.
- Sandbox test kullanicisi hazirlandi.
- TestFlight build yuklendi.
- Premium ekraninda urunler gercek App Store fiyatiyla gorundu.
- Satin alma, iptal, geri yukleme ve yenileme senaryolari test edildi.

## 7. RevenueCat Karari

RevenueCat su durumda avantajli olur:

- Android yayinina gecilecegi zaman.
- App Store ve Google Play abonelik durumunu tek panelde izlemek istedigimizde.
- Webhook ile Supabase profilini otomatik guncellemek istedigimizde.
- Iptal, grace period, refund ve yenileme olaylarini tek yerden takip etmek istedigimizde.

Ilk canli surumde iki yol var:

- Yol A: Dogrudan StoreKit 2 ile basla, iOS'u hizli test et.
- Yol B: RevenueCat'i bastan bagla, Android ve uzun vadeli abonelik yonetimini daha rahat kur.

Onerilen yol: Android hedefi net oldugu icin RevenueCat'e hazir mimariyi koru; App Store Connect urunleri acildiktan sonra RevenueCat baglantisini degerlendir.

## 8. Aktivasyon Sirasi

1. App Store Connect'te uygulama kaydi ve abonelik urunlerini ac.
2. TestFlight build yukle.
3. StoreKit urunlerinin uygulamada gorundugunu dogrula.
4. Sandbox satin alma testi yap.
5. Supabase profil guncelleme yolunu sec: manuel test, backend endpoint veya RevenueCat webhook.
6. Premium haklarinin hesaba bagli kalici acildigini dogrula.
7. Geri yukleme ve iptal senaryolarini test et.
8. Canli surumde satin alma butonunu aktif et.
