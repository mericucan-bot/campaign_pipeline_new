import Foundation
import UserNotifications

enum CampaignReminderService {
    private static let reminderOffsets = [7, 3, 0]

    static func syncReminder(for campaign: Campaign, record: CampaignParticipation) {
        cancelReminders(for: campaign)

        guard record.didJoin, let expiresAt = record.rewardExpiresAt else { return }

        Task {
            let granted = await requestPermissionIfNeeded()
            guard granted else { return }

            let center = UNUserNotificationCenter.current()
            for offset in reminderOffsets {
                guard let fireDate = Calendar.current.date(byAdding: .day, value: -offset, to: expiresAt),
                      let notificationDate = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: fireDate),
                      notificationDate > Date() else {
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = "Puan kullanım zamanı"
                content.body = bodyText(for: campaign, record: record, daysBefore: offset)
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: reminderID(for: campaign, daysBefore: offset),
                    content: content,
                    trigger: trigger
                )

                try? await center.add(request)
            }
        }
    }

    static func cancelReminders(for campaign: Campaign) {
        let ids = reminderOffsets.map { reminderID(for: campaign, daysBefore: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func requestPermissionIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func reminderID(for campaign: Campaign, daysBefore: Int) -> String {
        "campaign-reminder-\(campaign.id)-\(daysBefore)"
    }

    private static func bodyText(for campaign: Campaign, record: CampaignParticipation, daysBefore: Int) -> String {
        let amount = record.earnedAmount > 0 ? " \(record.earnedAmount.currencyText)" : ""
        let prefix: String
        switch daysBefore {
        case 0:
            prefix = "Bugün son gün."
        case 1:
            prefix = "Yarın son gün."
        default:
            prefix = "\(daysBefore) gün kaldı."
        }
        return "\(prefix)\(amount) kazanımını kullanmayı unutma: \(campaign.title)"
    }
}
