import Foundation
import Observation

@MainActor
@Observable
final class CampaignListViewModel {
    var campaigns: [Campaign] = []
    var searchText = ""
    var selectedBank: String?
    var isLoading = false
    var errorMessage: String?

    private let service = CampaignService()

    var banks: [String] {
        Array(Set(campaigns.map(\.bank))).sorted {
            label(for: $0).localizedCaseInsensitiveCompare(label(for: $1)) == .orderedAscending
        }
    }

    var filteredCampaigns: [Campaign] {
        campaigns.filter { campaign in
            let bankMatches = selectedBank == nil || campaign.bank == selectedBank
            let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatches = search.isEmpty
                || campaign.title.localizedCaseInsensitiveContains(search)
                || campaign.displaySummary.localizedCaseInsensitiveContains(search)
                || campaign.bank.localizedCaseInsensitiveContains(search)

            return bankMatches && searchMatches
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

    func label(for bank: String) -> String {
        campaigns.first(where: { $0.bank == bank })?.displayBank ?? bank
    }
}

