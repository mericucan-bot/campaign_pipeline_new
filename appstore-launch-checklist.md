# Kampanya Radarı — App Store Yayın Kontrol Listesi

> Bu belge, projenin mevcut kod tabanı incelenerek hazırlanmıştır.  
> Tamamlananlar ✅, kritik blocker'lar 🔴, önemli ama engelleyici olmayanlar 🟡, bilgi notları ℹ️ ile işaretlenmiştir.

---

## Mevcut Durum (Projeyi İnceleyince Gördüklerim)

Projenin aslında çok ileride olduğunu belirtmek gerekiyor. Aşağıdakiler zaten **tamamlanmış**:

✅ SwiftUI native iOS uygulaması (MVVM, @Observable)  
✅ Supabase Auth — e-posta/şifre giriş, kayıt, şifre sıfırlama, deep link callback  
✅ Kullanıcı verisi bulut senkronu (favoriler, kartlarım, katılım kayıtları)  
✅ StoreKit 2 — ürün yükleme, satın alma, geri yükleme altyapısı  
✅ Entitlement katmanı — Free/Premium kural motoru merkezi  
✅ Push bildirim — UNUserNotification ile 7/3/0 gün hatırlatıcı planlama  
✅ Onboarding (3 adım), misafir modu, şifre güncelleme akışı  
✅ Privacy.html + Support.html GitHub Pages'de canlı  
✅ App icon (1024×1024 PNG) tanımlı  
✅ TestFlight ve App Store Connect rehberleri dokümanlarda mevcut  

---

## 🔴 KRİTİK — Bu 3 Şey Olmadan App Store'a Gönderilmez

### 🟡 1. Supabase Publishable Key Konumu

**Nerede:** `ios/KampanyaRadari/KampanyaRadari/Services/AppConfig.swift`

```swift
// 15 Mayıs 2026 güncellemesi:
// AppConfig.swift içindeki fallback URL/key kaldırıldı.
// Uygulama artık değerleri Info.plist üzerinden okuyor.
```

**Not:**
- Supabase `anon` / `publishable` key mobil uygulama içinde bulunabilir; bu key, RLS politikalarıyla sınırlandırılmış public client key'dir.
- Asıl kritik yasak: `service_role`, `sb_secret` veya scraper yazma anahtarının iOS uygulamasına ya da public repoya girmemesi.
- Mevcut iOS kodunda `service_role` key yok.

**Yapılacak:**  
TestFlight öncesi RLS politikaları tekrar denetlenecek. İstersek daha sonra `Info.plist` değerleri Xcode build config dosyasına taşınarak repo içindeki tekrar azaltılabilir.

---

### 🔴 2. Apple Sign In Zorunluluğu

**Nerede:** `CampaignListView.swift` → `AuthPreviewButton` — şu an "Yakında" olarak kapalı

**Neden kritik:**  
Apple'ın App Store Review Guideline 4.8 kuralı açık:  
> *"Apps that use a third-party or social login service to set up or authenticate the user's primary account with the app must also offer Sign in with Apple."*

E-posta/şifre ile kayıt bir "third-party login" sayılmadığı durumlar olsa da Supabase Auth kullanan bir uygulama için Apple genellikle Apple Sign In istiyor. **İlk gönderimiyle reddedilme ihtimali yüksek.**

**Yapılacak:**
- Xcode'da "Sign in with Apple" capability'yi aktive et
- `ASAuthorizationAppleIDProvider` ile akışı yaz
- `SupabaseAuthService`'e Apple token'ını Supabase'e iletecek endpoint ekle
- `AuthOptionsSheet`'teki kapalı butonu aç

---

### ✅ 3. App Store Connect'te Uygulama ve Abonelik Kaydı — TAMAMLANDI

**12 Mayıs 2026 tarihinde tamamlandı:**

✅ `com.mericucan.KampanyaRadari` Bundle ID kaydedildi (Push Notifications, Sign in with Apple, In-App Purchase aktif)  
✅ Paid Apps anlaşması imzalandı — Active  
✅ Vergi formu (W-8BEN) teslim edildi — Active (Türkiye-ABD %10 withholding)  
✅ Banka hesabı eklendi — Enpara, TRY, Active  
✅ My Apps → "Kampanya Radarı" oluşturuldu (Apple ID: 6768634795)  
✅ Abonelik grubu "Kampanya Radarı Premium" oluşturuldu  
✅ `com.mericucan.KampanyaRadari.premium.monthly` → Aylık Premium, ₺49,99  
✅ `com.mericucan.KampanyaRadari.premium.yearly` → Yıllık Premium oluşturuldu  
✅ App Information → Category: Finance, Age Rating: 4+, Fiyat: Ücretsiz  
✅ Sandbox tester hesabı oluşturuldu  

> ⚠️ **Not:** Abonelik ürünlerinin "Missing Metadata" durumu normal — binary yüklenip review'a gönderildiğinde bu durum kapanıyor. Şu aşamada engelleyici değil.

---

## 🟡 ÖNEMLİ — TestFlight'tan Önce Tamamlanmalı

### ✅ 4. Access Token Yenileme (Refresh) Mekanizması

**Nerede:** `SupabaseAuthService.swift` + `AuthStateStore.swift`

**15 Mayıs 2026 güncellemesi:**  
`refresh_token` ile `auth/v1/token?grant_type=refresh_token` çağrısı eklendi. Uygulama kaydedilmiş oturumu açılışta kontrol ediyor ve süresi yaklaşmışsa yenilemeyi deniyor.

**Yayın öncesi test:**  
Gerçek cihazda uzun süre bekletme / uygulamayı kapatıp açma senaryosu TestFlight sırasında tekrar kontrol edilecek.

---

### 🟡 5. Kalıcı Premium Doğrulaması

**Sorun:** `PremiumPurchaseService.purchaseSelectedOffering()` başarılı olunca `authState.applyPremiumPurchasePreview()` çağrılıyor. Bu sadece uygulama oturumunda premium açıyor — uygulama kapatılınca sıfırlanıyor.

**Yapılacak (iki yoldan biri):**

- **Yol A — Hızlı:** StoreKit `Transaction.currentEntitlements` akışını uygulama açılışında dinle, aktif abonelik varsa profili güncelle.
- **Yol B — Doğru (önerilen):** RevenueCat bağla. Webhook ile Supabase `profiles.premium_until` alanını otomatik güncelle. Android hedefi olduğu için bu yol uzun vadede daha mantıklı.

---

### 🟡 6. RLS (Row Level Security) Politikaları Son Denetim

**Neden önemli:** Scraper service role key ile yazıyor, mobil anon key ile okuyor. Bu ayrım doğru ama yayın öncesi Supabase dashboard'da şunları doğrula:

- `campaigns` tablosu: public read ✓, write yok ✓
- `user_favorites`, `user_cards`, `campaign_participations`: sadece kendi `user_id`'sine okuma/yazma
- `profiles`: kendi satırına okuma/yazma, başkasına erişim yok

---

### 🟡 7. App Store Screenshots

**Gerekli format:** iPhone 6.7" (2796×1290) zorunlu + iPhone 6.5" (2778×1284) önerilen  
**Adet:** Her cihaz için en az 1, en fazla 10 ekran görüntüsü

`docs/app-store-screenshots/` klasörü şu an boş. Simülatörde şu ekranların görüntüsü alınmalı:
- Ana dashboard (kampanya özeti)
- Kampanya listesi (filtre açık)
- Kampanya detayı
- Kazançlarım ekranı
- Premium / Paywall ekranı

---

## 🟡 Kod Kalitesi — Yayın Sonrasında İzlenecekler

### 🟡 8. Kategori Eşleştirme Mantığı Kırılgan

**Nerede:** `CampaignListViewModel.canonicalCategory(for:)`

Şu an kampanya kategorisi, başlık ve açıklama içinde Türkçe anahtar kelime aramasıyla belirleniyor. Banka sitelerinin kampanya metinleri değişirse veya yeni bir marka eklense (örn. yeni bir market zinciri) kategori yanlış düşecek.

**Öneri:** Scraper tarafında kategori zaten `campaigns.category` alanına yazılıyorsa bunu öncelikli kullan; metin analizi fallback olarak kalsın.

---

### 🟡 9. Hata Mesajları Türkçeleştirme Eksik

`CampaignListViewModel.load()` → `errorMessage = "Kampanyalar yuklenemedi. \(error.localizedDescription)"` — `localizedDescription` İngilizce sistem hatası dönebiliyor ("The Internet connection appears to be offline" gibi). Kullanıcıya gösterilecek hata metinleri önceden Türkçe olarak tanımlanmalı.

---

## ℹ️ Bilgi Notları

### ℹ️ Web Scraping ve Review Riski

Apple, App Store Review sırasında zaman zaman "veri kaynağı nedir?" diye sorabiliyor. Review notlarına şunu eklemek gerekebilir:

> *"Kampanya verileri, Türk bankalarının kamuya açık kampanya web sayfalarından sunucu tarafında otomatik olarak toplanmaktadır. Uygulama bu verileri yalnızca okuma amacıyla sunar."*

Bu bilgiyi App Store Connect'teki "Notes for App Review" alanına ekle.

---

### ℹ️ Google Sign In — Sonraki Sürüm

Google Sign In için OAuth client ID ve Supabase entegrasyonu gerekiyor. Bu Apple Sign In kadar acil değil ve ilk sürümde "Yakında" olarak bırakılabilir. Ancak açıkça devre dışı olduğu görünmeli — buton grileşmiş ve tıklanamaz olarak gösterilmeli (şu an öyle görünüyor, iyi).

---

### ℹ️ Crash ve Analitik Takibi

Şu an uygulamada herhangi bir crash raporlama veya analitik yok. TestFlight'ın kendi crash raporları başlangıç için yeterli. Kullanıcı sayısı arttığında Sentry veya Firebase Crashlytics değerlendirilebilir.

---

### ℹ️ Uygulama İsmi ve Bundle ID

- **Uygulama adı:** "Kampanya Radarı" (Türkçe karakter içeriyor — App Store'da sorun çıkarmaz ama "Kampanya Radari" gibi ASCII versiyonu yedek olarak düşünülebilir)
- **Bundle ID:** `com.mericucan.KampanyaRadari` — Xcode'da bu ID ile provisioning profile oluşturulmalı

---

## Özet: Öncelik Sırası

| # | Görev | Durum | Blocker mı? |
|---|-------|-------|-------------|
| 1 | Supabase key fallback'lerini temizle | ✅ **Tamamlandı** | — |
| 2 | Apple Sign In entegrasyonu | 🔴 **Bekliyor** | Review'da ret riski |
| 3 | App Store Connect kurulumu (bundle ID, abonelik, agreements) | ✅ **Tamamlandı** | — |
| 4 | Token refresh mekanizması | ✅ **Tamamlandı** | — |
| 5 | Kalıcı premium doğrulaması | 🟡 **Bekliyor** | Gelir modeli |
| 6 | RLS politikaları denetim | 🟡 **Bekliyor** | Güvenlik |
| 7 | App Store screenshots | 🟡 **Bekliyor** | Metadata zorunlu |
| 8 | Xcode Archive → App Store Connect upload | 🟡 **Bekliyor** | TestFlight için zorunlu |
| 9 | TestFlight ile gerçek cihaz testi | 🟡 **Bekliyor** | Kalite |
| 10 | Review notuna veri kaynağı açıklaması | 🟡 **Bekliyor** | Ret önleme |
| 11 | Hata mesajları Türkçeleştirme | ⚪ **Yayın sonrası** | Kalite |
| 12 | RevenueCat veya StoreKit kalıcı doğrulama | 🟡 **Bekliyor** | Gelir modeli |

---

*Son güncelleme: 15 Mayıs 2026 — Debug taramasıyla token refresh, Supabase sayfalama ve AppConfig fallback temizliği eklendi.*
