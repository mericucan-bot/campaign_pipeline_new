import Foundation

enum AppConfig {
    static var supabaseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            let url = URL(string: raw),
            !raw.isEmpty
        else {
            fatalError("SupabaseURL Info.plist icinde tanimli olmali.")
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard
            let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
            !key.isEmpty
        else {
            fatalError("SupabaseAnonKey Info.plist icinde tanimli olmali.")
        }
        return key
    }
}

