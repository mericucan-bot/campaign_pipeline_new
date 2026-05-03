export function loadingStateHtml() {
  return `
    <div class="state-panel loading-panel">
      <svg class="spinner" viewBox="0 0 24 24" aria-hidden="true">
        <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="3" opacity=".18"></circle>
        <path d="M22 12a10 10 0 0 1-10 10" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"></path>
      </svg>
      <h3>Kampanyalar yükleniyor...</h3>
      <div class="state-skeletons">
        ${Array.from({ length: 3 }).map(() => `
          <article class="state-skeleton-card">
            <span class="skeleton skeleton-title"></span>
            <span class="skeleton"></span>
            <span class="skeleton skeleton-short"></span>
            <span class="skeleton skeleton-footer"></span>
          </article>
        `).join("")}
      </div>
    </div>
  `;
}

export function emptyStateHtml(filterContext) {
  return `
    <div class="state-panel empty-panel">
      <svg viewBox="0 0 48 48" aria-hidden="true">
        <circle cx="21" cy="21" r="12" fill="none" stroke="currentColor" stroke-width="4"></circle>
        <path d="m31 31 9 9" stroke="currentColor" stroke-width="4" stroke-linecap="round"></path>
      </svg>
      <h3>Sonuç bulunamadı</h3>
      <p><strong>${filterContext}</strong> için kampanya yok. Filtreleri değiştirmeyi deneyin.</p>
      <div class="state-actions">
        <button type="button" class="secondary-button" data-clear-filters>Filtreleri temizle</button>
        <button type="button" class="apply-button" data-show-all>Tüm kampanyaları gör</button>
      </div>
    </div>
  `;
}

export function errorStateHtml(errorMsg) {
  return `
    <div class="state-panel error-panel">
      <svg viewBox="0 0 48 48" aria-hidden="true">
        <path d="M24 5 45 42H3L24 5Z" fill="none" stroke="currentColor" stroke-width="4" stroke-linejoin="round"></path>
        <path d="M24 18v11M24 35h.01" stroke="currentColor" stroke-width="4" stroke-linecap="round"></path>
      </svg>
      <h3>Veriler yüklenemedi</h3>
      <p>Teknik detay: ${errorMsg}</p>
      <div class="state-actions">
        <button type="button" class="apply-button" onclick="location.reload()">Tekrar dene</button>
        <a class="secondary-button" href="https://github.com/mericucan-bot/campaign_pipeline_new/issues" target="_blank" rel="noreferrer">GitHub'da bildir</a>
      </div>
    </div>
  `;
}
