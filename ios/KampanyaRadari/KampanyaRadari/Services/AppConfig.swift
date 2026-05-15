import Foundation

enum AppConfig {
    static var supabaseURL: URL {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String ?? ""
        guard let url = URL(string: raw), !raw.isEmpty else {
            fatalError("SupabaseURL gecersiz.")
        }
        return url
    }

    static var supabaseAnonKey: String {
        let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String ?? ""
        guard !key.isEmpty else { fatalError("SupabaseAnonKey gecersiz.") }
        return key
    }

    static var authRedirectURL: String {
        Bundle.main.object(forInfoDictionaryKey: "AuthRedirectURL") as? String ?? "kampanyaradari://auth-callback"
    }
}
