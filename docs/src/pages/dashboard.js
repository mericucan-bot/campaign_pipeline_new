import { loadingStateHtml, emptyStateHtml, errorStateHtml } from "../components/emptyStates.js";
import { fetchCampaignPayload } from "../services/campaignService.js";
import { BANK_LABELS, DEFAULT_MY_CARDS, HESAP_KATEGORILERI, KATEGORI_HARITASI } from "../data/config.js";
import { escapeAttr, escapeHtml } from "../utils/html.js";
import { formatCurrency, normalize, normalizeSearch, shortenText } from "../utils/format.js";
import { normalizeCampaign } from "../utils/campaignSchema.js";
import { calculateEffectiveReturn } from "../utils/valueCalculator.js";
import { calculateOpportunityScore, opportunityLabel } from "../utils/opportunityScore.js";

export function startDashboard() {
const state = {
  campaigns: [],
  filtered: [],
  selectedBank: "",
  favorites: loadFavoriteSet(),
  used: loadUsed(),
  pendingUsedId: null,
  manualCampaigns: JSON.parse(localStorage.getItem("manualCampaigns") || "[]").map((item, index) => normalizeCampaign(item, { index })),
  monthlySpend: Number(localStorage.getItem("kr-aylik-harcama") || localStorage.getItem("monthlySpend") || 2000),
  effectiveSpend: Number(localStorage.getItem("kr-effective-spend") || 1000),
  myCards: new Set(JSON.parse(localStorage.getItem("myCards") || "null") || DEFAULT_MY_CARDS),
};

const els = {
  campaigns: document.querySelector("#campaigns"),
  bankFilter: document.querySelector("#bankFilter"),
  categoryFilter: document.querySelector("#categoryFilter"),
  rewardFilter: document.querySelector("#rewardFilter"),
  sortFilter: document.querySelector("#sortFilter"),
  searchInput: document.querySelector("#searchInput"),
  effectiveSpendInput: document.querySelector("#effectiveSpendInput"),
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
  healthDrawer: document.querySelector(".health-drawer"),
  healthOpen: document.querySelector("[data-health-open]"),
  healthClose: document.querySelector("[data-health-close]"),
  historyDrawer: document.querySelector(".history-drawer"),
  historyOpen: document.querySelector("[data-history-open]"),
  historyClose: document.querySelector("[data-history-close]"),
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

fetchCampaignPayload()
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
  fillSelect(els.rewardFilter, "Tüm kazanımlar", unique(state.campaigns.map((item) => item.rewardType)), rewardTypeLabel);
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
  if (els.effectiveSpendInput) {
    els.effectiveSpendInput.value = state.effectiveSpend;
    els.effectiveSpendInput.addEventListener("input", updateEffectiveSpend);
    els.effectiveSpendInput.addEventListener("change", updateEffectiveSpend);
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
  bindDrawer(els.healthOpen, els.healthClose, els.healthDrawer);
  bindDrawer(els.historyOpen, els.historyClose, els.historyDrawer);
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
      && (!reward || item.rewardType === reward)
      && (!activeOnly || item.isActive)
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
  const inactive = state.campaigns.filter((item) => !item.isActive).length;
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
    return clone.sort((a, b) => (a.validTo || "9999-12-31").localeCompare(b.validTo || "9999-12-31"));
  }
  if (sort === "gain") {
    return clone
      .map((item) => ({ ...item, normalized: normalizeKazanim(item, calculatorSpendMap()) }))
      .sort((a, b) => b.normalized - a.normalized);
  }
  if (sort === "bank") {
    return clone.sort((a, b) => `${a.bank}${a.title}`.localeCompare(`${b.bank}${b.title}`));
  }
  return clone.sort((a, b) => String(b.validFrom || "").localeCompare(String(a.validFrom || "")));
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
  const effective = calculateEffectiveReturn(item, state.effectiveSpend);
  const opportunity = opportunityLabel(calculateOpportunityScore(item));
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
        <span class="effective-return-badge">Etkin getiri: %${formatPercent(effective.effectiveRate)}</span>
        <span class="opportunity-score-badge ${opportunity.className}">${escapeHtml(opportunity.text)}</span>
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
  const rawTitle = item.title || "";
  const rawDescription = item.description || item.conditions?.join(" ") || "";
  const text = compactCampaignText(rawTitle, rawDescription);
  return {
    id: item.id,
    baslik: text.baslik,
    aciklama: text.aciklama,
    fullTitle: String(rawTitle || "").replace(/\s+/g, " ").trim(),
    banka: item.bank || "Kampanya",
    kategori: item.category || "Genel",
    kazanim: item.rewardRate || item.highlight || 0,
    kazanim_turu: rewardLabelFor(item),
    rewardType: item.rewardType || "cashback",
    rewardRate: Number(item.rewardRate || 0),
    min_harcama: Number(item.minSpend || 0),
    max_kazanim: Number(item.maxReward || 0),
    bitis_tarihi: item.validTo || null,
    kaynak_url: item.sourceUrl || "",
    gorsel_url: item.imageUrl || "",
    aktif: item.isActive ?? true,
    sourceDate: item.sourceDate || String(item.validFrom || "").slice(0, 10) || "Tarih yok",
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

function isDeadlineOnlyText(text) {
  const value = normalize(text);
  return /^(?:\d+\s+gun\s+kaldi|bu kampanya bitmistir|tarih kaynakta|suresi gecmis)$/.test(value);
}

function rewardBadge(data) {
  if (!isSpendRewardCampaign(data)) return null;
  const type = String(data.rewardType || "").toLowerCase();
  const value = Number(data.rewardRate || 0);
  if (!value || value <= 0 || Number.isNaN(value)) return null;
  if (type === "installment") return { className: "reward-card-installment", label: `+${value} taksit` };
  if (type === "points") return { className: "reward-card-puan", label: `+${value} puan` };
  if (type === "cashback" && /%/.test(`${data.fullTitle || ""} ${data.aciklama || ""}`)) return { className: "reward-card-percent", label: `+${value}% indirim` };
  if (type === "cashback") return { className: "reward-card-tl", label: `+${value}₺ cashback` };
  return null;
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
  const bitisTarihi = parseDeadline(kampanya.bitis_tarihi || kampanya.validTo);
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
        if (data) new Notification("Kampanya Radarı ⏰", { body: `${data.baslik} — ${uyari.mesaj}`, icon: "./assets/radar-logo.svg" });
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
    .filter((item) => item.isActive)
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
  const item = normalizeCampaign({
    id,
    bank: "Manuel Favori",
    title,
    description: els.manualDescription.value.trim(),
    imageUrl: els.manualImage.value.trim(),
    sourceUrl: els.manualUrl.value.trim(),
    validFrom: now,
    isActive: true,
    category: "Genel",
    rewardType: "cashback",
    rewardRate: 0,
    brandCode: "MF",
  });

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
  return BANK_LABELS[bank] || bank;
}

function rewardTypeLabel(type) {
  if (type === "cashback") return "Nakit/indirim";
  if (type === "points") return "Puan";
  if (type === "installment") return "Taksit";
  return type || "Fırsat";
}

function normalizeKazanim(kampanya, harcamalar = 2000) {
  const sliderKey = sliderKeyForCampaign(kampanya);
  const ilgiliHarcama = typeof harcamalar === "object"
    ? Number(harcamalar[sliderKey] || 0)
    : Number(harcamalar || 0);
  if (ilgiliHarcama === 0) return 0;

  const kazanim = Number(kampanya.rewardRate || 0);
  const minSpend = Number(kampanya.min_harcama ?? kampanya.minSpend ?? 0);
  const maxReward = Number(kampanya.max_kazanim ?? kampanya.maxReward ?? 0) || Infinity;
  if (!kazanim || kazanim <= 0) return 0;
  if (ilgiliHarcama < minSpend) return 0;

  if (kampanya.rewardType === "points") return Math.min(kazanim * 0.01, maxReward);
  if (kampanya.rewardType === "installment") return 0;
  if (/%/.test(`${kampanya.fullTitle || ""} ${kampanya.aciklama || ""} ${kampanya.highlight || ""}`)) {
    return Math.min((ilgiliHarcama * kazanim) / 100, maxReward);
  }
  return Math.min(kazanim, maxReward);
}

function isCalculatorEligible(item, harcamalar = 2000) {
  return isCalculatorCategory(item) && isSpendRewardCampaign(item) && normalizeKazanim(item, harcamalar) > 0;
}

function isCalculatorCategory(item) {
  const category = item.kategori || item.category || "";
  return HESAP_KATEGORILERI.has(category);
}

function isSpendRewardCampaign(item) {
  if (item.rewardType === "installment") return false;
  const text = normalize(`${item.kazanim || ""} ${item.highlight || ""} ${item.title || ""} ${item.baslik || ""} ${item.description || ""} ${item.aciklama || ""} ${item.rewardType || ""}`);
  if (/(faiz|mevduat|nakit avans|fatura ode|hesap ac|vadeli|vade|fon|yatirim|sigorta)/.test(text)) return false;
  return item.rewardRate > 0 || /(tl|₺|indirim|iade|cashback|puan|bonus|chip|worldpuan|bankkart lira|mil|oran|%)/.test(text);
}

function sliderKeyForCampaign(kampanya) {
  const category = kampanya.kategori || kampanya.category || "Genel";
  return KATEGORI_HARITASI[category] || KATEGORI_HARITASI[normalize(category)] || "diger";
}

function rewardKindFor(item) {
  return item.rewardType || "cashback";
}

function rewardLabelFor(item) {
  return rewardTypeLabel(rewardKindFor(item));
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

function updateEffectiveSpend() {
  state.effectiveSpend = Math.max(0, Number(els.effectiveSpendInput?.value || 0));
  localStorage.setItem("kr-effective-spend", String(state.effectiveSpend));
  renderCampaigns();
}

function rerenderCards() {
  applyFilters();
}

function formatPercent(value) {
  const percent = Math.max(0, Number(value || 0) * 100);
  if (percent >= 100) return Math.round(percent).toLocaleString("tr-TR");
  return percent.toLocaleString("tr-TR", { maximumFractionDigits: 2 });
}

function showLoadingState() {
  els.campaigns.innerHTML = loadingStateHtml();
}

function showEmptyState(filterContext) {
  els.campaigns.innerHTML = emptyStateHtml(escapeHtml(filterContext));
  const clear = els.campaigns.querySelector("[data-clear-filters]");
  const showAll = els.campaigns.querySelector("[data-show-all]");
  if (clear) clear.addEventListener("click", clearFilters);
  if (showAll) showAll.addEventListener("click", showAllCampaigns);
}

function showErrorState(errorMsg) {
  const detail = errorMsg && errorMsg.message ? errorMsg.message : errorMsg;
  console.error(errorMsg);
  els.campaigns.innerHTML = errorStateHtml(escapeHtml(detail || "Bilinmeyen hata"));
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

  window.closeBanner = closeBanner;
  window.highlightCard = highlightCard;
  window.syncInput = syncInput;
  window.syncSlider = syncSlider;
}
