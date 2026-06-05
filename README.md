# Kampanya Radarı

Türkiye'deki banka ve kredi kartı kampanyalarını tek ekranda takip edin. En iyi fırsatları radarına alın, hiç birini kaçırmayın.

**Kampanya Radarı**, 50+ banka ve finansal kuruluşun güncel kampanyalarını derleyerek, kullanıcıların hangi kartlarıyla hangi avantajları alabileceğini anında gösterir.

---

## 📱 Uygulamalar

### iOS
- **App Store:** [Kampanya Radarı](https://apps.apple.com/tr/app/kampanya-radari/)
- **Gereken iOS:** 15.0+
- **Cihazlar:** iPhone (iPad görünüm optimize değil)

### Android
- **Google Play:** [Kampanya Radarı](https://play.google.com/store/apps/details?id=com.mericucan.kampanyaradari)
- **Gereken Android:** 8.0+ (API 26)
- **Özellikler:** Full responsive design, tablet desteği

---

## ✨ Ana Özellikler

### Akıllı Filtreleme
- **Kart filtresi:** Hangi kartlarınız varsa seçin, sizinle ilgili kampanyaları görelim
- **Kategori filtresi:** Market, akaryakıt, giyim, restoran, elektronik, seyahat, online
- **Banka filtresi:** Garanti, Akbank, Yapı Kredi, İş Bankası, Ziraat, VakıfBank ve 10+ banka

### Akıllı Sıralama
- **Bitiş tarihine göre:** Acil kampanyalar yukarıda
- **Fırsat skoruna göre:** En değerli kampanyalar öne
- **Banka adına göre:** Alfabetik sıralama
- **Başlığa göre:** Hızlı arama

### Favori Kampanyalar
- Beğendiğin kampanyaları kaydet
- Favorilerin sayısını ve tarafını göz at
- Offline erişim (kayıtlı favoriler)

### Hatırlatıcılar
- Kampanyanın bitiş tarihine yaklaşınca bildirim al
- Son gün sürprizinden kaçın
- Akıllı timing: bitiş tarihine 3 gün kala hatırlat

### Hesap ve Senkronizasyon (Premium)
- Tüm cihazlarda favorileriniz senkronize olsun
- Kampanya takip geçmişinizi koruyun
- Cihaz değiştiğinde verileriniz sizinle gitsin

---

## 🚀 Nasıl Başlayacağım?

### En Hızlı Başlangıç
1. **Misafir Mod:** Hesap oluşturmadan uygulamayı keşfet
2. **Kartlarımı Seç:** Hangi bankaların kartına sahipsen işaretle
3. **Kampanyaları Gör:** Seninle ilgili kampanyalar anında listeden öne çıkacak

### Hesap Oluştur
- E-posta ile kayıt (veya Google/Apple ile gir)
- Kartlarımı belirle
- Kampanyaları takip etmeye başla
- (Optional) Premium'a yükselt → cihazlar arası senkronizasyon

---

## 💰 Premium Özellikleri

| Özellik | Ücretsiz | Premium |
|---------|----------|---------|
| Kampanya görüntüleme | ✅ | ✅ |
| Favori kampanya | ✅ (50'ye kadar) | ✅ Sınırsız |
| Hatırlatıcı | ✅ (3 kampanya) | ✅ Sınırsız |
| Cihazlar arası senkronizasyon | ❌ | ✅ |
| Kazanç raporu | ❌ | ✅ |
| Reklam yok | ❌ | ✅ |

**Fiyatlandırma:**
- Aylık: 4.99 TL/ay
- Yıllık: 39.99 TL/yıl (% 33 tasarruf)

---

## 🏗️ Mimarisi

### iOS (Swift + SwiftUI)
```
ios/KampanyaRadari/
├── Services/          # Supabase auth, campaign fetching, reminders
├── Views/            # UI components (SwiftUI)
├── ViewModels/       # State management
└── Models/           # Data structures
```

**Teknoloji:**
- SwiftUI (UI)
- Combine (Reactive)
- StoreKit 2 (In-app subscriptions)
- Supabase (Backend/auth)
- CloudKit (Backup)

### Android (Kotlin + Jetpack Compose)
```
android/app/
├── ui/
│   ├── screen/       # Screens
│   ├── component/    # Reusable components
│   └── theme/        # Material 3 theme
├── viewmodel/        # State management
├── repository/       # Data layer
└── di/              # Dependency injection
```

**Teknoloji:**
- Jetpack Compose (UI)
- MVVM + Repository pattern
- Hilt (DI)
- Room (Local DB)
- Supabase (Backend)
- Datastore (User preferences)

### Backend (Supabase)
- PostgreSQL veritabanı
- Row Level Security (RLS)
- PostgreSQL functions (campaign sync)
- Auth (email, OAuth)

---

## 🛠️ Geliştirici Ortamı Kurulumu

### iOS
```bash
cd ios/KampanyaRadari
open KampanyaRadari.xcodeproj
# Xcode 15+ gerekli, iOS 15.0+
```

### Android
```bash
cd android
# Android Studio'da aç veya:
./gradlew assembleDebug
```

### Backend (Local Supabase)
```bash
# supabase_schema.sql ve supabase_user_schema.sql'i 
# Supabase SQL editor'de çalıştır
```

---

## 📊 Desteklenen Bankalar (50+)

**Premium Kartlar:**
- Garanti BBVA (Bonus, Premium Plus)
- Akbank (Axess, Axess Premium)
- Yapı Kredi (World, Platinum)
- İş Bankası (Maximum, Premium)
- Ziraat Bankkart
- VakıfBank

**Fintech & Digital:**
- Paraf, Paraf Premium
- N Kolay
- Halkbank
- DenizBank
- TEB
- QNB Finansbank
- ING
- Kuveyt Türk
- Kolay

---

## 🔒 Gizlilik & Güvenlik

- **Gizlilik Politikası:** [privacy.html](https://mericucan-bot.github.io/campaign_pipeline_new/privacy.html)
- **Kullanım Şartları:** [terms.html](https://mericucan-bot.github.io/campaign_pipeline_new/terms.html)
- **Veri:** Sadece gerekli veriler saklanır (e-posta, kartlar, favori kampanyalar)
- **Şifreleme:** HTTPS, database RLS ile korunmuş
- **Silme:** Hesapla birlikte tüm verileriniz silinir

---

## 📈 v2 Yol Haritası

Bkz: [ROADMAP.md](ROADMAP.md)

---

## 🤝 Katkı

Kampanya Radarı şu an kapalı bir proje. Geri bildirim ve öneriler için:
- **E-posta:** mericucan@gmail.com
- **App Store:** Yorum/geri bildirim bırakabilirsiniz

---

## 📄 License

Copyright © 2026 Meric Ucan. Tüm hakları saklıdır.

---

## 📞 Destek

- **Web:** [mericucan-bot.github.io/campaign_pipeline_new](https://mericucan-bot.github.io/campaign_pipeline_new/)
- **E-posta:** mericucan@gmail.com
- **In-app:** Ayarlar → Destek / Feedback
