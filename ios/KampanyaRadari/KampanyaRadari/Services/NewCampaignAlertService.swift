import Foundation
import UserNotifications

enum NewCampaignAlertService {
    private static let seenIDsKey = "newCampaignAlert_seenIDs"
    private static let notificationPrefix = "new-campaign-"

    /// Kampanyalar yüklendikten sonra çağır. Premium + kartı olan kullanıcılara yeni kampanya varsa bildirim gönderir.
    static func checkAndSchedule(
        campaigns: [Campaign],
        myCardBanks: Set<String>,
        plan: SubscriptionPlan
    ) {
        guard plan.isPremiumLike, !myCardBanks.isEmpty, !campaigns.isEmpty else { return }
        Task.detached(priority: .utility) {
            await run(campaigns: campaigns, myCardBanks: myCardBanks)
        }
    }

    private static func run(campaigns: [Campaign], myCardBanks: Set<String>) async {
        let seenIDs = Set(UserDefaults.standard.stringArray(forKey: seenIDsKey) ?? [])
        let allCurrentIDs = Set(campaigns.map(\.id))

        // Görülen kampanyaları güncelle
        UserDefaults.standard.set(Array(allCurrentIDs), forKey: seenIDsKey)

        // İlk açılış: spam önlemek için bildirim gönderme
        guard !seenIDs.isEmpty else { return }

        let newForMyBanks = campaigns.filter {
            !seenIDs.contains($0.id) && myCardBanks.contains($0.bank)
        }
        guard !newForMyBanks.isEmpty else { return }

        let granted = await requestPermission()
        guard granted else { return }

        let bankGroups = Dictionary(grouping: newForMyBanks, by: \.bank)
        let center = UNUserNotificationCenter.current()

        for (bank, bankCampaigns) in bankGroups {
            let content = UNMutableNotificationContent()
            let label = bankCampaigns.first?.bankLabel ?? bank
            content.title = "\(label): yeni kampanya"
            content.body = bankCampaigns.count == 1
                ? bankCampaigns[0].title
                : "\(bankCampaigns.count) yeni kampanya mevcut."
            content.sound = .default

            let id = "\(notificationPrefix)\(bank.hash)-\(Int(Date().timeIntervalSince1970))"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
            try? await center.add(request)
        }
    }

    private static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied: return false
        @unknown default: return false
        }
    }
}
