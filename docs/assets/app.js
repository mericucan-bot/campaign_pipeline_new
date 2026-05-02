const state = {
  campaigns: [],
  filtered: [],
  selectedBank: "",
  favorites: loadFavoriteSet(),
  manualCampaigns: JSON.parse(localStorage.getItem("manualCampaigns") || "[]"),
  monthlySpend: Number(localStorage.getItem("monthlySpend") || 3000),
  myCards: new Set(JSON.parse(localStorage.getItem("myCards") || "null") || [
    "Akbank Axess",
    "Is Bankasi Maximum",
    "Paraf",
    "Paraf Premium",
    "VakifBank",
    "Yapi Kredi World",
  ]),
};

const labels = {
  "Akbank Axess": "Axess",
  "DenizBank Bonus": "DenizBank",
  "Garanti BBVA Bonus": "Garanti",
  "Is Bankasi Maximum": "Maximum",
  "Kuveyt Turk Saglam Kart": "Kuveyt",
  "N Kolay": "N Kolay",
  "On Kart": "On",
  "Paraf": "Paraf",
  "Paraf Premium": "Paraf Premium",
  "QNB CardFinans": "QNB",
  "TEB Bonus": "TEB",
  "VakifBank": "Vakif",
  "Yapi Kredi World": "YKB",
  "Ziraat Bankkart": "Ziraat",
  "Manuel Favori": "Manuel",
};

const myCards = new Set([
  "Akbank Axess",
  "Is Bankasi Maximum",
  "Paraf",
  "Paraf Premium",
  "VakifBank",
  "Yapi Kredi World",
]);

const els = {
  campaigns: document.querySelector("#campaigns"),
  bankFilter: document.querySelector("#bankFilter"),
  categoryFilter: document.querySelector("#categoryFilter"),
  rewardFilter: document.querySelector("#rewardFilter"),
  sortFilter: document.querySelector("#sortFilter"),
  searchInput: document.querySelector("#searchInput"),
  activeOnly: document.querySelector("#activeOnly"),
  favoritesOnly: document.querySelector("#favoritesOnly"),
  myCardsOnly: document.querySelector("#myCardsOnly"),
  bankRail: document.querySelector("#bankRail"),
  myCardsGrid: document.querySelector("#myCardsGrid"),
  healthGrid: document.querySelector("#healthGrid"),
  statSubline: document.querySelector("#statSubline"),
  activeCount: document.querySelector("#activeCount"),
  bankCount: document.querySelector("#bankCount"),
  favoriteCount: document.querySelector("#favoriteCount"),
  generatedAt: document.querySelector("#generatedAt"),
  manualForm: document.querySelector("#manualForm"),
  manualTitle: document.querySelector("#manualTitle"),
  manualDescription: document.querySelector("#manualDescription"),
  manualUrl: document.querySelector("#manualUrl"),
  manualImage: document.querySelector("#manualImage"),
  monthlySpend: document.querySelector("#monthlySpend"),
  monthlySpendValue: document.querySelector("#monthlySpendValue"),
  backToTop: document.querySelector(".back-to-top"),
  modal: document.querySelector(".detail-modal"),
  modalClose: document.querySelector(".modal-close"),
  settingsDrawer: document.querySelector(".settings-drawer"),
  settingsOpen: document.querySelector("[data-settings-open]"),
  settingsClose: document.querySelector("[data-settings-close]"),
};

showLoadingState();

fetch("./data/campaigns.json", { cache: "no-store" })
  .then((response) => response.json())
  .then((payload) => {
    state.campaigns = [...(payload.campaigns || []), ...state.manualCampaigns];
    hydrateStats(payload);
    hydrateHealth(payload.health || []);
    hydrateFilters();
    hydrateMyCards();
    initPreferredFlow();
    bindEvents();
    if (!state.campaigns.length) {
      showEmptyState("Tüm kaynaklar");
      return;
    }
    applyFilters();
  })
  .catch((err) => {
    showErrorState(err);
  });

function hydrateStats(payload) {
  const stats = payload.stats || {};
  els.activeCount.textContent = stats.active || 0;
  els.bankCount.textContent = stats.bank_count || unique(state.campaigns.map((item) => item.bank)).length;
  els.favoriteCount.textContent = state.favorites.size;
  if (payload.generated_at) {
    els.generatedAt.textContent = `Son güncelleme: ${new Date(payload.generated_at).toLocaleString("tr-TR")}`;
  }
}

function hydrateFilters() {
  fillSelect(els.bankFilter, "Tümü", unique(state.campaigns.map((item) => item.bank)), (bank) => bankLabel(bank));
  fillSelect(els.categoryFilter, "Tüm kategoriler", unique(state.campaigns.map((item) => item.category)));
  fillSelect(els.rewardFilter, "Tüm kazanımlar", unique(state.campaigns.map((item) => item.reward_type)));
  renderBankRail();
}

function bindEvents() {
  [els.bankFilter, els.categoryFilter, els.rewardFilter, els.sortFilter, els.searchInput, els.activeOnly, els.favoritesOnly, els.myCardsOnly].forEach((el) => {
    el.addEventListener("input", applyFilters);
    el.addEventListener("change", applyFilters);
  });
  if (els.monthlySpend) {
    els.monthlySpend.value = state.monthlySpend;
    updateMonthlySpendLabel();
    els.monthlySpend.addEventListener("input", () => {
      state.monthlySpend = Number(els.monthlySpend.value || 3000);
      localStorage.setItem("monthlySpend", String(state.monthlySpend));
      updateMonthlySpendLabel();
      applyFilters();
    });
  }
  if (els.manualForm) {
    els.manualForm.addEventListener("submit", addManualCampaign);
  }
  if (els.backToTop) {
    window.addEventListener("scroll", () => {
      els.backToTop.classList.toggle("visible", window.scrollY > 600);
    });
    els.backToTop.addEventListener("click", () => {
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }
  if (els.modalClose && els.modal) {
    els.modalClose.addEventListener("click", () => els.modal.close());
    els.modal.addEventListener("click", (event) => {
      if (event.target === els.modal) els.modal.close();
    });
  }
  if (els.settingsOpen && els.settingsDrawer) {
    els.settingsOpen.addEventListener("click", () => els.settingsDrawer.showModal());
  }
  if (els.settingsClose && els.settingsDrawer) {
    els.settingsClose.addEventListener("click", () => els.settingsDrawer.close());
    els.settingsDrawer.addEventListener("click", (event) => {
      if (event.target === els.settingsDrawer) els.settingsDrawer.close();
    });
  }
}

function initPreferredFlow() {
  if (els.myCardsOnly && localStorage.getItem("myCards")) {
    els.myCardsOnly.checked = true;
  }
}

function applyFilters() {
  state.selectedBank = els.bankFilter.value;
  const query = normalize(els.searchInput.value);
  const category = els.categoryFilter.value;
  const reward = els.rewardFilter.value;
  const activeOnly = els.activeOnly.checked;
  const favoritesOnly = els.favoritesOnly.checked;
  const myCardsOnly = els.myCardsOnly.checked;

  let rows = state.campaigns.filter((item) => {
    const haystack = normalize(`${item.title || ""} ${item.description || ""} ${item.bank || ""}`);
    return (!state.selectedBank || item.bank === state.selectedBank)
      && (!category || item.category === category)
      && (!reward || item.reward_type === reward)
      && (!activeOnly || item.is_active)
      && (!favoritesOnly || state.favorites.has(String(item.id)))
      && (!myCardsOnly || state.myCards.has(item.bank))
      && (!query || haystack.includes(query));
  });

  rows = sortRows(rows, els.sortFilter.value);
  state.filtered = rows;
  renderBankRail();
  renderCampaigns();
  const total = state.campaigns.length;
  const inactive = state.campaigns.filter((item) => !item.is_active).length;
  els.statSubline.textContent = `${rows.length} sonuç · ${total} kayıt · ${inactive} pasif`;
  els.favoriteCount.textContent = state.favorites.size;
}

function hydrateMyCards() {
  if (!els.myCardsGrid) return;
  const banks = unique(state.campaigns.map((item) => item.bank));
  els.myCardsGrid.innerHTML = banks.map((bank) => `
    <label class="card-pick">
      <input type="checkbox" value="${escapeAttr(bank)}" ${state.myCards.has(bank) ? "checked" : ""}>
      <span>${escapeHtml(bankLabel(bank))}</span>
    </label>
  `).join("");
  els.myCardsGrid.querySelectorAll("input").forEach((input) => {
    input.addEventListener("change", () => {
      state.myCards = new Set([...els.myCardsGrid.querySelectorAll("input:checked")].map((item) => item.value));
      localStorage.setItem("myCards", JSON.stringify([...state.myCards]));
      applyFilters();
    });
  });
}

function sortRows(rows, sort) {
  const clone = [...rows];
  if (sort === "deadline") {
    return clone.sort((a, b) => (a.deadline || "9999-12-31").localeCompare(b.deadline || "9999-12-31"));
  }
  if (sort === "gain") {
    return clone.sort((a, b) => normalizeKazanim(b, state.monthlySpend) - normalizeKazanim(a, state.monthlySpend));
  }
  if (sort === "bank") {
    return clone.sort((a, b) => `${a.bank}${a.title}`.localeCompare(`${b.bank}${b.title}`));
  }
  return clone.sort((a, b) => String(b.last_seen || "").localeCompare(String(a.last_seen || "")));
}

function renderBankRail() {
  const banks = unique(state.campaigns.map((item) => item.bank));
  els.bankRail.innerHTML = [
    chip("", "Tümü", !state.selectedBank),
    ...banks.map((bank) => chip(bank, bankLabel(bank), bank === state.selectedBank)),
  ].join("");
  els.bankRail.querySelectorAll("button").forEach((button) => {
    button.addEventListener("click", () => {
      els.bankFilter.value = button.dataset.bank;
      applyFilters();
    });
  });
}

function renderCampaigns() {
  if (!state.filtered.length) {
    showEmptyState(activeFilterContext());
    return;
  }

  els.campaigns.innerHTML = state.filtered.map((item) => card(item)).join("");
  els.campaigns.querySelectorAll(".favorite-button").forEach((button) => {
    button.addEventListener("click", () => {
      const id = button.dataset.id;
      if (state.favorites.has(id)) state.favorites.delete(id);
      else state.favorites.add(id);
      persistFavorites();
      button.classList.add("is-bumping");
      setTimeout(() => button.classList.remove("is-bumping"), 260);
      applyFilters();
    });
  });
  els.campaigns.querySelectorAll(".source-button").forEach((button) => {
    button.addEventListener("click", () => {
      if (button.dataset.url) window.open(button.dataset.url, "_blank", "noopener");
    });
  });
  els.campaigns.querySelectorAll(".detail-button").forEach((button) => {
    button.addEventListener("click", () => showDetail(button.dataset));
  });
}

function card(item) {
  const data = adaptCampaign(item);
  const favorite = state.favorites.has(String(data.id));
  const reward = rewardBadge(data);
  const deadline = deadlineInfo(data);
  const logoStyle = `--logo-bg:${bankColor(data.banka)}`;
  const logo = data.gorsel_url
    ? `<img src="${escapeAttr(data.gorsel_url)}" alt="" loading="lazy">`
    : `<span style="${logoStyle}">${escapeHtml(bankInitials(data.banka))}</span>`;
  return `
    <article class="campaign-card radar-card ${deadline.cardClass}" data-id="${escapeAttr(data.id)}">
      <div class="card-header">
        <div class="bank-logo" style="${logoStyle}">${logo}</div>
        <div class="card-bank-meta">
          <strong>${escapeHtml(data.banka)}</strong>
          <span class="category-badge">${escapeHtml(data.kategori)}</span>
        </div>
        <button class="favorite-button ${favorite ? "selected" : ""}" data-id="${escapeAttr(data.id)}" title="Favorilere ekle" aria-label="Favorilere ekle">${favorite ? "★" : "☆"}</button>
      </div>

      <div class="card-body">
        <h2 class="card-title">${escapeHtml(data.baslik)}</h2>
        ${data.aciklama ? `<p class="card-description">${escapeHtml(data.aciklama)}</p>` : ""}
      </div>

      <div class="card-footer">
        <span class="reward-badge ${reward.className}">${escapeHtml(reward.label)}</span>
        <span class="date-badge ${deadline.badgeClass}">${escapeHtml(deadline.label)}</span>
      </div>

      <div class="card-source">
        <span>Kaynak: ${escapeHtml(data.banka)} · ${escapeHtml(data.sourceDate)}</span>
        <button class="source-button" type="button" data-url="${escapeAttr(data.kaynak_url)}">Kaynağa git <span aria-hidden="true">↗</span></button>
      </div>
    </article>
  `;
}

function adaptCampaign(item) {
  return {
    id: item.id,
    baslik: item.baslik || item.title || "",
    aciklama: item.aciklama || item.description || "",
    banka: item.banka || item.bank || "Kampanya",
    kategori: item.kategori || item.category || "Genel",
    kazanim: item.kazanim || item.highlight || normalizeKazanim(item, state.monthlySpend),
    kazanim_turu: item.kazanim_turu || rewardLabelFor(item),
    bitis_tarihi: item.bitis_tarihi || item.deadline || null,
    kaynak_url: item.kaynak_url || item.url || "",
    gorsel_url: item.gorsel_url || item.image_url || "",
    aktif: item.aktif ?? item.is_active ?? true,
    sourceDate: String(item.last_seen || item.first_seen || "").slice(0, 10) || "Tarih yok",
  };
}

function rewardBadge(data) {
  const type = String(data.kazanim_turu || "").toLowerCase();
  const value = rewardValueText(data.kazanim);
  if (type === "tl") return { className: "reward-card-tl", label: `+${value}₺ cashback` };
  if (type === "%") return { className: "reward-card-percent", label: `+${value}% indirim` };
  if (type === "puan") return { className: "reward-card-puan", label: `+${value} puan` };
  if (type === "mil") return { className: "reward-card-mil", label: `+${value} mil` };
  return { className: "reward-card-default", label: value ? `+${value}` : "Fırsat" };
}

function rewardValueText(value) {
  const match = String(value || "").match(/\d+(?:[.,]\d+)?/);
  return match ? match[0] : String(value || "").trim();
}

function bankInitials(name) {
  return String(name || "KR").trim().slice(0, 2).toLocaleUpperCase("tr-TR");
}

function loadFavoriteSet() {
  try {
    const objectFavorites = JSON.parse(localStorage.getItem("favorites") || "{}");
    const ids = Object.entries(objectFavorites).filter(([, enabled]) => enabled).map(([id]) => id);
    if (ids.length) return new Set(ids);
  } catch (err) {
    console.error(err);
  }
  return new Set(JSON.parse(localStorage.getItem("campaignFavorites") || "[]"));
}

function persistFavorites() {
  const objectFavorites = {};
  state.favorites.forEach((id) => {
    objectFavorites[id] = true;
  });
  localStorage.setItem("favorites", JSON.stringify(objectFavorites));
  localStorage.setItem("campaignFavorites", JSON.stringify([...state.favorites]));
}

function hydrateHealth(rows) {
  if (!els.healthGrid) return;
  if (!rows.length) {
    els.healthGrid.innerHTML = `<div class="health-item"><strong>Veri yok</strong><span>Bir sonraki taramada olusur</span><small>-</small></div>`;
    return;
  }
  els.healthGrid.innerHTML = rows.map((row) => `
    <div class="health-item ${Number(row.inactive || 0) ? "has-issue" : ""}">
      <strong>${escapeHtml(bankLabel(row.bank || ""))}</strong>
      <span>${row.active || 0} aktif · ${row.inactive || 0} pasif</span>
      <small>${String(row.last_seen || "Tarih yok").slice(0, 10)}</small>
    </div>
  `).join("");
}

function showDetail(data) {
  if (!els.modal) return;
  els.modal.querySelector(".modal-bank").textContent = data.bank || "";
  els.modal.querySelector(".modal-title").textContent = data.title || "";
  els.modal.querySelector(".modal-category").textContent = data.category || "";
  els.modal.querySelector(".modal-reward").textContent = data.reward || "";
  els.modal.querySelector(".modal-date").textContent = data.date || "";
  els.modal.querySelector(".modal-description").textContent = data.description || "Açıklama kaynak sayfada.";
  const link = els.modal.querySelector(".modal-link");
  link.href = data.url || "#";
  link.hidden = !data.url;
  els.modal.showModal();
}

function addManualCampaign(event) {
  event.preventDefault();
  const title = els.manualTitle.value.trim();
  if (!title) return;

  const now = new Date().toISOString();
  const id = `manual-${Date.now()}`;
  const item = {
    id,
    bank: "Manuel Favori",
    bank_label: "Manuel",
    external_id: id,
    title,
    description: els.manualDescription.value.trim(),
    image_url: els.manualImage.value.trim(),
    url: els.manualUrl.value.trim(),
    version: 1,
    first_seen: now,
    last_seen: now,
    last_updated: now,
    is_active: true,
    category: "Genel",
    reward_type: "Fırsat",
    favorite: true,
    brand_code: "MF",
    deadline: null,
    deadline_label: "Manuel",
    deadline_urgent: false,
    highlight: "",
  };

  state.manualCampaigns.unshift(item);
  state.campaigns.unshift(item);
  state.favorites.add(String(id));
  localStorage.setItem("manualCampaigns", JSON.stringify(state.manualCampaigns));
  persistFavorites();
  els.manualForm.reset();
  els.favoritesOnly.checked = true;
  hydrateFilters();
  applyFilters();
}

function fillSelect(select, allLabel, values, labeler = (value) => value) {
  select.innerHTML = `<option value="">${allLabel}</option>` + values.map((value) => `<option value="${escapeAttr(value)}">${escapeHtml(labeler(value))}</option>`).join("");
}

function chip(value, label, selected) {
  return `<button type="button" class="bank-chip ${selected ? "selected" : ""}" data-bank="${escapeAttr(value)}" title="${escapeAttr(value || "Tümü")}">${escapeHtml(label)}</button>`;
}

function unique(values) {
  return [...new Set(values.filter(Boolean))].sort((a, b) => bankLabel(a).localeCompare(bankLabel(b), "tr"));
}

function bankLabel(bank) {
  return labels[bank] || bank;
}

function gainScore(item) {
  const text = `${item.title || ""} ${item.description || ""}`;
  const numbers = [...text.matchAll(/\b\d{2,5}\b/g)].map((match) => Number(match[0]));
  return Math.max(0, ...numbers);
}

function normalizeKazanim(kampanya, aylikHarcama) {
  const text = `${kampanya.highlight || ""} ${kampanya.title || ""} ${kampanya.description || ""}`;
  const normalized = normalize(text);
  const tl = [...text.matchAll(/(\d{2,6}(?:[.,]\d{1,2})?)\s*(?:tl|₺)/gi)].map((match) => parseMoney(match[1]));
  if (tl.length) return Math.max(...tl);

  const percent = [...text.matchAll(/%[\s]*(\d{1,2}(?:[.,]\d{1,2})?)/g)].map((match) => parseMoney(match[1]));
  if (percent.length) return Math.round(aylikHarcama * (Math.max(...percent) / 100));

  const points = [...text.matchAll(/(\d{2,6})\s*(?:puan|chip|bonus|para|worldpuan|bankkart lira)/gi)].map((match) => Number(match[1]));
  if (points.length || normalized.includes("puan")) return Math.round(Math.max(0, ...points) * 0.01);

  const miles = [...text.matchAll(/(\d{2,6})\s*(?:mil|mile)/gi)].map((match) => Number(match[1]));
  if (miles.length || normalized.includes("mil")) return Math.round(Math.max(0, ...miles) * 0.03);

  return gainScore(kampanya);
}

function rewardKindFor(item) {
  const text = `${item.highlight || ""} ${item.title || ""} ${item.description || ""} ${item.reward_type || ""}`;
  const normalized = normalize(text);
  if (/%\s*\d+/.test(text)) return "percent";
  if (/(tl|₺)/i.test(text)) return "tl";
  if (normalized.includes("puan") || normalized.includes("chip") || normalized.includes("bonus")) return "puan";
  if (normalized.includes("mil")) return "mil";
  return slug(item.reward_type || "firsat");
}

function rewardLabelFor(item) {
  const kind = rewardKindFor(item);
  if (kind === "tl") return "TL";
  if (kind === "percent") return "%";
  if (kind === "puan") return "Puan";
  if (kind === "mil") return "Mil";
  return item.reward_type || "Fırsat";
}

function deadlineInfo(item) {
  if (!item.aktif && item.aktif !== undefined) return { label: "Süresi doldu", badgeClass: "deadline-expired", cardClass: "is-expired" };
  if (item.is_active === false) return { label: "Süresi doldu", badgeClass: "deadline-expired", cardClass: "is-expired" };
  const deadlineValue = item.bitis_tarihi || item.deadline;
  if (!deadlineValue) return { label: item.deadline_label || "Tarih kaynakta", badgeClass: "deadline-neutral", cardClass: "" };

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const end = new Date(`${deadlineValue}T00:00:00`);
  if (Number.isNaN(end.getTime())) return { label: item.deadline_label || "Tarih kaynakta", badgeClass: "deadline-neutral", cardClass: "" };
  const days = Math.ceil((end - today) / 86400000);
  if (days <= 0) return { label: "Süresi doldu", badgeClass: "deadline-expired", cardClass: "is-expired" };
  if (days <= 3) return { label: `🔴 ${days} gün`, badgeClass: "deadline-danger pulse", cardClass: "deadline-danger-card" };
  if (days <= 14) return { label: `⚠ ${days} gün`, badgeClass: "deadline-warning", cardClass: "deadline-warning-card" };
  return { label: `${days} gün`, badgeClass: "deadline-neutral", cardClass: "" };
}

function parseMoney(value) {
  return Number(String(value || "0").replace(/\./g, "").replace(",", ".")) || 0;
}

function formatCurrency(value) {
  return `${Math.round(value || 0).toLocaleString("tr-TR")}₺`;
}

function bankCode(item) {
  return String(item.brand_code || bankLabel(item.bank || "KR").replace(/[^A-Za-zÇĞİÖŞÜçğıöşü0-9 ]/g, "").split(/\s+/).map((part) => part[0]).join("").slice(0, 2) || "KR").toUpperCase();
}

function bankColor(seed) {
  const palette = ["#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#8b5cf6"];
  let hash = 0;
  for (const char of String(seed || "KR")) hash = (hash * 31 + char.charCodeAt(0)) >>> 0;
  return palette[hash % palette.length];
}

function updateMonthlySpendLabel() {
  if (els.monthlySpendValue) els.monthlySpendValue.textContent = formatCurrency(state.monthlySpend);
}

function showLoadingState() {
  if (!els.campaigns) return;
  els.campaigns.innerHTML = `
    <div class="state-panel loading-state" aria-live="polite">
      <svg class="loading-spinner" width="24" height="24" viewBox="0 0 24 24" aria-hidden="true">
        <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="3" opacity=".18"></circle>
        <path d="M21 12a9 9 0 0 0-9-9" fill="none" stroke="currentColor" stroke-linecap="round" stroke-width="3"></path>
      </svg>
      <h2>Kampanyalar yükleniyor...</h2>
      <div class="skeleton-state-grid" aria-hidden="true">
        ${Array.from({ length: 3 }).map(() => `
          <div class="skeleton-state-card">
            <div class="skeleton skeleton-title"></div>
            <div class="skeleton skeleton-line"></div>
            <div class="skeleton skeleton-line short"></div>
            <div class="skeleton skeleton-footer"></div>
          </div>
        `).join("")}
      </div>
    </div>
  `;
}

function showEmptyState(filterContext) {
  const context = filterContext || "Seçili filtreler";
  els.campaigns.innerHTML = `
    <div class="state-panel empty-state" aria-live="polite">
      <svg class="state-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <circle cx="11" cy="11" r="7"></circle>
        <path d="m20 20-3.5-3.5"></path>
      </svg>
      <h2>Sonuç bulunamadı</h2>
      <p><strong>${escapeHtml(context)}</strong> için kampanya yok. Filtreleri değiştirmeyi deneyin.</p>
      <div class="state-actions">
        <button type="button" class="apply-button" data-clear-filters>Filtreleri Temizle</button>
        <button type="button" class="secondary-button" data-show-all>Tüm Kampanyaları Gör</button>
      </div>
    </div>
  `;
  const clearButton = els.campaigns.querySelector("[data-clear-filters]");
  const showAllButton = els.campaigns.querySelector("[data-show-all]");
  if (clearButton) clearButton.addEventListener("click", clearFilters);
  if (showAllButton) showAllButton.addEventListener("click", showAllCampaigns);
}

function showErrorState(errorMsg) {
  console.error(errorMsg);
  const detail = errorMsg && errorMsg.message ? errorMsg.message : String(errorMsg || "Bilinmeyen hata");
  els.campaigns.innerHTML = `
    <div class="state-panel error-state" aria-live="assertive">
      <svg class="state-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M10.3 4.1 2.7 18a2 2 0 0 0 1.7 3h15.2a2 2 0 0 0 1.7-3L13.7 4.1a2 2 0 0 0-3.4 0Z"></path>
        <path d="M12 9v4"></path>
        <path d="M12 17h.01"></path>
      </svg>
      <h2>Veriler yüklenemedi</h2>
      <p>Teknik detay: ${escapeHtml(detail)}</p>
      <div class="state-actions">
        <button type="button" class="apply-button" data-retry-load>Tekrar Dene</button>
        <a class="secondary-link" href="https://github.com/mericucan-bot/campaign_pipeline_new/issues" target="_blank" rel="noreferrer">GitHub'da bildir</a>
      </div>
    </div>
  `;
  const retryButton = els.campaigns.querySelector("[data-retry-load]");
  if (retryButton) retryButton.addEventListener("click", () => location.reload());
}

function clearFilters() {
  resetFilters(true);
}

function showAllCampaigns() {
  resetFilters(false);
}

function resetFilters(activeOnly) {
  els.bankFilter.value = "";
  els.categoryFilter.value = "";
  els.rewardFilter.value = "";
  els.sortFilter.value = "updated";
  els.searchInput.value = "";
  els.activeOnly.checked = activeOnly;
  els.favoritesOnly.checked = false;
  els.myCardsOnly.checked = false;
  applyFilters();
}

function activeFilterContext() {
  const parts = [];
  if (els.bankFilter.value) parts.push(bankLabel(els.bankFilter.value));
  if (els.categoryFilter.value) parts.push(els.categoryFilter.value);
  if (els.rewardFilter.value) parts.push(els.rewardFilter.value);
  if (els.searchInput.value.trim()) parts.push(`Arama: ${els.searchInput.value.trim()}`);
  if (els.activeOnly.checked) parts.push("Aktif kampanyalar");
  if (els.favoritesOnly.checked) parts.push("Favoriler");
  if (els.myCardsOnly.checked) parts.push("Benim kartlarım");
  return parts.join(", ") || "Tüm kampanyalar";
}

function normalize(value) {
  value = String(value || "").replaceAll("yurtdışı", "yurt dışı").replaceAll("yurtdisi", "yurt disi");
  return String(value || "").toLocaleLowerCase("tr-TR").replaceAll("ı", "i").replaceAll("ğ", "g").replaceAll("ş", "s").replaceAll("ö", "o").replaceAll("ü", "u").replaceAll("ç", "c").normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

function slug(value) {
  return normalize(value).replace(/[^a-z0-9]+/g, "-");
}

function escapeHtml(value) {
  return String(value || "").replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" }[char]));
}

function escapeAttr(value) {
  return escapeHtml(value);
}
