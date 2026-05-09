# Kampanya Radar iOS MVP

Bu klasor iOS uygulamasinin ilk SwiftUI iskeletidir. Uygulama Supabase REST API'den sadece aktif kampanyalari okur.

## Xcode'da proje olusturma

1. Xcode > File > New > Project
2. iOS > App
3. Product Name: `KampanyaRadar`
4. Interface: `SwiftUI`
5. Language: `Swift`
6. Bundle Identifier: kendi Apple hesabina uygun bir deger

Sonra bu klasordeki `Sources/KampanyaRadar` altindaki dosyalari Xcode projesine ekle.

## Info.plist degerleri

Xcode projesinin `Info.plist` dosyasina su iki key'i ekle:

```xml
<key>SupabaseURL</key>
<string>https://elzosfogvbybieyvojek.supabase.co</string>
<key>SupabaseAnonKey</key>
<string>BURAYA_PUBLISHABLE_KEY</string>
```

`SupabaseAnonKey` icin publishable key kullan:

```text
sb_publishable_...
```

Service role veya secret key iOS uygulamaya konmaz.

## Ilk ozellikler

- Aktif kampanyalari Supabase'den okur
- Banka filtresi
- Arama
- Favoriler cihazda saklanir
- Detay ekrani
- Kaynak linkini Safari'de acar

