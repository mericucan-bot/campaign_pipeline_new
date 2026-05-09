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

@MainActor
@Observable
final class CampaignListViewModel {
    var campaigns: [Campaign] = []
    var searchText = ""
    var selectedBank: String?
    var selectedCategory: String?
    var selectedRewardType: String?
    var showFavoritesOnly = false
    var sortOption: CampaignSortOption = .expiringSoon
    var isLoading = false
    var errorMessage: String?

    private let service = CampaignService()

    var banks: [String] {
        Array(Set(campaigns.map(\.bank))).sorted {
            label(for: $0).localizedCaseInsensitiveCompare(label(for: $1)) == .orderedAscending
        }
    }

    var categories: [String] {
        sortedUniqueValues(campaigns.compactMap(\.category))
    }

    var rewardTypes: [String] {
        sortedUniqueValues(campaigns.compactMap(\.rewardType))
    }

    var categorySummaries: [CategorySummary] {
        let grouped = Dictionary(grouping: campaigns) { campaign in
            let category = campaign.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return category.isEmpty ? "Genel" : category
        }

        return grouped
            .map { CategorySummary(name: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count != $1.count { return $0.count > $1.count }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    var topCategorySummaries: [CategorySummary] {
        Array(categorySummaries.prefix(4))
    }

    var bankCount: Int {
        Set(campaigns.map(\.bank)).count
    }

    var hasAdvancedFilters: Bool {
        selectedCategory != nil || selectedRewardType != nil || showFavoritesOnly || sortOption != .expiringSoon
    }

    func filteredCampaigns(favoriteIDs: Set<String>) -> [Campaign] {
        let filtered = campaigns.filter { campaign in
            let bankMatches = selectedBank == nil || campaign.bank == selectedBank
            let categoryMatches = selectedCategory == nil || campaign.category == selectedCategory
            let rewardMatches = selectedRewardType == nil || campaign.rewardType == selectedRewardType
            let favoriteMatches = !showFavoritesOnly || favoriteIDs.contains(campaign.id)
            let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatches = search.isEmpty
                || campaign.title.localizedCaseInsensitiveContains(search)
                || campaign.displaySummary.localizedCaseInsensitiveContains(search)
                || campaign.bank.localizedCaseInsensitiveContains(search)

            return bankMatches && categoryMatches && rewardMatches && favoriteMatches && searchMatches
        }

        return sort(filtered)
    }

    func resetFilters() {
        selectedBank = nil
        selectedCategory = nil
        selectedRewardType = nil
        showFavoritesOnly = false
        sortOption = .expiringSoon
    }

    func clearAdvancedFilters() {
        selectedCategory = nil
        selectedRewardType = nil
        showFavoritesOnly = false
        sortOption = .expiringSoon
    }

    func showAllCampaigns() {
        resetFilters()
        searchText = ""
    }

    func showCampaigns(category: String) {
        searchText = ""
        selectedBank = nil
        selectedCategory = category
        selectedRewardType = nil
        showFavoritesOnly = false
        sortOption = .expiringSoon
    }

    func label(for bank: String) -> String {
        campaigns.first(where: { $0.bank == bank })?.displayBank ?? bank
    }

    private func sortedUniqueValues(_ values: [String]) -> [String] {
        Array(Set(values.filter { !$0.isEmpty })).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
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
            campaigns = try await service.fetchActiveCampaigns()
        } catch {
            errorMessage = "Kampanyalar yuklenemedi. \(error.localizedDescription)"
        }
        isLoading = false
    }
}
