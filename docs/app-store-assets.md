# App Store Gorsel Paket Plani

Bu dosya App Store'a yuklenecek ikon ve ekran goruntulerinin hazirlik standardidir. Amac son hafta panik yapmadan, hangi gorselin nerede kullanilacagini net tutmak.

## 1. App Icon

Apple icin ana ikon 1024x1024 PNG olmalidir.

Teknik kurallar:

- Boyut: `1024x1024`
- Format: PNG
- Renk profili: sRGB
- Transparan arka plan yok
- Kose yuvarlatma yok; iOS bunu kendisi uygular
- Kucuk boyutta okunmayacak uzun metin yok
- Banka logosu veya banka markasina benzeyen unsur yok

Tasarim yonu:

- Dashboard temasiyla uyumlu koyu yesil / siyah zemin.
- Radar fikri ana sembol olsun.
- Mint yesili vurgu rengi kullanilsin.
- Ikon 40x40 gibi kucuk boyutta da taninabilir kalmali.

Hazirlanacak dosyalar:

- `ios/KampanyaRadari/KampanyaRadari/Assets.xcassets/AppIcon.appiconset/AppIcon-Light.png`
- `ios/KampanyaRadari/KampanyaRadari/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png`
- `ios/KampanyaRadari/KampanyaRadari/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png`

Not: `AppIcon.appiconset/Contents.json` su an ikon yuvalarini iceriyor, fakat PNG dosyalari henuz bagli degil. Ikon final tasarimi uretildiginde bu dosya adlariyla asset catalog'a baglanacak.

## 2. Ekran Goruntusu Seti

App Store icin ilk set iPhone dikey ekran goruntuleriyle hazirlanacak. Gorseller gercek veriyi gosterebilir ama kisisel e-posta, hesap bilgisi veya gizli anahtar gostermemeli.

Kural:

- Kisisel e-posta gorunmeyecek.
- Test hesabi veya misafir mod kullanilacak.
- Bildirim, hesap ve premium ekranlarinda gercek odeme bilgisi gorunmeyecek.
- Gorseller ayni tema ve ayni veri setiyle tutarli olacak.

Onerilen ekranlar:

1. `01-onboarding.png` - Ilk acilis ve deger onerisi.
2. `02-dashboard.png` - Toplam kampanya, banka ve kategori ozeti.
3. `03-campaign-list.png` - Kampanya listesi, arama ve banka secimi.
4. `04-campaign-detail.png` - Detay, favori, katildim ve kaynak aksiyonlari.
5. `05-reminder.png` - Puan harcama hatirlaticisi.
6. `06-profile-premium.png` - Hesap, plan ve premium alani.

## 3. App Store Metin Bindirmesi

Ilk surumde sade ekran goruntusu tercih edilecek. Sonra gerekirse App Store icin gorsel uzerine kisa basliklar eklenebilir.

Olası basliklar:

- "Kart kampanyalarini tek ekranda kesfet"
- "Sadece kendi kartlarina uygun firsatlari filtrele"
- "Puanlarini kacirmamak icin hatirlatici kur"
- "Favorilerini ve kazancini takip et"

## 4. Cekim Kontrol Listesi

- Uygulama son `dev-experiments` koduyla build edildi.
- Test kullanicisi veya misafir mod acildi.
- Arama kutusu bos veya genel bir kelimeyle duruyor.
- Favori/kart/hatirlatici sayilari gercekci gorunuyor.
- Saat, pil ve simulator cercevesi tutarli.
- Kisisel e-posta ve hassas veri gorunmuyor.
- Ekran goruntuleri `docs/app-store-screenshots/` altina isimlendirme standardiyla kondu.
