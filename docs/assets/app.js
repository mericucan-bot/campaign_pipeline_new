const state = {
  campaigns: [],
  filtered: [],
  selectedBank: "",
  favorites: loadFavoriteSet(),
  used: loadUsed(),
  pendingUsedId: null,
  manualCampaigns: JSON.parse(localStorage.getItem("manualCampaigns") || "[]"),
  monthlySpend: Number(localStorage.getItem("kr-aylik-harcama") || localStorage.getItem("monthlySpend") || 2000),
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

const kategoriHaritasi = {
  market: "market",
  Market: "market",
  "süpermarket": "market",
  supermarket: "market",
  "Süpermarket": "market",
  restoran: "restoran",
  Restoran: "restoran",
  yemek: "restoran",
  akaryakıt: "yakit",
  akaryakit: "yakit",
  "Akaryakıt": "yakit",
  yakıt: "yakit",
  yakit: "yakit",
  online: "online",
  Online: "online",
  "e-ticaret": "online",
  eticaret: "online",
  seyahat: "diger",
  Seyahat: "diger",
  genel: "diger",
  Genel: "diger",
  ulaşım: "diger",
  ulasim: "diger",
  "Ulaşım": "diger",
};

const HESAP_KATEGORILERI = new Set([
  "market", "Market", "Süpermarket", "süpermarket",
  "restoran", "Restoran", "Yemek", "yemek", "Cafe", "cafe",
  "akaryakıt", "Akaryakıt", "yakıt", "Yakıt",
  "online", "Online", "e-ticaret", "E-ticaret",
  "ulaşım", "Ulaşım", "seyahat", "Seyahat",
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
  usedOnly: document.querySelector("#usedOnly"),
  calculatorOnly: document.querySelector("#calculatorOnly"),
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
  monthlySpendValue: document.querySelector("#harcama-val") || document.querySelector("#monthlySpendValue"),
  backToTop: document.querySelector(".back-to-top"),
  modal: document.querySelector(".detail-modal"),
  modalClose: document.querySelector(".modal-close"),
  settingsDrawer: document.querySelector(".settings-drawer"),
  settingsOpen: document.querySelector("[data-settings-open]"),
  settingsClose: document.querySelector("[data-settings-close]"),
  statusDrawer: document.querySelector(".status-drawer"),
  statusOpen: document.querySelector("[data-status-open]"),
  statusClose: document.querySelector("[data-status-close]"),
  manualDrawer: document.querySelector(".manual-drawer"),
  manualOpen: document.querySelector("[data-manual-open]"),
  manualClose: document.querySelector("[data-manual-close]"),
  toolbar: document.querySelector(".filter-toolbar"),
  calculatorPanel: document.querySelector("#calculatorPanel"),
  calculatorResult: document.querySelector("#kalk-sonuc"),
  usedHistory: document.querySelector("#usedHistory"),
  usedSummary: document.querySelector("#usedSummary"),
  exportUsed: document.querySelector("#exportUsed"),
  clearUsed: document.querySelector("#clearUsed"),
  usedModal: document.querySelector("#usedModal"),
  usedForm: document.querySelector("#usedForm"),
  usedCancel: document.querySelector("#usedCancel"),
  usedModalClose: document.querySelector(".used-modal-close"),
  usedBank: document.querySelector("#usedBank"),
  usedTitle: document.querySelector("#usedTitle"),
  usedGain: document.querySelector("#usedGain"),
  usedNote: document.querySelector("#usedNote"),
};

function closeBanner() {
  const banner = document.getElementById("info-banner");
  if (banner) banner.style.display = "none";
  localStorage.setItem("kr-banner-closed", "1");
}

if (localStorage.getItem("kr-banner-closed") === "1") {
  const banner = document.getElementById("info-banner");
  if (banner) banner.style.display = "none";
}

showLoadingState();

fetch("./data/campaigns.json", { cache: "no-store" })
  .then((response) => response.json())
  .then((payload) => {
    state.campaigns = [...(payload.campaigns || []), ...state.manualCampaigns];
    hydrateStats(payload);
    hydrateHealth(payload.health || []);
    hydrateFilters();
    hydrateMyCards();
    renderUsedHistory();
    initPreferredFlow();
    bindEvents();
    requestNotificationPermission();
    checkNotifs();
    syncFavoriteNotifications();
    initCalculator();
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
  [els.bankFilter, els.categoryFilter, els.rewardFilter, els.sortFilter, els.searchInput, els.activeOnly, els.favoritesOnly, els.myCardsOnly, els.usedOnly].forEach((el) => {
    el.addEventListener("input", applyFilters);
    el.addEventListener("change", applyFilters);
  });
  [els.activeOnly, els.favoritesOnly, els.myCardsOnly, els.usedOnly].forEach((el) => {
    el.addEventListener("change", () => {
      if (els.calculatorOnly) els.calculatorOnly.checked = false;
      switchCalculatorMode(false);
      applyFilters();
    });
  });
  if (els.calculatorOnly) {
    els.calculatorOnly.addEventListener("change", () => {
      switchCalculatorMode(els.calculatorOnly.checked);
      if (!els.calculatorOnly.checked) applyFilters();
    });
  }
  if (els.monthlySpend) {
    els.monthlySpend.value = state.monthlySpend;
    updateMonthlySpendLabel();
    els.monthlySpend.addEventListener("input", () => {
      updateHarcama(els.monthlySpend.value);
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
  if (els.usedForm && els.usedModal) {
    els.usedForm.addEventListener("submit", saveUsedFromModal);
    [els.usedCancel, els.usedModalClose].forEach((button) => {
      if (button) button.addEventListener("click", closeUsedModal);
    });
    els.usedModal.addEventListener("click", (event) => {
      if (event.target === els.usedModal) closeUsedModal();
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
  bindDrawer(els.statusOpen, els.statusClose, els.statusDrawer);
  bindDrawer(els.manualOpen, els.manualClose, els.manualDrawer);
  bindToolbarScroll();
  if (els.exportUsed) els.exportUsed.addEventListener("click", exportData);
  if (els.clearUsed) els.clearUsed.addEventListener("click", clearUsedHistory);
}

function bindToolbarScroll() {
  if (!els.toolbar) return;
  const update = () => els.toolbar.classList.toggle("is-stuck", window.scrollY > 24);
  update();
  window.addEventListener("scroll", update, { passive: true });
}

function bindDrawer(openButton, closeButton, drawer) {
  if (!drawer) return;
  if (openButton) openButton.addEventListener("click", () => drawer.showModal());
  if (closeButton) closeButton.addEventListener("click", () => drawer.close());
  drawer.addEventListener("click", (event) => {
    if (event.target === drawer) drawer.close();
  });
}

function initPreferredFlow() {
  if (els.myCardsOnly && localStorage.getItem("myCards")) {
    els.myCardsOnly.checked = true;
  }
}

function switchCalculatorMode(enabled) {
  if (enabled) clearFlowToggles();
  if (els.toolbar) els.toolbar.style.display = enabled ? "none" : "";
  if (els.campaigns) els.campaigns.style.display = enabled ? "none" : "";
  if (els.calculatorPanel) els.calculatorPanel.hidden = !enabled;
  if (els.statSubline) els.statSubline.style.display = enabled ? "none" : "";
  const footer = document.querySelector(".site-disclaimer");
  if (footer) footer.style.display = enabled ? "none" : "";
  if (enabled) {
    hesapla();
  }
}

function clearFlowToggles() {
  [els.activeOnly, els.favoritesOnly, els.myCardsOnly, els.usedOnly].forEach((input) => {
    if (input) input.checked = false;
  });
}

function applyFilters() {
  if (els.calculatorOnly?.checked) {
    switchCalculatorMode(true);
    return;
  }
  switchCalculatorMode(false);
  state.selectedBank = els.bankFilter.value;
  const query = normalizeSearch(els.searchInput.value);
  const category = els.categoryFilter.value;
  const reward = els.rewardFilter.value;
  const activeOnly = els.activeOnly.checked;
  const favoritesOnly = els.favoritesOnly.checked;
  const myCardsOnly = els.myCardsOnly.checked;
  const usedOnly = els.usedOnly.checked;

  let rows = state.campaigns.filter((item) => {
    const haystack = normalizeSearch(`${item.title || ""} ${item.description || ""} ${item.bank || ""} ${item.highlight || ""} ${item.category || ""}`);
    return (!state.selectedBank || item.bank === state.selectedBank)
      && (!category || item.category === category)
      && (!reward || item.reward_type === reward)
      && (!activeOnly || item.is_active)
      && (!favoritesOnly || state.favorites.has(String(item.id)))
      && (!myCardsOnly || state.myCards.has(item.bank))
      && (!usedOnly || Boolean(state.used[String(item.id)]))
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
    return clone
      .map((item) => ({ ...item, normalized: normalizeKazanim(item, calculatorSpendMap()) }))
      .sort((a, b) => b.normalized - a.normalized);
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

  els.campaigns.innerHTML = `${urgentFavoritesBanner()}${state.filtered.map((item) => card(item)).join("")}`;
  const urgentButton = els.campaigns.querySelector("[data-filter-urgent]");
  if (urgentButton) urgentButton.addEventListener("click", filterUrgent);
  els.campaigns.querySelectorAll(".favorite-button").forEach((button) => {
    button.addEventListener("click", () => {
      const id = button.dataset.id;
      if (state.favorites.has(id)) {
        state.favorites.delete(id);
        unscheduleNotif(id);
      } else {
        state.favorites.add(id);
        const campaign = state.campaigns.find((item) => String(item.id) === id);
        if (campaign) scheduleNotif(adaptCampaign(campaign));
      }
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
  els.campaigns.querySelectorAll(".used-button").forEach((button) => {
    button.addEventListener("click", () => markUsed(button.dataset.id));
  });
  els.campaigns.querySelectorAll(".detail-button").forEach((button) => {
    button.addEventListener("click", () => showDetail(button.dataset));
  });
}

function card(item) {
  const data = adaptCampaign(item);
  const favorite = state.favorites.has(String(data.id));
  const usedData = state.used[String(data.id)];
  const reward = rewardBadge(data);
  const deadline = deadlineInfo(data);
  const urgent = urgencyInfo(data);
  const normalized = normalizeKazanim(data, calculatorSpendMap());
  const logoStyle = `--logo-bg:${bankColor(data.banka)}`;
  const logo = data.gorsel_url
    ? `<img src="${escapeAttr(data.gorsel_url)}" alt="" loading="lazy">`
    : `<span style="${logoStyle}">${escapeHtml(bankInitials(data.banka))}</span>`;
  return `
    <article id="card-${escapeAttr(data.id)}" class="campaign-card radar-card ${deadline.cardClass} ${urgent.cardClass} ${usedData ? "used-card" : ""}" data-id="${escapeAttr(data.id)}">
      <div class="card-header">
        <div class="bank-logo" style="${logoStyle}">${logo}</div>
        <div class="card-bank-meta">
          <strong>${escapeHtml(data.banka)}</strong>
          <span class="category-badge badge-kategori ${categoryClass(data.kategori)}" data-kategori="${escapeAttr(data.kategori || "Genel")}">${escapeHtml(data.kategori)}</span>
        </div>
        <div class="favorite-wrap">
          <button class="favorite-button ${favorite ? "selected" : ""}" data-id="${escapeAttr(data.id)}" title="Favorilere ekle" aria-label="Favorilere ekle">${favorite ? "★" : "☆"}</button>
          ${favorite && urgent.isUrgent ? `<span class="favorite-urgent-dot" aria-label="Acil favori"></span>` : ""}
        </div>
      </div>

      <div class="card-body">
        <h2 class="card-title" title="${escapeAttr(data.fullTitle || data.baslik)}">${escapeHtml(data.baslik)}</h2>
        ${data.aciklama ? `<p class="card-description">${escapeHtml(data.aciklama)}</p>` : ""}
      </div>

      <div class="card-footer">
        ${reward ? `<span class="reward-badge ${reward.className}">${escapeHtml(reward.label)}</span>` : ""}
        ${normalized >= 1 && isSpendRewardCampaign(data) ? `<span class="gain-badge">≈ ${Math.round(normalized).toLocaleString("tr-TR")}₺ değerinde</span>` : ""}
        ${deadline.hidden ? "" : `<span class="date-badge ${deadline.badgeClass}">${escapeHtml(deadline.label)}</span>`}
        ${urgent.badge ? `<span class="urgent-badge ${urgent.badgeClass}">${escapeHtml(urgent.badge)}</span>` : ""}
      </div>

      <div class="card-source">
        <button class="source-button" type="button" data-url="${escapeAttr(data.kaynak_url)}">Kaynağa git <span aria-hidden="true">↗</span></button>
        <button id="used-${escapeAttr(data.id)}" class="used-button ${usedData ? "is-used" : ""}" type="button" data-id="${escapeAttr(data.id)}" ${usedData ? "disabled" : ""}>${usedData ? `✓ Kullanıldı (${escapeHtml(usedData.tarih)})` : "✓ Kullandım"}</button>
        <span class="source-disclaimer">Kaynak: ${escapeHtml(data.banka)} resmi sitesi • ${escapeHtml(data.sourceDate)}</span>
      </div>
    </article>
  `;
}

function adaptCampaign(item) {
  const rawTitle = item.baslik || item.title || "";
  const rawDescription = item.aciklama || item.description || "";
  const text = compactCampaignText(rawTitle, rawDescription);
  return {
    id: item.id,
    baslik: text.baslik,
    aciklama: text.aciklama,
    fullTitle: String(rawTitle || "").replace(/\s+/g, " ").trim(),
    banka: item.banka || item.bank || "Kampanya",
    kategori: item.kategori || item.category || "Genel",
    kazanim: item.kazanim || item.highlight || normalizeKazanim(item, state.monthlySpend),
    kazanim_turu: item.kazanim_turu || rewardLabelFor(item),
    min_harcama: parseMoney(item.min_harcama || item.min_spend || 0),
    max_kazanim: parseMoney(item.max_kazanim || item.max_reward || 0),
    bitis_tarihi: item.bitis_tarihi || item.deadline || null,
    kaynak_url: item.kaynak_url || item.url || "",
    gorsel_url: item.gorsel_url || item.image_url || "",
    aktif: item.aktif ?? item.is_active ?? true,
    sourceDate: String(item.last_seen || item.first_seen || "").slice(0, 10) || "Tarih yok",
  };
}

function compactCampaignText(title, description) {
  const cleanTitle = String(title || "").replace(/\s+/g, " ").trim();
  const cleanDescription = String(description || "").replace(/\s+/g, " ").trim();
  if (cleanTitle.length <= 120) {
    return { baslik: cleanTitle, aciklama: cleanDescription };
  }

  return {
    baslik: shortenText(cleanTitle, 96),
    aciklama: cleanDescription && !isDeadlineOnlyText(cleanDescription) ? cleanDescription : cleanTitle,
  };
}

function shortenText(text, maxLength) {
  const value = String(text || "").trim();
  if (value.length <= maxLength) return value;
  const cut = value.slice(0, maxLength);
  const lastSpace = cut.lastIndexOf(" ");
  return `${cut.slice(0, lastSpace > 60 ? lastSpace : maxLength).trim()}...`;
}

function isDeadlineOnlyText(text) {
  const value = normalize(text);
  return /^(?:\d+\s+gun\s+kaldi|bu kampanya bitmistir|tarih kaynakta|suresi gecmis)$/.test(value);
}

function rewardBadge(data) {
  if (!isSpendRewardCampaign(data)) return null;
  const type = String(data.kazanim_turu || "").toLowerCase();
  const value = rewardValueText(data.kazanim);
  const amount = parseMoney(value);
  if (!value || !amount || amount <= 0 || Number.isNaN(amount)) return null;
  if (type === "tl") return { className: "reward-card-tl", label: `+${value}₺ cashback` };
  if (type === "%") return { className: "reward-card-percent", label: `+${value}% indirim` };
  if (type === "puan") return { className: "reward-card-puan", label: `+${value} puan` };
  if (type === "mil") return { className: "reward-card-mil", label: `+${value} mil` };
  return null;
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

function loadUsed() {
  try {
    return JSON.parse(localStorage.getItem("kr-used") || "{}") || {};
  } catch (err) {
    console.error(err);
    return {};
  }
}

function persistFavorites() {
  const objectFavorites = {};
  state.favorites.forEach((id) => {
    objectFavorites[id] = true;
  });
  localStorage.setItem("favorites", JSON.stringify(objectFavorites));
  localStorage.setItem("kr-favorites", JSON.stringify(objectFavorites));
  localStorage.setItem("campaignFavorites", JSON.stringify([...state.favorites]));
}

function persistUsed() {
  localStorage.setItem("kr-used", JSON.stringify(state.used));
}

function markUsed(id) {
  if (state.used[id]) return;
  openUsedModal(id);
}

function openUsedModal(id) {
  if (!els.usedModal) return;
  const campaign = state.campaigns.find((item) => String(item.id) === String(id));
  const adapted = campaign ? adaptCampaign(campaign) : null;
  state.pendingUsedId = String(id);
  if (els.usedBank) els.usedBank.textContent = adapted?.banka || "Kampanya";
  if (els.usedTitle) els.usedTitle.textContent = adapted?.baslik || "Kampanyayı kullandım";
  if (els.usedGain) els.usedGain.value = "";
  if (els.usedNote) els.usedNote.value = "";
  els.usedModal.showModal();
}

function closeUsedModal() {
  state.pendingUsedId = null;
  if (els.usedModal?.open) els.usedModal.close();
}

function saveUsedFromModal(event) {
  event.preventDefault();
  const id = state.pendingUsedId;
  if (!id || state.used[id]) return closeUsedModal();
  const gainValue = Number(els.usedGain?.value || 0);
  state.used[id] = {
    tarih: new Date().toLocaleDateString("tr-TR"),
    kazanilan: gainValue > 0 ? gainValue : null,
    not: els.usedNote?.value.trim() || "",
  };
  persistUsed();
  updateUsedButton(id, state.used[id]);
  renderUsedHistory();
  closeUsedModal();
}

function updateUsedButton(id, data) {
  const btn = document.getElementById(`used-${id}`);
  if (!btn) return;
  btn.textContent = `✓ Kullanıldı (${data.tarih})`;
  btn.classList.add("is-used");
  btn.disabled = true;
  const card = document.getElementById(`card-${id}`);
  if (card) card.classList.add("used-card");
}

function renderUsedHistory() {
  if (!els.usedHistory || !els.usedSummary) return;
  const usedList = Object.entries(state.used);
  const toplamKazanilan = usedList.reduce((sum, [, data]) => sum + (Number(data.kazanilan) || 0), 0);
  const hasGain = usedList.some(([, data]) => Number(data.kazanilan) > 0);
  els.usedSummary.textContent = !usedList.length
    ? "0 kampanya kullanıldı"
    : hasGain
    ? `${usedList.length} kampanya kullanıldı • Toplam ≈ ${Math.round(toplamKazanilan).toLocaleString("tr-TR")}₺ kazanıldı`
    : `${usedList.length} kampanya kullanıldı • Kazanım tutarı girilmedi`;
  if (!usedList.length) {
    els.usedHistory.innerHTML = `<p class="history-empty">Henüz kullanılan kampanya yok.</p>`;
    return;
  }
  els.usedHistory.innerHTML = usedList.map(([id, data]) => {
    const campaign = state.campaigns.find((item) => String(item.id) === String(id));
    const adapted = campaign ? adaptCampaign(campaign) : null;
    return `
      <div class="history-item">
        <span>${escapeHtml(data.tarih)} — ${escapeHtml(adapted?.banka || "?")} ${escapeHtml(adapted?.baslik || id)}</span>
        ${data.kazanilan ? `<strong>+${Number(data.kazanilan).toLocaleString("tr-TR")}₺</strong>` : ""}
        ${data.not ? `<small>${escapeHtml(data.not)}</small>` : ""}
      </div>
    `;
  }).join("");
}

function exportData() {
  const favorites = JSON.parse(localStorage.getItem("kr-favorites") || localStorage.getItem("favorites") || "{}");
  const used = JSON.parse(localStorage.getItem("kr-used") || "{}");
  const data = { favorites, used };
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "kampanya-radar-yedek.json";
  a.click();
  URL.revokeObjectURL(a.href);
}

function clearUsedHistory() {
  if (!confirm("Geçmişi temizlemek istediğine emin misin?")) return;
  state.used = {};
  persistUsed();
  renderUsedHistory();
  applyFilters();
}

function urgentFavorites() {
  return state.campaigns
    .map((item) => adaptCampaign(item))
    .filter((item) => state.favorites.has(String(item.id)))
    .map((item) => ({ ...item, urgency: urgencyInfo(item) }))
    .filter((item) => item.urgency.hours > 0 && item.urgency.hours <= 48)
    .sort((a, b) => a.urgency.hours - b.urgency.hours);
}

function urgentFavoritesBanner() {
  const rows = urgentFavorites();
  if (!rows.length) return "";
  return `
    <section class="urgent-banner">
      <div class="urgent-banner-head">
        <strong>⚡ ${rows.length} favori kampanyan 48 saat içinde bitiyor!</strong>
        <button type="button" class="secondary-button" data-filter-urgent>Acil kampanyaları göster</button>
      </div>
      <ul>
        ${rows.map((item) => `<li>• ${escapeHtml(item.banka)} — ${escapeHtml(item.baslik)} — ${item.urgency.hours} saat kaldı</li>`).join("")}
      </ul>
    </section>
  `;
}

function filterUrgent() {
  const rows = urgentFavorites().map((item) => state.campaigns.find((campaign) => String(campaign.id) === String(item.id))).filter(Boolean);
  state.filtered = rows;
  renderCampaigns();
  els.statSubline.textContent = `${rows.length} acil favori · ${state.campaigns.length} kayıt`;
}

function requestNotificationPermission() {
  if ("Notification" in window && Notification.permission === "default") {
    setTimeout(() => Notification.requestPermission(), 3000);
  }
}

function scheduleNotif(kampanya) {
  const bitisTarihi = parseDeadline(kampanya.bitis_tarihi);
  if (!bitisTarihi) return;
  const uyarilar = [
    { zaman: new Date(bitisTarihi - 24 * 3600 * 1000), mesaj: "24 saat kaldı" },
    { zaman: new Date(bitisTarihi - 2 * 3600 * 1000), mesaj: "2 saat kaldı" },
  ].filter((uyari) => uyari.zaman > new Date());
  if (!uyarilar.length) return;
  const kayitli = JSON.parse(localStorage.getItem("kr-notifs") || "{}");
  kayitli[kampanya.id] = uyarilar.map((uyari) => ({ zaman: uyari.zaman.toISOString(), mesaj: uyari.mesaj, gosterildi: false }));
  localStorage.setItem("kr-notifs", JSON.stringify(kayitli));
}

function unscheduleNotif(id) {
  const kayitli = JSON.parse(localStorage.getItem("kr-notifs") || "{}");
  delete kayitli[id];
  localStorage.setItem("kr-notifs", JSON.stringify(kayitli));
}

function checkNotifs() {
  if (!("Notification" in window) || Notification.permission !== "granted") return;
  const kayitli = JSON.parse(localStorage.getItem("kr-notifs") || "{}");
  const simdi = new Date();
  Object.entries(kayitli).forEach(([id, uyarilar]) => {
    uyarilar.forEach((uyari) => {
      if (!uyari.gosterildi && new Date(uyari.zaman) <= simdi) {
        const kampanya = state.campaigns.find((item) => String(item.id) === String(id));
        const data = kampanya ? adaptCampaign(kampanya) : null;
        if (data) new Notification("Kampanya Radar ⏰", { body: `${data.baslik} — ${uyari.mesaj}`, icon: "/favicon.ico" });
        uyari.gosterildi = true;
      }
    });
  });
  localStorage.setItem("kr-notifs", JSON.stringify(kayitli));
}

function syncFavoriteNotifications() {
  state.campaigns.forEach((item) => {
    if (state.favorites.has(String(item.id))) scheduleNotif(adaptCampaign(item));
  });
}

function initCalculator() {
  const saved = JSON.parse(localStorage.getItem("kr-harcamalar") || "{}");
  const defaults = { market: 1500, restoran: 800, yakit: 300, online: 1000, diger: 500 };
  Object.entries({ ...defaults, ...saved }).forEach(([key, value]) => {
    const slider = document.getElementById(`slider-${key}`);
    const manual = document.getElementById(`input-${key}`);
    const amount = Math.max(0, Number(value) || 0);
    if (slider) slider.value = Math.min(amount, Number(slider.max) || 10000);
    if (manual) manual.value = amount;
  });
  ["market", "restoran", "yakit", "online", "diger"].forEach((key) => {
    const slider = document.getElementById(`slider-${key}`);
    const manual = document.getElementById(`input-${key}`);
    if (slider) {
      slider.addEventListener("input", () => {
        if (manual) manual.value = slider.value;
        hesapla();
      });
    }
    if (manual) {
      manual.addEventListener("input", () => {
        const amount = Math.max(0, Number(manual.value) || 0);
        if (slider) slider.value = Math.min(amount, Number(slider.max) || 10000);
        hesapla();
      });
    }
  });
  hesapla();
}

function hesapla() {
  const harcamalar = {
    market: calculatorSpend("market"),
    restoran: calculatorSpend("restoran"),
    yakit: calculatorSpend("yakit"),
    online: calculatorSpend("online"),
    diger: calculatorSpend("diger"),
  };

  Object.keys(harcamalar).forEach((key) => {
    const valueEl = document.getElementById(`v-${key}`);
    if (valueEl) valueEl.textContent = `${harcamalar[key].toLocaleString("tr-TR")}₺`;
  });

  const toplam = Object.values(harcamalar).reduce((total, value) => total + value, 0);
  const totalEl = document.getElementById("toplam-val");
  if (totalEl) totalEl.textContent = `${toplam.toLocaleString("tr-TR")}₺`;

  const sonuclar = state.campaigns
    .filter((item) => item.aktif ?? item.is_active)
    .map((item) => adaptCampaign(item))
    .filter((data) => isCalculatorCategory(data))
    .map((data) => {
      if (!isCalculatorEligible(data, harcamalar)) return { ...data, tahminiKazanim: 0 };
      return { ...data, tahminiKazanim: normalizeKazanim(data, harcamalar) };
    })
    .filter((item) => item.tahminiKazanim > 0)
    .sort((a, b) => b.tahminiKazanim - a.tahminiKazanim)
    .slice(0, 5);

  const tahminiKazanc = sonuclar.reduce((total, item) => total + item.tahminiKazanim, 0);
  const gainEl = document.getElementById("kazanc-val");
  if (gainEl) {
    gainEl.textContent = tahminiKazanc > 0
      ? `≈ ${Math.round(tahminiKazanc).toLocaleString("tr-TR")}₺`
      : "-";
  }

  const resultEl = document.getElementById("kalk-sonuc");
  const rozetler = ["🥇", "🥈", "🥉", "4.", "5."];
  if (resultEl) {
    resultEl.innerHTML = sonuclar.length === 0
      ? `<p>Eşleşen kampanya bulunamadı.</p>`
      : sonuclar.map((item, index) => `
        <button class="calculator-result" type="button" onclick="highlightCard('${escapeAttr(item.id)}')">
          <span class="kampanya-adi" title="${escapeAttr(item.baslik)}">${rozetler[index]} ${escapeHtml(item.banka)} — ${escapeHtml(shortenText(item.baslik, 50))}</span>
          <strong>≈ +${Math.round(item.tahminiKazanim).toLocaleString("tr-TR")}₺</strong>
        </button>
      `).join("");
  }

  localStorage.setItem("kr-harcamalar", JSON.stringify(harcamalar));
}

function calculatorSpend(key) {
  const manual = document.getElementById(`input-${key}`);
  const slider = document.getElementById(`slider-${key}`);
  const amount = Math.max(0, Number(manual?.value || slider?.value || 0));
  if (manual && manual.value !== String(amount)) manual.value = amount;
  if (slider) slider.value = Math.min(amount, Number(slider.max) || 10000);
  return amount;
}

function calculatorSpendMap() {
  const defaults = { market: 2000, restoran: 1000, yakit: 500, online: 1000, diger: 500 };
  try {
    const saved = JSON.parse(localStorage.getItem("kr-harcamalar") || "{}") || {};
    return Object.fromEntries(Object.entries(defaults).map(([key, value]) => [key, Number(saved[key]) || value]));
  } catch (err) {
    console.error(err);
    return defaults;
  }
}

function syncInput(key, val) {
  const input = document.getElementById(`input-${key}`);
  if (input) input.value = val;
  hesapla();
}

function syncSlider(key, val) {
  const slider = document.getElementById(`slider-${key}`);
  if (slider) slider.value = Math.min(Math.max(0, Number(val) || 0), Number(slider.max) || 10000);
  hesapla();
}

function calculatorCategory(item) {
  return sliderKeyForCampaign(item);
}

function categoryClass(category) {
  const text = normalize(category);
  if (text.includes("seyahat") || text.includes("tatil") || text.includes("otel") || text.includes("yurt disi")) return "category-travel";
  if (text.includes("restoran") || text.includes("yemek") || text.includes("cafe") || text.includes("kafe")) return "category-food";
  if (text.includes("market") || text.includes("supermarket") || text.includes("gida")) return "category-market";
  if (text.includes("yakit") || text.includes("akaryakit") || text.includes("benzin")) return "category-fuel";
  if (text.includes("online") || text.includes("internet") || text.includes("alisveris")) return "category-online";
  if (text.includes("firsat")) return "category-opportunity";
  return "category-general";
}

function highlightCard(id) {
  document.querySelectorAll(".campaign-card").forEach((cardEl) => cardEl.classList.remove("calculator-highlight"));
  let el = document.getElementById(`card-${id}`);
  if (!el) {
    const campaign = state.campaigns.find((item) => String(item.id) === String(id));
    if (campaign) {
      els.bankFilter.value = campaign.bank || "";
      els.categoryFilter.value = "";
      els.rewardFilter.value = "";
      els.searchInput.value = "";
      els.activeOnly.checked = false;
      els.favoritesOnly.checked = false;
      els.myCardsOnly.checked = false;
      els.usedOnly.checked = false;
      applyFilters();
      el = document.getElementById(`card-${id}`);
    }
  }
  if (el) {
    el.classList.add("calculator-highlight");
    el.scrollIntoView({ behavior: "smooth", block: "center" });
  }
}

function hydrateHealth(rows) {
  if (!els.healthGrid) return;
  if (!rows.length) {
    els.healthGrid.innerHTML = `<div class="health-item"><strong>Veri yok</strong><span>Bir sonraki taramada olusur</span><small>-</small></div>`;
    return;
  }
  els.healthGrid.innerHTML = rows.map((row) => `
    <div class="health-item ${healthClass(row)}">
      <strong>${escapeHtml(bankLabel(row.bank || ""))}</strong>
      <span>${row.active || 0} aktif · ${row.inactive || 0} pasif</span>
      <small>${escapeHtml(formatHealthTime(row.last_seen))}</small>
    </div>
  `).join("");
}

function healthClass(row) {
  const age = hoursSince(row.last_seen);
  if (age === null) return "health-stale";
  if (age <= 12 && !Number(row.inactive || 0)) return "health-fresh";
  if (age <= 36) return "health-warn";
  return "health-stale";
}

function hoursSince(value) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return (Date.now() - date.getTime()) / 3600000;
}

function formatHealthTime(value) {
  if (!value) return "Tarih yok";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value).slice(0, 10);
  return date.toLocaleString("tr-TR", { day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit" });
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
  if (els.manualDrawer?.open) els.manualDrawer.close();
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

function normalizeKazanim(kampanya, harcamalar = 2000) {
  if (!isSpendRewardCampaign(kampanya)) return 0;
  const spendMap = typeof harcamalar === "object" && harcamalar !== null
    ? harcamalar
    : { market: Number(harcamalar) || 0, restoran: Number(harcamalar) || 0, yakit: Number(harcamalar) || 0, online: Number(harcamalar) || 0, diger: Number(harcamalar) || 0 };
  const sliderKey = sliderKeyForCampaign(kampanya);
  const ilgiliHarcama = Number(spendMap[sliderKey] || 0);
  if (ilgiliHarcama === 0) return 0;
  const kazanim = parseMoney(kampanya.kazanim);
  const kazanimTuru = String(kampanya.kazanim_turu || "").trim().toLocaleLowerCase("tr-TR");
  const minHarcama = parseMoney(kampanya.min_harcama || 0);
  const maxKazanim = parseMoney(kampanya.max_kazanim || 0);

  if (!kazanim || !kazanimTuru) return 0;
  if (kazanimTuru === "%") {
    let hesap = (ilgiliHarcama * kazanim) / 100;
    if (maxKazanim) hesap = Math.min(hesap, maxKazanim);
    return hesap;
  }
  if (kazanimTuru === "tl") {
    return ilgiliHarcama >= minHarcama ? kazanim : 0;
  }
  if (kazanimTuru === "puan") return kazanim * 0.01;
  if (kazanimTuru === "mil") return kazanim * 0.03;
  return 0;
}

function isCalculatorEligible(item, harcamalar = 2000) {
  return isCalculatorCategory(item) && isSpendRewardCampaign(item) && normalizeKazanim(item, harcamalar) > 0;
}

function isCalculatorCategory(item) {
  const category = item.kategori || item.category || "";
  return HESAP_KATEGORILERI.has(category);
}

function isSpendRewardCampaign(item) {
  const text = normalize(`${item.kazanim || ""} ${item.highlight || ""} ${item.title || ""} ${item.baslik || ""} ${item.description || ""} ${item.aciklama || ""} ${item.reward_type || ""}`);
  if (/(faiz|mevduat|nakit avans|fatura ode|hesap ac|vadeli|vade|fon|yatirim|sigorta)/.test(text)) return false;
  return /(tl|₺|indirim|iade|cashback|puan|bonus|chip|worldpuan|bankkart lira|mil|oran|%)/.test(text);
}

function sliderKeyForCampaign(kampanya) {
  const category = kampanya.kategori || kampanya.category || "Genel";
  return kategoriHaritasi[category] || kategoriHaritasi[normalize(category)] || "diger";
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
  if (!deadlineValue) return { label: "", badgeClass: "deadline-neutral", cardClass: "", hidden: true };

  const end = parseDeadline(deadlineValue);
  if (!end) return { label: "", badgeClass: "deadline-neutral", cardClass: "", hidden: true };
  const days = Math.ceil((end - new Date()) / 86400000);
  if (days <= 0) return { label: "Süresi doldu", badgeClass: "deadline-expired", cardClass: "is-expired" };
  if (days <= 3) return { label: `🔴 ${days} gün`, badgeClass: "deadline-danger pulse", cardClass: "deadline-danger-card" };
  if (days <= 14) return { label: `⚠ ${days} gün`, badgeClass: "deadline-warning", cardClass: "deadline-warning-card" };
  return { label: `${days} gün`, badgeClass: "deadline-neutral", cardClass: "" };
}

function urgencyInfo(item) {
  const end = parseDeadline(item.bitis_tarihi || item.deadline);
  if (!end) return { hours: Infinity, isUrgent: false, badge: "", badgeClass: "", cardClass: "" };
  const hours = Math.ceil((end - new Date()) / 3600000);
  if (hours <= 0) return { hours, isUrgent: false, badge: "", badgeClass: "", cardClass: "" };
  if (hours <= 24) {
    return { hours, isUrgent: true, badge: `SON ${hours} SAAT`, badgeClass: "urgent-hours", cardClass: "urgent-hours-card" };
  }
  if (hours <= 72) {
    const days = Math.ceil(hours / 24);
    return { hours, isUrgent: true, badge: `⚠ ${days} gün`, badgeClass: "urgent-days", cardClass: "urgent-days-card" };
  }
  return { hours, isUrgent: false, badge: "", badgeClass: "", cardClass: "" };
}

function parseDeadline(value) {
  if (!value) return null;
  const raw = String(value).trim();
  const date = raw.includes("T") ? new Date(raw) : new Date(`${raw}T23:59:59`);
  return Number.isNaN(date.getTime()) ? null : date;
}

function parseMoney(value) {
  const match = String(value || "0").match(/\d+(?:[.,]\d+)?/);
  const raw = String(match ? match[0] : "0");
  if (raw.includes(",")) return Number(raw.replace(/\./g, "").replace(",", ".")) || 0;
  if (raw.includes(".")) {
    const cents = raw.split(".").at(-1);
    return Number(cents.length <= 2 ? raw : raw.replace(/\./g, "")) || 0;
  }
  return Number(raw) || 0;
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

function updateHarcama(val) {
  state.monthlySpend = Number(val || 2000);
  updateMonthlySpendLabel();
  localStorage.setItem("kr-aylik-harcama", String(state.monthlySpend));
  localStorage.setItem("monthlySpend", String(state.monthlySpend));
  rerenderCards();
}

function rerenderCards() {
  applyFilters();
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
  const emptyFavorites = els.favoritesOnly?.checked && state.favorites.size === 0;
  els.campaigns.innerHTML = `
    <div class="state-panel empty-state" aria-live="polite">
      <svg class="state-icon" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <circle cx="11" cy="11" r="7"></circle>
        <path d="m20 20-3.5-3.5"></path>
      </svg>
      <h2>${emptyFavorites ? "Henüz favori kampanyan yok" : "Sonuç bulunamadı"}</h2>
      <p>${emptyFavorites ? "Kartlardaki yıldızlara basarak ilgilendiğin kampanyaları burada toplayabilirsin." : `<strong>${escapeHtml(context)}</strong> için kampanya yok. Filtreleri değiştirmeyi deneyin.`}</p>
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
  els.usedOnly.checked = false;
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
  if (els.usedOnly.checked) parts.push("Kullandıklarım");
  return parts.join(", ") || "Tüm kampanyalar";
}

function normalize(value) {
  value = String(value || "").replaceAll("yurtdışı", "yurt dışı").replaceAll("yurtdisi", "yurt disi");
  return String(value || "").toLocaleLowerCase("tr-TR").replaceAll("ı", "i").replaceAll("ğ", "g").replaceAll("ş", "s").replaceAll("ö", "o").replaceAll("ü", "u").replaceAll("ç", "c").normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

function normalizeSearch(value) {
  return normalize(value).replace(/\s+/g, "");
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
