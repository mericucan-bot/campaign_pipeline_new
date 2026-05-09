import Foundation
import Observation

@Observable
final class FavoritesStore {
    private let key = "favoriteCampaignIDs"
    private(set) var ids: Set<String> = []

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func contains(_ campaign: Campaign) -> Bool {
        ids.contains(campaign.id)
    }

    func toggle(_ campaign: Campaign) {
        if ids.contains(campaign.id) {
            ids.remove(campaign.id)
        } else {
            ids.insert(campaign.id)
        }
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}

