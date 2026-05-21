# Kampanya Radarı Onboarding - Çalışan SwiftUI Paket

Bu paket, 3 onboarding sayfasını Codex'in tekrar yorumlamasına gerek kalmadan doğrudan Xcode projesine eklemek için hazırlandı.

## İçerik

- `SwiftUI/KampanyaRadariOnboarding.swift`  
  3 ekranın tamamını içeren tek SwiftUI dosyası.

- `References/`  
  Tasarım referansı olarak kullanacağın 3 PNG.

- `Assets/LogoPlaceholders/LogoAssetNames.md`  
  Xcode `Assets.xcassets` içine eklenmesi gereken logo asset isimleri.

## Kullanım

1. `KampanyaRadariOnboarding.swift` dosyasını Xcode projenize sürükleyip bırakın.
2. `Assets.xcassets` içine banka/kart logolarını aşağıdaki isimlerle ekleyin:
   - `maximum`
   - `axess`
   - `garanti`
   - `paraf`
   - `saglamkart`
   - `nkolay`
   - `ondigital`
   - `vakifworld`
   - `qnb`
   - `denizbank`
   - `ziraat`
   - `yapikredi`
   - `teb`
3. Root view içinde şunu çağırın:

```swift
KampanyaRadariOnboardingView()
```

Logo assetleri eklenmezse kod placeholder yazı ve SF Symbol ile yine çalışır. Asset eklendiği anda otomatik olarak gerçek logoyu gösterir.

## Tasarım Notları

Ana renkler:

- Koyu arka plan: `#020B12`, `#07131D`, `#01070C`
- Mint vurgu: `#55E6D0`
- Metin beyaz: `#F5F7F8`
- Açıklama gri: `#8E9AA3`
- YapıKredi WORLD mor: `#B64DFF`

Kodda özellikle absolute-position mantığı kullanıldı. Böylece Codex tasarımı düzleştirmeden, görseldeki yerleşime daha yakın sonuç üretir.

## Codex'e Verilecek Kısa Talimat

Aşağıdaki dosyayı aynen projeye ekle. Görsel dili değiştirme. Sadece gerekiyorsa mevcut navigation yapısına bağla. Logo asset isimlerini `Assets.xcassets` içinde aynı isimlerle kullan. `KampanyaRadariOnboardingView()` onboarding başlangıç view'i olacak.
