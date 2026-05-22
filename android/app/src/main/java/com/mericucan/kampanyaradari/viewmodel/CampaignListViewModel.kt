package com.mericucan.kampanyaradari.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mericucan.kampanyaradari.data.model.Campaign
import com.mericucan.kampanyaradari.data.remote.CampaignService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate

// ── Enums (iOS'tan birebir) ───────────────────────────────────

enum class SortOption(val label: String) {
    EXPIRING_SOON("Yakında biten"),
    BEST_SCORE("Fırsat skoru"),
    BANK("Banka adı"),
    TITLE("Kampanya adı")
}

enum class CampaignCategory(val label: String, val emoji: String) {
    FUEL("Akaryakıt", "⛽"),
    ELECTRONICS("Elektronik", "💻"),
    FASHION("Giyim", "👕"),
    MARKET("Market", "🛒"),
    ONLINE("Online", "🌐"),
    RESTAURANT("Restoran", "🍽️"),
    TRAVEL("Seyahat", "✈️")
}

data class CategorySummary(val category: CampaignCategory, val count: Int)

// ── ViewModel ─────────────────────────────────────────────────

class CampaignListViewModel : ViewModel() {
    private val service = CampaignService()
    private val categoryCache = mutableMapOf<String, String>()

    private val _campaigns    = MutableStateFlow<List<Campaign>>(emptyList())
    private val _isLoading    = MutableStateFlow(false)
    private val _lastSyncTime = MutableStateFlow<Long?>(null)
    private val _error       = MutableStateFlow<String?>(null)

    val campaigns: StateFlow<List<Campaign>>  = _campaigns.asStateFlow()
    val isLoading: StateFlow<Boolean>         = _isLoading.asStateFlow()
    val lastSyncTime: StateFlow<Long?>        = _lastSyncTime.asStateFlow()
    val error: StateFlow<String?>            = _error.asStateFlow()

    // Filter state
    val searchText          = MutableStateFlow("")
    val selectedBanks       = MutableStateFlow<Set<String>>(emptySet())
    val selectedCategories  = MutableStateFlow<Set<String>>(emptySet())
    val selectedRewardType  = MutableStateFlow<String?>(null)
    val showFavoritesOnly   = MutableStateFlow(false)
    val showMyCardsOnly     = MutableStateFlow(false)
    val sortOption          = MutableStateFlow(SortOption.EXPIRING_SOON)

    init { load() }

    fun load() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                val fetched = service.fetchActiveCampaigns()
                fetched.forEach { categoryCache[it.id] = computeCategory(it) }
                _campaigns.value = fetched
                _lastSyncTime.value = System.currentTimeMillis()
            } catch (e: Exception) {
                _error.value = "Kampanyalar yüklenemedi: ${e.message}"
            }
            _isLoading.value = false
        }
    }

    fun filteredCampaigns(favoriteIds: Set<String>, myCardBanks: Set<String>): List<Campaign> {
        val search    = searchText.value.trim()
        val banks     = selectedBanks.value
        val cats      = selectedCategories.value
        val reward    = selectedRewardType.value
        val favOnly   = showFavoritesOnly.value
        val cardsOnly = showMyCardsOnly.value

        return _campaigns.value
            .filter { c ->
                (banks.isEmpty() || banks.contains(c.bank)) &&
                (cats.isEmpty()  || cats.contains(getCategory(c))) &&
                (reward == null  || c.rewardType?.contains(reward, ignoreCase = true) == true) &&
                (!favOnly        || favoriteIds.contains(c.id)) &&
                (!cardsOnly      || myCardBanks.contains(c.bank)) &&
                (search.isEmpty() ||
                    c.title.contains(search, ignoreCase = true) ||
                    c.displaySummary.contains(search, ignoreCase = true) ||
                    c.bank.contains(search, ignoreCase = true))
            }
            .let { sorted(it) }
    }

    fun getCategory(campaign: Campaign): String =
        categoryCache.getOrPut(campaign.id) { computeCategory(campaign) }

    fun allBanks(): List<String> =
        _campaigns.value.map { it.bank }.toSet().sortedWith(compareBy { bankLabel(it) })

    fun bankLabel(bank: String): String =
        _campaigns.value.firstOrNull { it.bank == bank }?.displayBank ?: bank

    fun categorySummaries(): List<CategorySummary> =
        CampaignCategory.entries.mapNotNull { cat ->
            val count = _campaigns.value.count { getCategory(it) == cat.label }
            if (count > 0) CategorySummary(cat, count) else null
        }

    fun hasActiveFilters(): Boolean =
        selectedBanks.value.isNotEmpty() ||
        selectedCategories.value.isNotEmpty() ||
        selectedRewardType.value != null ||
        showFavoritesOnly.value ||
        showMyCardsOnly.value ||
        sortOption.value != SortOption.EXPIRING_SOON

    fun resetFilters() {
        selectedBanks.value      = emptySet()
        selectedCategories.value = emptySet()
        selectedRewardType.value = null
        showFavoritesOnly.value  = false
        showMyCardsOnly.value    = false
        sortOption.value         = SortOption.EXPIRING_SOON
    }

    fun showFavoriteCampaigns() {
        resetFilters()
        showFavoritesOnly.value = true
    }

    fun showMyCardCampaigns() {
        resetFilters()
        showMyCardsOnly.value = true
    }

    fun showCampaigns(category: String) {
        resetFilters()
        selectedCategories.value = setOf(category)
    }

    // ── Private helpers ───────────────────────────────────────

    private fun sorted(list: List<Campaign>): List<Campaign> = when (sortOption.value) {
        SortOption.EXPIRING_SOON -> list.sortedWith(
            compareBy({ it.validToDate ?: LocalDate.MAX }, { it.title })
        )
        SortOption.BEST_SCORE -> list.sortedWith(
            compareByDescending<Campaign> { it.opportunityScore ?: 0 }.thenBy { it.title }
        )
        SortOption.BANK  -> list.sortedWith(compareBy({ it.displayBank }, { it.title }))
        SortOption.TITLE -> list.sortedBy { it.title }
    }

    private fun computeCategory(c: Campaign): String {
        val h = listOfNotNull(c.title, c.summary, c.description)
            .joinToString(" ")
            .lowercase()
            .replace('ı', 'i').replace('ş', 's').replace('ğ', 'g')
            .replace('ü', 'u').replace('ö', 'o').replace('ç', 'c')

        return when {
            h.any("akaryakit", "yakit", "petrol", "shell", "opet", "total") -> CampaignCategory.FUEL.label
            h.any("elektronik", "teknosa", "mediamarkt", "vatan", "bilgisayar", "telefon") -> CampaignCategory.ELECTRONICS.label
            h.any("giyim", "moda", "zara", "defacto", "lc waikiki", "ipekyol", "vakko") -> CampaignCategory.FASHION.label
            h.any("market", "migros", "a101", "sok", "carrefour", "bim", "file", "metro", "kipa", "hakmar", "makro") -> CampaignCategory.MARKET.label
            h.any("restoran", "restaurant", "cafe", "yemek", "bigchefs") -> CampaignCategory.RESTAURANT.label
            h.any("seyahat", "otel", "hotel", "ucak", "tatil", "havalimani", "lounge", "transfer",
                "arac kiralama", "tatilbudur", "jolly", "yolcu360", "enuygun") -> CampaignCategory.TRAVEL.label
            else -> CampaignCategory.ONLINE.label
        }
    }

    private fun String.any(vararg terms: String) = terms.any { this.contains(it) }
}
