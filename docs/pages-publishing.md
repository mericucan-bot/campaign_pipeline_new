# GitHub Pages Yayın Adımları

Bu proje `docs/` klasörünü statik web sitesi olarak yayınlar. Yayın tamamlanınca App Store Connect için gizlilik politikası ve destek URL'leri hazır olur.

## Beklenen Adresler

GitHub Pages ayarı açıldıktan sonra beklenen ana adres:

`https://mericucan-bot.github.io/campaign_pipeline_new/`

App Store Connect alanları için:

- Gizlilik Politikası URL'si: `https://mericucan-bot.github.io/campaign_pipeline_new/privacy.html`
- Destek URL'si: `https://mericucan-bot.github.io/campaign_pipeline_new/support.html`

## GitHub'da Yapılacak Ayar

1. GitHub'da `mericucan-bot/campaign_pipeline_new` reposunu aç.
2. `Settings` sekmesine gir.
3. Sol menüden `Pages` bölümünü aç.
4. `Build and deployment` altında `Source` seçeneğini `GitHub Actions` yap.
5. `Actions` sekmesine geç.
6. `Deploy Kampanya Radar` workflow'unu aç.
7. `Run workflow` ile `main` branch üzerinde elle çalıştır.

Workflow başarılı olunca GitHub Pages adresi repo ayarlarında görünecek.

## Önemli Not

Workflow sadece `main` ve `master` branch push'larında otomatik yayın yapar. `dev-experiments` branch'i test/geliştirme alanıdır ve otomatik olarak canlı siteyi değiştirmez.

## Yayın Sonrası Kontrol

- Ana sayfa açılıyor mu?
- Kampanyalar listeleniyor mu?
- Footer'daki `Gizlilik Politikası` linki açılıyor mu?
- Footer'daki `Destek` linki açılıyor mu?
- `privacy.html` ve `support.html` doğrudan URL ile açılıyor mu?
