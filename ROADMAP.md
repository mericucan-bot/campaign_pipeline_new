# 🗺️ Kampanya Radarı v2 Yol Haritası

Kampanya Radarı v1'den v2'ye evrim. Planlanan özellikler ve geliştirmeler.

---

## 📋 İlke

**v1 (2026 S1):** MVP — Kampanya taraması ve temel filtreleme  
**v2 (2026 Orta-Sonu):** Premium özellikleri, AI, widget'lar ve cihazlar arası senkronizasyon  
**v3+ (2027+):** Sosyal, API, enterprise

---

## 🎯 v2 Özellikleri (Q3 2026)

### Kategori 1: Widget & Home Screen

#### Home Screen Widget (iOS 17+, Android 12+)
- **Favori kampanyalarının sayısı**
- **En yakında bitiş tarihi göstermek**
- **Tıkla → uygulamayı açıp detay görmek**

**Status:** 📋 Tasarımda  
**ETA:** Ağustos 2026

```swift
// iOS örnek
struct CampaignWidgetEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        VStack {
            Text("En yakın bitiş: \(entry.nextDeadline)")
            Text("Favori kampanyalar: \(entry.favoriteCount)")
        }
    }
}
```

---

### Kategori 2: AI Öneriler

#### Kişiselleştirilmiş Kampanya Önerileri
- **Geçmiş:** Önceden açılan, favorilenen kampanyaları analiz et
- **Kart profili:** Seçili kartlara göre öneriler
- **Trend:** Bu hafta benzer kullanıcıların baktığı kampanyalar

**Status:** 🔄 Prototipleştirilme  
**ETA:** Eylül 2026

**Algoritma:**
```
Skor = (KartUygunluğu * 0.4) + 
        (GeçmişiKampanyalar * 0.3) + 
        (AkulanıcıTrendı * 0.2) + 
        (FırsatKalitesi * 0.1)
```

---

### Kategori 3: Bilgiler & Raporlar

#### Kazanç Raporu (Premium)
- **Tasarruf özeti:** Toplam ₺, aylar bazında
- **Kategori analizi:** Hangi kategoide en çok kazandın
- **Banka karşılaştırması:** Bankalar bazında ödenekler

**Status:** 📋 Tasarımda  
**ETA:** Eylül 2026

**Dashboard örneği:**
```
┌────────────────────────┐
│ Mayıs Özeti            │
├────────────────────────┤
│ Toplam tasarruf: 2.450 ₺ │
│ Market: 1.200 ₺ (49%)  │
│ Yakıt: 750 ₺ (31%)     │
│ Diğer: 500 ₺ (20%)     │
└────────────────────────┘
```

#### Banka İstatistikleri Gösterge Paneli
- **Banka başına aktif kampanya sayısı**
- **Güncellenme sıklığı**
- **Ortalama kazanç** per kampanya

**Status:** ⏱️ Backlog  
**ETA:** Ekim 2026

---

### Kategori 4: Geliştirilmiş Filtreleme

#### Dinamik Fiyat Aralığı Filtresi
- **Min-Max kazanç aralığı**
- **Yalnızca "Anında taraftarlar"**
- **Yalnızca çevrimiçi alışveriş**

**Status:** 🔄 Prototipleştirilme  
**ETA:** Eylül 2026

#### Kayıtlı Filtre Şablonları
Sık kullanan filtreleri şablona kaydet, sonra bir tıkla yükle.

```
Örnek şablonlar:
- "İş günü hızlı kahvaltı" (Restoran, kahve, 1-2 dakika)
- "Hafta sonu akaryakıt" (Yakıt, Garanti + Akbank)
- "Yurt dışı seyahat" (Seyahat, havayolu, otel)
```

**Status:** 📋 Tasarımda  
**ETA:** Ekim 2026

---

### Kategori 5: Sosyal & Sosyal Paylaşım

#### Arkadaş İçeriSyncom
- **"Benim kartlarım"ı arkadaşla paylaş**
- **Benzer kartları olan kullanıcılar → Öneriler**

**Status:** ⏱️ Backlog  
**ETA:** 2027 (v2.1)

#### Kampanya Paylaşma
- **Kampanyaya link oluştur, arkadaşa gönder**
- **"Bu kampanya benim için uygun" diye tavsiye yap**

**Status:** ⏱️ Backlog  
**ETA:** 2027 (v2.1)

---

### Kategori 6: Veri Yönetimi & İhracat

#### Verileri Excel/CSV Olarak Dışa Aktar
- **Tüm kampanyaları indir**
- **Sadece favorileri indir**
- **Son 3 ayın kampanyalarını indir**

**Status:** 📋 Tasarımda  
**ETA:** Ekim 2026

```
CSV Başlığı:
Bank,Title,Category,Reward,EndDate,Favorite,Saved,Notes
```

---

## 🔧 Teknik Iyileştirmeler (v2 | Arka planda)

### iOS

- **SwiftUI 6 entegrasyonu** (Xcode 16+)
- **iOS 18+ async/await optimizasyonları**
- **CloudKit backup** (opsiyonel)
- **Focus mode integrasyonu**

**Status:** ⏱️ Backlog  
**ETA:** Ekim 2026

### Android

- **Kotlin Multiplatform Mobile** (KMM) explore (v3 için)
- **Jetpack Compose 1.7+ adaptasyonu**
- **Material Design 4 migrasyonu**
- **Predictive Back Gesture** iyileştirmesi

**Status:** ⏱️ Backlog  
**ETA:** Ekim 2026

### Backend (Supabase)

- **Vector embeddings** (AI önerileri için)
- **Full-text search** (kampanya başlığı + açıklama)
- **WebSocket** gerçek zamanlı güncellemeler
- **Realtime sync** cihazlar arası

**Status:** ⏱️ Backlog  
**ETA:** Eylül 2026

---

## 📊 İndikator & Ölçütler

### v1 Başarı Ölçütleri (Şu anki)
- ✅ App Store Onaylandı
- ✅ Google Play Onaylandı
- ⏳ 50+ aktif banka
- ⏳ 1K+ DAU (Daily Active Users) hedefi
- ⏳ Premium'a çevrim oranı: %3-5

### v2 Hedefleri
- 📈 10K+ DAU
- 📈 Premium çevrim oranı: %8-12
- 📈 Widget aktivasyonu: %40+
- 📈 Kullanıcı kalış süresi: +30%
- 📈 Push notification açılma: 40%+

---

## ⏱️ Timeline

```
2026:
├─ S1 (Halen): v1 yayını (iOS + Android)
├─ S2 (Haziran): Kapalı test, v1 improvements
├─ S3 (Temmuz-Eylül): v2 geliştirmesi
│  ├─ Şubat: Widget beta
│  ├─ Eylül: AI önerileri beta
│  └─ Ekim: Kazanç raporu
└─ S4 (Kasım-Aralık): v2 yayını + marketing

2027+:
├─ v2.1: Sosyal özellikler
├─ v2.2: Web dashboard
├─ v3: KMM / Multiplatform
└─ Enterprise: API, white-label
```

---

## 🤝 Geri Bildirim

**Özellikleri oyla veya öner:**
- App Store: Yorum bırak
- Google Play: Yorum bırak
- E-posta: mericucan@gmail.com

---

## 📝 Notlar

- Tüm özellikler v1 stabilite ve performansa zarar vermez
- Privacy-first: Tüm öneriler cihaz üzerinde (on-device) yapılacak
- Veri: Sıfır şirkete şahsi verileriniz satılmaz

---

*Son güncelleme: Haziran 3, 2026*
