import SwiftUI
import Sentry

@main
struct KampanyaRadariApp: App {
    init() {
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
