# App Store Connect Kurulum Rehberi

Bu rehber Kampanya Radarı'nı TestFlight ve App Store yoluna sokmak için App Store Connect'te yapılacak gerçek adımları sade şekilde anlatır.

## 1. Başlamadan Önce

Gerekli hesaplar:

- Apple Developer hesabı aktif olmalı.
- App Store Connect erişimi açık olmalı.
- Ücretli abonelik açılacaksa Agreements, Tax and Banking bölümü tamamlanmalı.
- Xcode'da Apple hesabın ekli olmalı.

Önemli güvenlik notu:

- iOS uygulamasına hiçbir zaman Supabase `service_role` key girilmeyecek.
- Uygulamada sadece publishable/anon key kullanılacak.
- Kampanya yazma ve scraper işleri sadece backend/otomasyon tarafında kalacak.

## 2. App Kaydı Açma

App Store Connect'te:

1. My Apps ekranına gir.
2. `+` butonuna bas.
3. New App seç.
4. Şu bilgileri gir:

- Platform: `iOS`
- Name: `Kampanya Radarı`
- Primary Language: `Turkish`
- Bundle ID: `com.mericucan.KampanyaRadari`
- SKU: `kampanya-radari-ios`
- User Access: `Full Access`

Bundle ID görünmüyorsa önce Apple Developer portalında Identifier açmak gerekir.

## 3. Kategori ve Yaş Derecelendirmesi

Önerilen kategori:

- Primary Category: `Finance`
- Secondary Category: `Shopping`

Gerekçe: Uygulama kredi kartı/banka kampanyalarını takip ediyor; alışveriş fırsatı tarafı ikinci kategoriye daha uygun.

Age Rating:

- Anketi doğru cevapla.
- Kumar, bahis, kullanıcı üretimli sınırsız içerik veya yetişkin içerik yoksa muhtemelen düşük yaş derecesi çıkar.

## 4. URL Alanları

App Store Connect'te şu URL'leri kullanacağız:

- Privacy Policy URL: `https://mericucan-bot.github.io/campaign_pipeline_new/privacy.html`
- Support URL: `https://mericucan-bot.github.io/campaign_pipeline_new/support.html`
- Marketing URL: boş bırakılabilir.

Yayın öncesi bu iki URL tarayıcıda açılıp kontrol edilmeli.

## 5. App Privacy Cevapları

App Privacy bölümünde şunlar beyan edilecek:

- Contact Info: E-posta adresi.
- User Content: Favoriler, Kartlarım, katılım/kazanç kayıtları.
- Purchases: Premium abonelik durumu.
- Identifiers: Supabase kullanıcı ID'si.
- Diagnostics: Crash/analitik aracı eklenirse ayrıca işaretlenecek.

İlk sürümde reklam veya analitik eklemezsek bunları işaretlemeyiz. Sonradan eklenirse gizlilik cevapları güncellenir.

## 6. Abonelik Ürünleri

App Store Connect'te Subscriptions bölümünde:

1. Subscription Group oluştur.
2. Grup adı: `Kampanya Radarı Premium`
3. Monthly ürününü ekle:
   - Product ID: `com.mericucan.KampanyaRadari.premium.monthly`
   - Reference Name: `Kampanya Radarı Premium Monthly`
   - Display Name: `Aylık Premium`
   - Description: `Sınırsız hatırlatıcı, reklamsız kullanım ve gelişmiş kampanya takibi.`
4. Yearly ürününü ekle:
   - Product ID: `com.mericucan.KampanyaRadari.premium.yearly`
   - Reference Name: `Kampanya Radarı Premium Yearly`
   - Display Name: `Yıllık Premium`
   - Description: `Aylık plana göre daha avantajlı Premium kullanım.`

Fiyatlar henüz kesin değil. İlk sandbox testinde düşük ve makul bir fiyat seviyesi seçilebilir; canlı yayından önce tekrar karar verilecek.

## 7. Sandbox Tester

Sandbox ödeme testi için gerçek Apple ID yerine test kullanıcısı aç:

1. App Store Connect -> Users and Access.
2. Sandbox Testers sekmesine gir.
3. Yeni test kullanıcısı oluştur.
4. Bu e-posta gerçek Apple ID olmamalı.
5. Simülatör veya test cihazında satın alma testinde bu kullanıcı kullanılacak.

## 8. Xcode ile TestFlight Build

Xcode tarafında:

1. `ios/KampanyaRadari/KampanyaRadari.xcodeproj` dosyasını aç.
2. Target olarak KampanyaRadari seç.
3. Signing & Capabilities bölümünde Team seç.
4. Bundle Identifier: `com.mericucan.KampanyaRadari`
5. Build numarasını bir artır.
6. Üst cihaz seçiminden `Any iOS Device` veya bağlı gerçek cihaz seç.
7. Product -> Archive.
8. Archive bitince Distribute App -> App Store Connect -> Upload.

Upload sonrası App Store Connect'te build'in işlenmesi birkaç dakika sürebilir.

## 9. TestFlight Sırası

Önerilen test sırası:

1. Internal Testing grubuna kendini ekle.
2. Build'i iç testçilere aç.
3. `docs/testflight-checklist.md` dosyasındaki tüm testleri gerçek cihazda yap.
4. Şifre sıfırlama, bildirim izni, hatırlatıcı ve senkron akışlarını özellikle kontrol et.
5. Abonelik ürünleri hazırsa sandbox satın alma testi yap.
6. Hata yoksa küçük bir dış test grubu aç.

## 10. Yayın Öncesi Dikkat

- Final app icon 1024x1024 PNG olarak hazır olmalı.
- App Store ekran görüntüleri `docs/app-store-assets.md` planına göre hazırlanmalı.
- Banka logoları veya markalı görseller izin konusu netleşmeden App Store görsellerinde kullanılmamalı.
- Premium satın alma butonu, ürünler App Store Connect veya RevenueCat tarafında test edilmeden canlı açılmamalı.
- Privacy ve Support URL'leri canlı çalışmalı.
- Service role key uygulama dosyalarında bulunmamalı.

## 11. Bizim Sıradaki Pratik Adımımız

Kod tarafında sıradaki mantıklı sıra:

1. App Store Connect kaydını aç.
2. Bundle/signing ayarlarını Xcode'da doğrula.
3. Sandbox tester oluştur.
4. Abonelik ürünlerini App Store Connect'te aç.
5. StoreKit ürünlerinin uygulamada göründüğünü test et.
6. TestFlight build yükle.
