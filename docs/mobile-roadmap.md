# Mobil Uygulama Yol Haritasi

## Kisisellestirme

- Kullanici kendi banka/kartlarini profil ekranindan secer.
- Genel kampanya listesinde "Benim kartlarim" filtresi bu secime gore calisir.
- Favoriler, katildim, harcadim ve kazandim bilgileri ayni kullanici profiline baglanir.

## Hesap ve uyelik

- Ilk asamada yerel kayit kullanilir.
- Yayina yaklasirken Supabase Auth ile kullanici hesabi eklenir.
- Google ile giris, Apple ile giris ve e-posta girisi ayni profil verisine baglanir.
- Mobil uygulamaya service role key konmaz; istemci sadece public/anon yetkilerle calisir.

## Gelir modeli

- Ucretsiz planda reklamli deneyim ve temel filtreler yer alir.
- Ucretli planda reklamsiz deneyim, gelismis filtreler, takip listeleri ve kazanc hesaplayici one cikar.
- Abonelik ve satin alma islemleri App Store / Google Play kurallarina uygun tasarlanir.

## Android hazirligi

- Veri modeli, filtre mantigi ve kullanici profil verisi platformdan bagimsiz tutulur.
- iOS arayuzu SwiftUI ile ilerlerken backend/Supabase semasi Android icin de ayni kalir.
- Android gelistirme basladiginda ayni API, ayni RLS politikalari ve ayni kullanici profil tablolari kullanilir.
- Kritik is kurallari mobil arayuzlerin icine gomulmez; mumkun oldugunca servis/API katmaninda ortak tutulur.
