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
        campaignID: String,
        isGuest: Bool = false
    ) -> EntitlementRule {
        if isGuest {
            return EntitlementRule(
                allowed: false,
                title: "Giriş gerekli",
                message: "Hatırlatıcı eklemek için hesap oluşturman veya giriş yapman gerekiyor."
            )
        }

        if plan.isPremiumLike {
            return EntitlementRule(
                allowed: true,
                title: "Premium hatırlatıcı",
                message: "Premium planda kampanya hatırlatıcılarını öncelikli bildirim yönetimiyle kullanabilirsin."
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
            title: "Premium ile öncelikli takip",
            message: "Free planda 1 aktif hatırlatıcı hakkın var. Premium ile kampanya hatırlatıcılarını öncelikli bildirim yönetimiyle kullanabilirsin."
        )
    }

    static func reminderAllowanceText(plan: SubscriptionPlan, participation: ParticipationStore) -> String {
        if plan.isPremiumLike {
            return "Öncelikli hatırlatıcı"
        }
        return "\(participation.activeReminderCount)/1 aktif hatırlatıcı"
    }

    static let freeFavoriteLimit = 3

    static func canAddFavorite(
        plan: SubscriptionPlan,
        favorites: FavoritesStore,
        campaignID: String,
        isGuest: Bool = false
    ) -> EntitlementRule {
        if isGuest {
            return EntitlementRule(
                allowed: false,
                title: "Giriş gerekli",
                message: "Favorileri kaydetmek için hesap oluşturman veya giriş yapman gerekiyor."
            )
        }
        if plan.isPremiumLike {
            return EntitlementRule(allowed: true, title: "", message: "")
        }
        // Zaten favoride → kaldırmaya izin ver
        if favorites.ids.contains(campaignID) {
            return EntitlementRule(allowed: true, title: "", message: "")
        }
        if favorites.ids.count < freeFavoriteLimit {
            return EntitlementRule(allowed: true, title: "", message: "")
        }
        return EntitlementRule(
            allowed: false,
            title: "Favori limitine ulaştın",
            message: "Free planda \(freeFavoriteLimit) favori kampanya saklayabilirsin. Premium ile sınırsız favori ekleyebilirsin."
        )
    }

    static func favoriteAllowanceText(plan: SubscriptionPlan, favorites: FavoritesStore) -> String {
        if plan.isPremiumLike { return "Sınırsız favori" }
        return "\(min(favorites.ids.count, freeFavoriteLimit))/\(freeFavoriteLimit) favori"
    }

    static func canTrackCampaign(isGuest: Bool) -> EntitlementRule {
        guard isGuest else {
            return EntitlementRule(allowed: true, title: "", message: "")
        }
        return EntitlementRule(
            allowed: false,
            title: "Giriş gerekli",
            message: "Kampanya takibini kaydetmek için hesap oluşturman veya giriş yapman gerekiyor."
        )
    }
}
