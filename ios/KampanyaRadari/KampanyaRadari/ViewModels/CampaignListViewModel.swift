import Foundation
import Observation

enum CampaignSortOption: String, CaseIterable, Identifiable {
    case expiringSoon = "Yakinda biten"
    case bestScore = "Firsat skoru"
    case bank = "Banka adi"
    case title = "Kampanya adi"

    var id: String { rawValue }
}

struct CategorySummary: Identifiable, Hashable {
    let name: String
    let count: Int

    var id: String { name }
}

enum CampaignCategory: String, CaseIterable, Identifiable {
    case fuel = "Akaryakıt"
    case electronics = "Elektronik"
    case fashion = "Giyim"
    case market = "Market"
    case online = "Online"
    case restaurant = "Restoran"
    case travel = "Seyahat"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .fuel: return "fuelpump.fill"
        case .electronics: return "desktopcomputer"
        case .fashion: return "tshirt.fill"
        case .market: return "cart.fill"
        case .online: return "network"
        case .restaurant: return "fork.knife"
        case .travel: return "airplane"
        }
    }
}

@MainActor
@Observable
final class CampaignListViewModel {
    var campaigns: [Campaign] = []
    private var categoryCache: [String: String] = [:]
    var searchText = ""
    var selectedBanks: Set<String> = []
    var selectedCategories: Set<String> = []
    var selectedRewardType: String?
    var showFavoritesOnly = false
    var showMyCardsOnly = false
    var sortOption: CampaignSortOption = .expiringSoon
    var isLoading = false
    var errorMessage: String?
    var campaignsRevision = 0

    private let service = CampaignService()

    var banks: [String] {
        Array(Set(campaigns.map(\.bank))).sorted {
            label(for: $0).localizedCaseInsensitiveCompare(label(for: $1)) == .orderedAscending
        }
    }

    var categories: [String] {
        CampaignCategory.allCases
            .map(\.rawValue)
            .filter { category in
                campaigns.contains { canonicalCategory(for: $0) == category }
            }
    }

    var rewardTypes: [String] {
        sortedUniqueValues(campaigns.compactMap(\.rewardType))
    }

    var categorySummaries: [CategorySummary] {
        CampaignCategory.allCases.compactMap { category in
            let count = campaigns.filter { canonicalCategory(for: $0) == category.rawValue }.count
            guard count > 0 else { return nil }
            return CategorySummary(name: category.rawValue, count: count)
        }
    }

    var topCategorySummaries: [CategorySummary] {
        categorySummaries
    }

    var bankCount: Int {
        Set(campaigns.map(\.bank)).count
    }

    var hasAdvancedFilters: Bool {
        !selectedBanks.isEmpty || !selectedCategories.isEmpty || selectedRewardType != nil || showFavoritesOnly || showMyCardsOnly || sortOption != .expiringSoon
    }

    var hasContentFilters: Bool {
        !selectedCategories.isEmpty || selectedRewardType != nil || showFavoritesOnly || showMyCardsOnly
    }

    func filteredCampaigns(favoriteIDs: Set<String>, myCardBanks: Set<String>) -> [Campaign] {
        let filtered = campaigns.filter { campaign in
            let bankMatches = selectedBanks.isEmpty || selectedBanks.contains(campaign.bank)
            let categoryMatches = selectedCategories.isEmpty || selectedCategories.contains(canonicalCategory(for: campaign))
            let rewardMatches = selectedRewardType == nil || campaign.rewardType == selectedRewardType
            let favoriteMatches = !showFavoritesOnly || favoriteIDs.contains(campaign.id)
            let myCardsMatch = !showMyCardsOnly || myCardBanks.contains(campaign.bank)
            let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatches = search.isEmpty
                || campaign.title.localizedCaseInsensitiveContains(search)
                || campaign.displaySummary.localizedCaseInsensitiveContains(search)
                || campaign.bank.localizedCaseInsensitiveContains(search)

            return bankMatches && categoryMatches && rewardMatches && favoriteMatches && myCardsMatch && searchMatches
        }

        return sort(filtered)
    }

    func resetFilters() {
        selectedBanks = []
        selectedCategories = []
        selectedRewardType = nil
        showFavoritesOnly = false
        showMyCardsOnly = false
        sortOption = .expiringSoon
    }

    func clearAdvancedFilters() {
        selectedCategories = []
        selectedRewardType = nil
        showFavoritesOnly = false
        showMyCardsOnly = false
    }

    func showAllCampaigns() {
        resetFilters()
        searchText = ""
    }

    func showCampaigns(category: String) {
        searchText = ""
        selectedBanks = []
        selectedCategories = [category]
        selectedRewardType = nil
        showFavoritesOnly = false
        showMyCardsOnly = false
        sortOption = .expiringSoon
    }

    func showFavoriteCampaigns() {
        searchText = ""
        selectedBanks = []
        selectedCategories = []
        selectedRewardType = nil
        showFavoritesOnly = true
        showMyCardsOnly = false
        sortOption = .expiringSoon
    }

    func showMyCardCampaigns() {
        searchText = ""
        selectedBanks = []
        selectedCategories = []
        selectedRewardType = nil
        showFavoritesOnly = false
        showMyCardsOnly = true
        sortOption = .expiringSoon
    }

    func toggleBank(_ bank: String) {
        if selectedBanks.contains(bank) {
            selectedBanks.remove(bank)
        } else {
            selectedBanks.insert(bank)
        }
    }

    func clearBanks() {
        selectedBanks = []
    }

    func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func clearCategories() {
        selectedCategories = []
    }

    func label(for bank: String) -> String {
        campaigns.first(where: { $0.bank == bank })?.displayBank ?? bank
    }

    func iconName(for category: String) -> String {
        CampaignCategory.allCases.first(where: { $0.rawValue == category })?.iconName ?? "tag.fill"
    }

    private func sortedUniqueValues(_ values: [String]) -> [String] {
        Array(Set(values.filter { !$0.isEmpty })).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }

    private func canonicalCategory(for campaign: Campaign) -> String {
        if let cached = categoryCache[campaign.id] { return cached }
        let result = Self.computeCanonicalCategory(for: campaign)
        categoryCache[campaign.id] = result
        return result
    }

    nonisolated static func computeCanonicalCategory(for campaign: Campaign) -> String {
        let haystack = [
            campaign.title,
            campaign.summary,
            campaign.description
        ]
            .compactMap { $0 }
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()

        if haystack.contains("akaryakit") || haystack.contains("yakit") || haystack.contains("petrol") || haystack.contains("shell") || haystack.contains("opet") || haystack.contains("total") {
            return CampaignCategory.fuel.rawValue
        }
        if haystack.contains("elektronik") || haystack.contains("teknosa") || haystack.contains("mediamarkt") || haystack.contains("vatan") || haystack.contains("bilgisayar") || haystack.contains("telefon") {
            return CampaignCategory.electronics.rawValue
        }
        if haystack.contains("giyim") || haystack.contains("moda") || haystack.contains("zara") || haystack.contains("defacto") || haystack.contains("lc waikiki") || haystack.contains("ipekyol") || haystack.contains("vakko") {
            return CampaignCategory.fashion.rawValue
        }
        if haystack.contains("market") || haystack.contains("migros") || haystack.contains("a101") || haystack.contains("sok") || haystack.contains("carrefour") {
            return CampaignCategory.market.rawValue
        }
        if haystack.contains("restoran") || haystack.contains("restaurant") || haystack.contains("cafe") || haystack.contains("yemek") || haystack.contains("bigchefs") || haystack.contains("cookshop") {
            return CampaignCategory.restaurant.rawValue
        }
        if haystack.contains("seyahat")
            || haystack.contains("otel")
            || haystack.contains("hotel")
            || haystack.contains("konaklama")
            || haystack.contains("ucak")
            || haystack.contains("ucak bileti")
            || haystack.contains("otobus bileti")
            || haystack.contains("obilet")
            || haystack.contains("tatil")
            || haystack.contains("havalimani")
            || haystack.contains("lounge")
            || haystack.contains("transfer")
            || haystack.contains("arac kiralama")
            || haystack.contains("yurt disi cikis")
            || haystack.contains("cikis harci")
            || haystack.contains("pazaramatatil")
            || haystack.contains("tatilbudur")
            || haystack.contains("jolly")
            || haystack.contains("yolcu360")
            || haystack.contains("enuygun") {
            return CampaignCategory.travel.rawValue
        }
        return CampaignCategory.online.rawValue
    }

    private func sort(_ campaigns: [Campaign]) -> [Campaign] {
        switch sortOption {
        case .expiringSoon:
            return campaigns.sorted {
                ($0.validTo ?? .distantFuture, $0.title) < ($1.validTo ?? .distantFuture, $1.title)
            }
        case .bestScore:
            return campaigns.sorted {
                ($0.opportunityScore ?? 0, $0.title) > ($1.opportunityScore ?? 0, $1.title)
            }
        case .bank:
            return campaigns.sorted {
                let bankOrder = $0.displayBank.localizedCaseInsensitiveCompare($1.displayBank)
                if bankOrder != .orderedSame { return bankOrder == .orderedAscending }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .title:
            return campaigns.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await service.fetchActiveCampaigns()
            let cache: [String: String] = await Task.detached(priority: .userInitiated) {
                Dictionary(
                    uniqueKeysWithValues: fetched.map {
                        ($0.id, CampaignListViewModel.computeCanonicalCategory(for: $0))
                    }
                )
            }.value
            categoryCache = cache
            campaigns = fetched
            campaignsRevision += 1
        } catch {
            errorMessage = "Kampanyalar yuklenemedi. \(error.localizedDescription)"
        }
        isLoading = false
    }
}
