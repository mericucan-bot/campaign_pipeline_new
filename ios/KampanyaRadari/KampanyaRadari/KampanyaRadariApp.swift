import SwiftUI
import Sentry
import UserNotifications

@main
struct KampanyaRadariApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        let dsn = AppConfig.sentryDSN
        if !dsn.isEmpty {
            SentrySDK.start { options in
                options.dsn = dsn
                options.tracesSampleRate = 0.2
                options.environment = "production"
                options.enableAutoSessionTracking = true
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            CampaignListView()
        }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    private override init() {}

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
