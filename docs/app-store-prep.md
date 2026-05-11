# App Store Hazırlık Notları

## Uygulama Bilgileri

- Uygulama adı: Kampanya Radarı
- Bundle identifier: `com.mericucan.KampanyaRadari`
- İlk platform: iOS
- Dağıtım yolu: Xcode Archive -> App Store Connect -> TestFlight -> App Store Review

## App Store Connect'te Açılacak Alanlar

- Uygulama kaydı
- Bundle ID eşleşmesi
- Gizlilik politikası URL'si: `https://mericucan-bot.github.io/campaign_pipeline_new/privacy.html`
- Destek URL'si: `https://mericucan-bot.github.io/campaign_pipeline_new/support.html`
- Pazarlama URL'si, opsiyonel
- Kategori
- Yaş derecelendirmesi
- Uygulama gizliliği cevapları
- TestFlight iç test grubu
- Abonelik ürünleri
- Listeleme metinleri için kaynak: `docs/app-store-listing-draft.md`
- App Store ikon ve ekran görüntüsü planı için kaynak: `docs/app-store-assets.md`

## Planlanan Abonelik Ürünleri

- `com.mericucan.KampanyaRadari.premium.monthly`
- `com.mericucan.KampanyaRadari.premium.yearly`

Fiyatlar App Store Connect'te belirlenecek. Ürünler açılmadan iOS uygulamasındaki satın alma butonu aktif edilmeyecek.

## App Store Gizlilik Cevapları İçin Veri Kategorileri

- Contact Info: E-posta adresi, hesap için.
- User Content: Favoriler, Kartlarım, katılım/kazanç kayıtları.
- Purchases: Premium abonelik durumu.
- Identifiers: Supabase kullanıcı ID'si.
- Diagnostics/Usage Data: İleride analitik veya crash aracı eklenirse güncellenecek.

## İlk TestFlight Testleri

Detayli kontrol listesi: `docs/testflight-checklist.md`

- Yeni kurulum ve onboarding.
- Misafir olarak devam etme.
- E-posta ile kayıt ve giriş.
- Şifre sıfırlama deep link akışı.
- Favori, Kartlarım ve katılım kayıtlarının senkronu.
- Free planda 1 aktif hatırlatıcı limiti.
- Bildirim izni, 7 gün / 3 gün / son gün planlama.
- Premium ekranı ve App Store ürün bekleme durumu.
- Kampanya arama, banka/kategori filtreleme ve sıralama.
- Kaynak linklerinin açılması.

## Yayın Öncesi Açık Kararlar

- Destek e-posta adresi.
- GitHub Pages yayını açıldıktan sonra URL'lerin canlıda kontrol edilmesi.
- 1024x1024 App Store ikonunun final PNG dosyaları üretilecek ve `AppIcon.appiconset` içine bağlanacak.
- Ekran görüntüsü setleri `docs/app-store-assets.md` planına göre çekilecek.
- Abonelik fiyatları.
- RevenueCat mi doğrudan StoreKit 2 mi kullanılacağı.
- Google ve Apple ile girişin ilk sürüme girip girmeyeceği.
