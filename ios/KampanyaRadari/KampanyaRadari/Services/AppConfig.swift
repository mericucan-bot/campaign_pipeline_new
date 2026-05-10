import Foundation

enum AppConfig {
    private static let fallbackSupabaseURL = "https://elzosfogvbybieyvojek.supabase.co"
    private static let fallbackSupabaseAnonKey = "sb_publishable_8qo0lf-XuimNd1ZIIU5xLg_DXLFCsbd"

    static var supabaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String ?? fallbackSupabaseURL
        guard let url = URL(string: raw), !raw.isEmpty else {
            fatalError("SupabaseURL gecersiz.")
        }
        return url
    }

    static var supabaseAnonKey: String {
        let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String ?? fallbackSupabaseAnonKey
        guard !key.isEmpty else { fatalError("SupabaseAnonKey gecersiz.") }
        return key
    }

    static var authRedirectURL: String {
        Bundle.main.object(forInfoDictionaryKey: "AuthRedirectURL") as? String ?? "kampanyaradari://auth-callback"
    }
}
