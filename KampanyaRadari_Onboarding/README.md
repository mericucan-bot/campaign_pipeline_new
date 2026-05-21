# Kampanya Radarı Onboarding Paketi

Bu ZIP içinde:

- `SwiftUI/OnboardingView.swift`: 3 sayfalı onboarding tasarımı için tekrar üretilebilir SwiftUI kodu.
- `ReferenceImages/`: Tasarım referansı olarak kullanacağın 3 PNG.
- `AssetsGuide/logo_asset_names.txt`: Banka/kart logoları için önerilen asset isimleri.

## Kullanım

1. `OnboardingView.swift` dosyasını Xcode projenize ekleyin.
2. Gerçek banka/kart logolarını `Assets.xcassets` içine aşağıdaki isimlerle ekleyin:
   - axess
   - maximum
   - garanti
   - paraf
   - saglam
   - kolay
   - onDigital
   - vakifWorld
   - qnb
   - denizbank
   - ziraat
   - yapikrediWorld
   - teb
3. Uygulamada `OnboardingView()` çağırın.

## Önemli Not

3. sayfadaki banka/kart logoları telif ve marka doğruluğu açısından SwiftUI içinde çizilmedi. En doğru sonuç için resmi logo assetlerini projeye koymak gerekiyor.

Eğer logo assetleri henüz yoksa `BankLogoCard` içindeki fallback `Text` opacity değerini `1` yaparak geçici yazılı kartlar görebilirsin.
