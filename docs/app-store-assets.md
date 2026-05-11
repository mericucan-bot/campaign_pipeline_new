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

## 2. Pictures Referanslari

`pictures/` klasorundeki ornekler App Store gorsel dili icin referans olarak kullanilacak. Bu dosyalar birebir final varlik olmak zorunda degil; tasarim yonu, renk, kompozisyon ve pazarlama dili icin kaynak kabul edilecek.

Referans kullanimi:

- `pictures/ChatGPT Image May 11, 2026, 03_59_58 AM.png`
  - Ana App Store tanitim paketi referansi.
  - Ikon, kucuk ikon varyasyonlari ve dortlu screenshot sunum ritmi icin en guclu kaynak.
  - Final screenshot setinde koyu yesil/siyah zemin, mint vurgu ve kisa fayda basliklari bu dosyadan ilham alacak.

- `pictures/ChatGPT Image May 11, 2026, 03_59_23 AM.png`
  - Kampanya liste ekrani referansi.
  - Neon kenarlikli koyu kart, banka seridi, skor alani ve "Detaya Git" aksiyonu icin hedef tasarim dili.
  - Gercek uygulamadaki liste kartlari daha okunabilir kalacak; App Store gorsellerinde bu referansin daha parlak/pazarlama odakli versiyonu kullanilabilir.

- `pictures/ChatGPT Image May 11, 2026, 03_59_35 AM.png`
  - Ikon konsepti referansi.
  - Radar + firsat/para sembolu fikri iyi; ancak final App Store ikonunda uzun yazi kullanilmamali.
  - Final ikon bu fikrin sade, yazisiz ve kucuk boyutta taninabilir versiyonu olmali.

- `pictures/ChatGPT Image May 11, 2026, 03_55_23 AM.png`
  - Banka renk ve marka tonu referansi.
  - Gercek banka logolari birebir kullanilmadan, renk ailesi ve kart seridi karakteri icin yol gosterici olabilir.

- `pictures/ChatGPT Image May 11, 2026, 03_57_06 AM.png`
  - Banka seritleri ve kart varyasyonlari referansi.
  - Uygulamadaki kampanya kartlarinda sol banka seridi, monogram ve banka adi hiyerarsisi icin kullanilabilir.

Uyari:

- App Store gorsellerinde ve uygulama icinde banka logolari/markalari birebir kullanilmadan once marka ve kullanim haklari ayrica degerlendirilmeli.
- Guvenli ilk surum yaklasimi: banka rengi + banka adi + sade monogram kullanmak.
- App Store screenshotlari gercek uygulama ekranlarindan uretilecek; referans gorseller sadece kompozisyon ve tasarim rehberi olarak kullanilacak.

## 3. Ekran Goruntusu Seti

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

## 4. App Store Metin Bindirmesi

Ilk surumde sade ekran goruntusu tercih edilecek. Sonra gerekirse App Store icin gorsel uzerine kisa basliklar eklenebilir.

Olası basliklar:

- "Kart kampanyalarini tek ekranda kesfet"
- "Sadece kendi kartlarina uygun firsatlari filtrele"
- "Puanlarini kacirmamak icin hatirlatici kur"
- "Favorilerini ve kazancini takip et"

## 5. Cekim Kontrol Listesi

- Uygulama son `dev-experiments` koduyla build edildi.
- Test kullanicisi veya misafir mod acildi.
- Arama kutusu bos veya genel bir kelimeyle duruyor.
- Favori/kart/hatirlatici sayilari gercekci gorunuyor.
- Saat, pil ve simulator cercevesi tutarli.
- Kisisel e-posta ve hassas veri gorunmuyor.
- Ekran goruntuleri `docs/app-store-screenshots/` altina isimlendirme standardiyla kondu.
