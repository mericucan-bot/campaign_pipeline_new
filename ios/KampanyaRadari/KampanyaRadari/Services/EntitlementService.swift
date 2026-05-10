import Foundation

enum SubscriptionPlan: String, Codable, Equatable {
    case free
    case trial
    case premium

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .trial: return "Deneme"
        case .premium: return "Premium"
        }
    }

    var isPremiumLike: Bool {
        self == .trial || self == .premium
    }
}

struct EntitlementRule: Equatable {
    let allowed: Bool
    let title: String
    let message: String
}

enum EntitlementService {
    static func canUseRewardReminder(
        plan: SubscriptionPlan,
        participation: ParticipationStore,
        campaignID: String
    ) -> EntitlementRule {
        if plan.isPremiumLike {
            return EntitlementRule(
                allowed: true,
                title: "Premium hatırlatıcı",
                message: "Premium planda sınırsız kampanya hatırlatıcısı kullanabilirsin."
            )
        }

        if participation.activeReminderCount(excluding: campaignID) < 1 {
            return EntitlementRule(
                allowed: true,
                title: "Ücretsiz hatırlatıcı",
                message: "Free planda 1 aktif kampanya hatırlatıcısı kullanabilirsin."
            )
        }

        return EntitlementRule(
            allowed: false,
            title: "Premium ile sınırsız takip",
            message: "Free planda 1 aktif puan hatırlatıcısı var. Bir kampanyada deneyip faydasını gördükten sonra Premium ile sınırsız hatırlatıcı açabileceksin."
        )
    }

    static func reminderAllowanceText(plan: SubscriptionPlan, participation: ParticipationStore) -> String {
        if plan.isPremiumLike {
            return "Sınırsız hatırlatıcı"
        }
        return "\(participation.activeReminderCount)/1 aktif hatırlatıcı"
    }
}
