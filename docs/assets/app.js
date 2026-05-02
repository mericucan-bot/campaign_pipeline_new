const state = {
  campaigns: [],
  filtered: [],
  selectedBank: "",
  favorites: new Set(JSON.parse(localStorage.getItem("campaignFavorites") || "[]")),
  manualCampaigns: JSON.parse(localStorage.getItem("manualCampaigns") || "[]"),
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
  backToTop: document.querySelector(".back-to-top"),
  modal: document.querySelector(".detail-modal"),
  modalClose: document.querySelector(".modal-close"),
};

fetch("./data/campaigns.json", { cache: "no-store" })
  .then((response) => response.json())
  .then((payload) => {
    state.campaigns = [...(payload.campaigns || []), ...state.manualCampaigns];
    hydrateStats(payload);
    hydrateHealth(payload.health || []);
    hydrateFilters();
    bindEvents();
    applyFilters();
  })
  .catch(() => {
    els.campaigns.innerHTML = emptyState("Veri okunamadi", "GitHub Actions henuz kampanya verisini uretmemis olabilir.");
  });

function hydrateStats(payload) {
  const stats = payload.stats || {};
  els.activeCount.textContent = stats.active || 0;
  els.bankCount.textContent = stats.bank_count || unique(state.campaigns.map((item) => item.bank)).length;
  els.favoriteCount.textContent = state.favorites.size;
  if (payload.generated_at) {
    els.generatedAt.textContent = `Son guncelleme: ${new Date(payload.generated_at).toLocaleString("tr-TR")}`;
  }
}

function hydrateFilters() {
  fillSelect(els.bankFilter, "Tumu", unique(state.campaigns.map((item) => item.bank)), (bank) => bankLabel(bank));
  fillSelect(els.categoryFilter, "Tum kategoriler", unique(state.campaigns.map((item) => item.category)));
  fillSelect(els.rewardFilter, "Tum kazanimlar", unique(state.campaigns.map((item) => item.reward_type)));
  renderBankRail();
}

function bindEvents() {
  [els.bankFilter, els.categoryFilter, els.rewardFilter, els.sortFilter, els.searchInput, els.activeOnly, els.favoritesOnly, els.myCardsOnly].forEach((el) => {
    el.addEventListener("input", applyFilters);
    el.addEventListener("change", applyFilters);
  });
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
      && (!myCardsOnly || myCards.has(item.bank))
      && (!query || haystack.includes(query));
  });

  rows = sortRows(rows, els.sortFilter.value);
  state.filtered = rows;
  renderBankRail();
  renderCampaigns();
  const total = state.campaigns.length;
  const inactive = state.campaigns.filter((item) => !item.is_active).length;
  els.statSubline.textContent = `${rows.length} sonuc · ${total} kayit · ${inactive} pasif`;
  els.favoriteCount.textContent = state.favorites.size;
}

function sortRows(rows, sort) {
  const clone = [...rows];
  if (sort === "deadline") {
    return clone.sort((a, b) => (a.deadline || "9999-12-31").localeCompare(b.deadline || "9999-12-31"));
  }
  if (sort === "gain") {
    return clone.sort((a, b) => gainScore(b) - gainScore(a));
  }
  if (sort === "bank") {
    return clone.sort((a, b) => `${a.bank}${a.title}`.localeCompare(`${b.bank}${b.title}`));
  }
  return clone.sort((a, b) => String(b.last_seen || "").localeCompare(String(a.last_seen || "")));
}

function renderBankRail() {
  const banks = unique(state.campaigns.map((item) => item.bank));
  els.bankRail.innerHTML = [
    chip("", "Tumu", !state.selectedBank),
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
    els.campaigns.innerHTML = els.favoritesOnly.checked
      ? emptyState("Henuz favori kampanyan yok", "Begendigin kampanyalarin yildizina bas; sonra burada sadece takip ettiklerini gor.")
      : emptyState("Kayit yok", "Filtreleri gevselt veya aramani degistir.");
    return;
  }

  els.campaigns.innerHTML = state.filtered.map((item) => card(item)).join("");
  els.campaigns.querySelectorAll(".favorite-button").forEach((button) => {
    button.addEventListener("click", () => {
      const id = button.dataset.id;
      if (state.favorites.has(id)) state.favorites.delete(id);
      else state.favorites.add(id);
      localStorage.setItem("campaignFavorites", JSON.stringify([...state.favorites]));
      applyFilters();
    });
  });
  els.campaigns.querySelectorAll(".detail-button").forEach((button) => {
    button.addEventListener("click", () => showDetail(button.dataset));
  });
}

function card(item) {
  const favorite = state.favorites.has(String(item.id));
  return `
    <article class="campaign-card">
      <a class="media" href="${escapeAttr(item.url || "#")}" target="_blank" rel="noreferrer">
        ${item.image_url ? `<img src="${escapeAttr(item.image_url)}" alt="" loading="lazy">` : `<span>${escapeHtml(item.brand_code || "KR")}</span>`}
      </a>
      <div class="campaign-body">
        <div class="campaign-topline">
          <span class="brand-badge">${escapeHtml(item.brand_code || "KR")}</span>
          <div class="campaign-meta">
            <span class="bank-name">${escapeHtml(item.bank || "")}</span>
            <span class="status ${item.is_active ? "active" : "inactive"}">${item.is_active ? "Aktif" : "Pasif"}</span>
          </div>
          <button class="favorite-button ${favorite ? "selected" : ""}" data-id="${item.id}" title="Favorilere ekle">&#9733;</button>
        </div>
        <div class="badges">
          <span class="category-badge category-${slug(item.category)}">${escapeHtml(item.category || "Genel")}</span>
          <span class="reward-badge reward-${slug(item.reward_type)}">${escapeHtml(item.reward_type || "Firsat")}</span>
          <span class="date-badge">${escapeHtml(item.deadline_label || "Tarih kaynakta")}</span>
          ${item.deadline_urgent ? `<span class="urgent-badge">Bitiyor</span>` : ""}
        </div>
        <h2>${escapeHtml(item.title || "")}</h2>
        ${item.highlight ? `<strong class="campaign-highlight">${escapeHtml(item.highlight)}</strong>` : ""}
        ${item.description ? `<p>${escapeHtml(item.description)}</p>` : ""}
        <div class="campaign-footer">
          <span>v${item.version || 1} · ${String(item.last_seen || "").slice(0, 10)}</span>
          <button class="detail-button" type="button"
            data-title="${escapeAttr(item.title || "")}"
            data-bank="${escapeAttr(item.bank || "")}"
            data-category="${escapeAttr(item.category || "Genel")}"
            data-reward="${escapeAttr(item.reward_type || "Firsat")}"
            data-date="${escapeAttr(item.deadline_label || "Tarih kaynakta")}"
            data-description="${escapeAttr(item.description || "")}"
            data-url="${escapeAttr(item.url || "")}">Detay</button>
          ${item.url ? `<a href="${escapeAttr(item.url)}" target="_blank" rel="noreferrer">Kaynak</a>` : ""}
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
    <div class="health-item">
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
  els.modal.querySelector(".modal-description").textContent = data.description || "Aciklama kaynak sayfada.";
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
    reward_type: "Firsat",
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
  return `<button type="button" class="bank-chip ${selected ? "selected" : ""}" data-bank="${escapeAttr(value)}" title="${escapeAttr(value || "Tumu")}">${escapeHtml(label)}</button>`;
}

function emptyState(title, text) {
  return `<div class="empty"><div class="empty-icon" aria-hidden="true">&#9733;</div><h2>${title}</h2><p>${text}</p></div>`;
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

function normalize(value) {
  value = String(value || "").replaceAll("yurtdışı", "yurt dışı").replaceAll("yurtdisi", "yurt disi");
  return String(value || "").toLocaleLowerCase("tr-TR").replaceAll("ı", "i").normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/ğ/g, "g").replace(/ş/g, "s").replace(/ö/g, "o").replace(/ü/g, "u").replace(/ç/g, "c");
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
