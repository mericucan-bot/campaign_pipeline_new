import Foundation
import Observation

@Observable
final class FavoritesStore {
    private let key = "favoriteCampaignIDs"
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    private(set) var ids: Set<String> = []

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func contains(_ campaign: Campaign) -> Bool {
        ids.contains(campaign.id)
    }

    func toggle(_ campaign: Campaign) {
        set(campaign, isFavorite: !ids.contains(campaign.id))
    }

    func set(_ campaign: Campaign, isFavorite: Bool) {
        let containsCampaign = ids.contains(campaign.id)
        guard containsCampaign != isFavorite else { return }

        if containsCampaign {
            if !isFavorite {
                ids.remove(campaign.id)
            }
        } else if isFavorite {
            ids.insert(campaign.id)
        }
        save()
    }

    func replace(with newIDs: Set<String>) {
        guard ids != newIDs else { return }
        ids = newIDs
        save()
    }

    private func save() {
        let key = key
        let snapshot = Array(ids)
        saveTask?.cancel()
        saveTask = Task.detached(priority: .utility) {
            guard !Task.isCancelled else { return }
            UserDefaults.standard.set(snapshot, forKey: key)
        }
    }
}
