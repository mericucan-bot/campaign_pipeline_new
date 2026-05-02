const state = {
  campaigns: [],
  filtered: [],
  selectedBank: "",
  favorites: new Set(JSON.parse(localStorage.getItem("campaignFavorites") || "[]")),
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
    showEmptyState(els.favoritesOnly.checked ? "favorites" : "filters");
    return;
  }

  els.campaigns.innerHTML = state.filtered.map((item) => card(item)).join("");
  els.campaigns.querySelectorAll(".favorite-button").forEach((button) => {
    button.addEventListener("click", () => {
      const id = button.dataset.id;
      if (state.favorites.has(id)) state.favorites.delete(id);
      else state.favorites.add(id);
      localStorage.setItem("campaignFavorites", JSON.stringify([...state.favorites]));
      button.classList.add("is-bumping");
      setTimeout(() => button.classList.remove("is-bumping"), 260);
      applyFilters();
    });
  });
  els.campaigns.querySelectorAll(".detail-button").forEach((button) => {
    button.addEventListener("click", () => showDetail(button.dataset));
  });
}

function card(item) {
  const favorite = state.favorites.has(String(item.id));
  const gain = normalizeKazanim(item, state.monthlySpend);
  const rewardKind = rewardKindFor(item);
  const deadline = deadlineInfo(item);
  const logoStyle = `--logo-bg:${bankColor(item.bank || item.brand_code || "KR")}`;
  const logo = item.image_url
    ? `<img src="${escapeAttr(item.image_url)}" alt="" loading="lazy">`
    : `<span class="media-monogram" style="${logoStyle}">${escapeHtml(bankCode(item))}</span>`;
  return `
    <article class="campaign-card ${deadline.cardClass}" data-id="${escapeAttr(item.id)}">
      <a class="media" href="${escapeAttr(item.url || "#")}" target="_blank" rel="noreferrer">
        ${logo}
      </a>
      <div class="campaign-body">
        <div class="campaign-topline">
          <span class="brand-badge" style="${logoStyle}">${escapeHtml(bankCode(item))}</span>
          <div class="campaign-meta">
            <span class="bank-name">${escapeHtml(item.bank || "")}</span>
            <span class="status ${item.is_active ? "active" : "inactive"}">${item.is_active ? "Aktif" : "Pasif"}</span>
          </div>
          <button class="favorite-button ${favorite ? "selected" : ""}" data-id="${item.id}" title="Favorilere ekle">&#9733;</button>
        </div>
        <div class="badges">
          <span class="category-badge category-${slug(item.category)}">${escapeHtml(item.category || "Genel")}</span>
          <span class="reward-badge reward-${rewardKind}">${escapeHtml(rewardLabelFor(item))}</span>
          <span class="gain-badge">≈ ${formatCurrency(gain)}</span>
          <span class="date-badge ${deadline.badgeClass}">${escapeHtml(deadline.label)}</span>
          ${item.deadline_urgent ? `<span class="urgent-badge">Bitiyor</span>` : ""}
        </div>
        <h2>${escapeHtml(item.title || "")}</h2>
        ${item.highlight ? `<strong class="campaign-highlight">${escapeHtml(item.highlight)}</strong>` : ""}
        ${item.description ? `<p>${escapeHtml(item.description)}</p>` : ""}
        <div class="campaign-footer">
          <span>Kaynak: ${escapeHtml(bankLabel(item.bank || ""))} · ${String(item.last_seen || item.first_seen || "").slice(0, 10) || "Tarih yok"}</span>
          <button class="detail-button" type="button"
            data-title="${escapeAttr(item.title || "")}"
            data-bank="${escapeAttr(item.bank || "")}"
            data-category="${escapeAttr(item.category || "Genel")}"
            data-reward="${escapeAttr(item.reward_type || "Fırsat")}"
            data-date="${escapeAttr(item.deadline_label || "Tarih kaynakta")}"
            data-description="${escapeAttr(item.description || "")}"
            data-url="${escapeAttr(item.url || "")}">Detay</button>
          ${item.url ? `<a href="${escapeAttr(item.url)}" target="_blank" rel="noreferrer">Kaynak <span class="external-icon" aria-hidden="true">↗</span></a>` : ""}
        </div>
      </div>
    </article>
  `;
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
  localStorage.setItem("campaignFavorites", JSON.stringify([...state.favorites]));
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

function emptyState(title, text, clearable = false) {
  return `
    <div class="empty">
      <div class="empty-icon" aria-hidden="true">&#8981;</div>
      <h2>${title}</h2>
      <p>${text}</p>
      ${clearable ? `<button type="button" class="apply-button" data-clear-filters>Filtreleri temizle</button>` : ""}
    </div>
  `;
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
  if (!item.is_active) return { label: "Doldu", badgeClass: "deadline-expired", cardClass: "is-expired" };
  if (!item.deadline) return { label: item.deadline_label || "Tarih kaynakta", badgeClass: "deadline-neutral", cardClass: "" };

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const end = new Date(`${item.deadline}T00:00:00`);
  if (Number.isNaN(end.getTime())) return { label: item.deadline_label || "Tarih kaynakta", badgeClass: "deadline-neutral", cardClass: "" };
  const days = Math.ceil((end - today) / 86400000);
  if (days < 0) return { label: "Doldu", badgeClass: "deadline-expired", cardClass: "is-expired" };
  if (days === 0) return { label: "Bugün bitiyor", badgeClass: "deadline-danger pulse", cardClass: "deadline-danger-card" };
  if (days <= 3) return { label: `${days} gün kaldı`, badgeClass: "deadline-danger pulse", cardClass: "deadline-danger-card" };
  if (days <= 14) return { label: `${days} gün kaldı`, badgeClass: "deadline-warning", cardClass: "deadline-warning-card" };
  return { label: `${days} gün kaldı`, badgeClass: "deadline-neutral", cardClass: "" };
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
  const palette = ["#1a56db", "#10b981", "#7c3aed", "#f59e0b", "#0891b2", "#dc2626", "#4338ca", "#0f766e"];
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
    <div class="skeleton-grid" aria-hidden="true">
      ${Array.from({ length: 6 }).map(() => `<div class="skeleton-card"><span></span><b></b><i></i><i></i></div>`).join("")}
    </div>
  `;
}

function showEmptyState(ctx) {
  const title = ctx === "favorites" ? "Henüz favori kampanyan yok" : "Kayıt yok";
  const text = ctx === "favorites"
    ? "Beğendiğin kampanyaların yıldızına bas; sonra burada sadece takip ettiklerini gör."
    : "Filtreleri gevşet veya aramanı değiştir.";
  els.campaigns.innerHTML = emptyState(title, text, true);
  const clearButton = els.campaigns.querySelector("[data-clear-filters]");
  if (clearButton) clearButton.addEventListener("click", clearFilters);
}

function showErrorState(err) {
  console.error(err);
  els.campaigns.innerHTML = `
    <div class="empty error-state">
      <div class="empty-icon" aria-hidden="true">!</div>
      <h2>Veri okunamadı</h2>
      <p>Veri hazırlanırken sorun oluştu. Biraz sonra tekrar deneyebilirsin.</p>
      <div class="empty-actions">
        <button type="button" class="apply-button" onclick="location.reload()">Tekrar dene</button>
        <a href="https://github.com/mericucan-bot/campaign_pipeline_new/issues" target="_blank" rel="noreferrer">GitHub issue aç</a>
      </div>
    </div>
  `;
}

function clearFilters() {
  els.bankFilter.value = "";
  els.categoryFilter.value = "";
  els.rewardFilter.value = "";
  els.sortFilter.value = "updated";
  els.searchInput.value = "";
  els.activeOnly.checked = true;
  els.favoritesOnly.checked = false;
  els.myCardsOnly.checked = false;
  applyFilters();
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
