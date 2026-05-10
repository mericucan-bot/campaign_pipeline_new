import Foundation
import Observation

struct CampaignParticipation: Codable, Equatable {
    var didJoin: Bool = false
    var spentAmount: Double = 0
    var earnedAmount: Double = 0
    var rewardExpiresAt: Date?

    var hasReminder: Bool {
        didJoin && rewardExpiresAt != nil
    }
}

@Observable
final class ParticipationStore {
    private let key = "campaignParticipations"
    private(set) var records: [String: CampaignParticipation] = [:]

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: CampaignParticipation].self, from: data) else {
            return
        }
        records = decoded
    }

    var joinedCount: Int {
        records.values.filter(\.didJoin).count
    }

    var totalSpent: Double {
        records.values.reduce(0) { $0 + $1.spentAmount }
    }

    var totalEarned: Double {
        records.values.reduce(0) { $0 + $1.earnedAmount }
    }

    func record(for campaign: Campaign) -> CampaignParticipation {
        records[campaign.id] ?? CampaignParticipation()
    }

    func update(_ record: CampaignParticipation, for campaign: Campaign) {
        if record == CampaignParticipation() {
            records.removeValue(forKey: campaign.id)
        } else {
            records[campaign.id] = record
        }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
