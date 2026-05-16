import Foundation

struct AuthUser: Codable, Equatable {
    let id: String
    let email: String?
    let metadata: AuthUserMetadata?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case metadata = "user_metadata"
    }
}

struct AuthUserMetadata: Codable, Equatable {
    let fullName: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case name
    }

    var displayName: String? {
        [fullName, name]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }
}

struct AuthSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case user
    }

    init(accessToken: String, refreshToken: String?, expiresAt: Date?, user: AuthUser) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        user = try container.decode(AuthUser.self, forKey: .user)

        if let absoluteTimestamp = try container.decodeIfPresent(Double.self, forKey: .expiresAt) {
            expiresAt = Date(timeIntervalSince1970: absoluteTimestamp)
        } else if let expiresIn = try container.decodeIfPresent(Double.self, forKey: .expiresIn) {
            expiresAt = Date().addingTimeInterval(expiresIn)
        } else {
            expiresAt = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encodeIfPresent(expiresAt?.timeIntervalSince1970, forKey: .expiresAt)
        try container.encode(user, forKey: .user)
    }
}

enum SupabaseAuthError: LocalizedError {
    case emailConfirmationRequired
    case server(String)

    var errorDescription: String? {
        switch self {
        case .emailConfirmationRequired:
            return "Kayıt alındı. E-postanı onayladıktan sonra Giriş sekmesinden devam edebilirsin."
        case .server(let message):
            return Self.friendly(message)
        }
    }

    private static func friendly(_ message: String) -> String {
        let normalized = message.lowercased()
        if normalized.contains("invalid login credentials") {
            return "E-posta veya şifre eşleşmedi. Şifreyi hatırlamıyorsan sıfırlama maili gönderebilirsin."
        }
        if normalized.contains("email not confirmed") {
            return "E-posta onayı bekleniyor. Mail kutundaki Supabase onay bağlantısını açıp tekrar dene."
        }
        if normalized.contains("user already registered") || normalized.contains("already registered") {
            return "Bu e-posta zaten kayıtlı. Kayıt yerine Giriş sekmesini kullan."
        }
        return message
    }
}

struct SupabaseAuthService {
    func signIn(email: String, password: String) async throws -> AuthSession {
        try await requestSession(
            path: "auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            body: ["email": email, "password": password]
        )
    }

    func signUp(email: String, password: String) async throws -> AuthSession {
        try await requestSession(
            path: "auth/v1/signup",
            body: ["email": email, "password": password]
        )
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
        try await requestSession(
            path: "auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            body: ["provider": "apple", "id_token": idToken, "nonce": nonce]
        )
    }

    func refreshSession(refreshToken: String) async throws -> AuthSession {
        try await requestSession(
            path: "auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: ["refresh_token": refreshToken]
        )
    }

    func sendPasswordReset(email: String) async throws {
        try await requestEmpty(
            path: "auth/v1/recover",
            queryItems: [URLQueryItem(name: "redirect_to", value: AppConfig.authRedirectURL)],
            body: ["email": email]
        )
    }

    func updatePassword(accessToken: String, password: String) async throws {
        guard password.count >= 6 else {
            throw SupabaseAuthError.server("Yeni şifre en az 6 karakter olmalı.")
        }

        guard let url = URL(string: "auth/v1/user", relativeTo: AppConfig.supabaseURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["password": password])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseAuthError.server(errorMessage(from: data) ?? "Şifre güncellenemedi.")
        }
    }

    func signOut(accessToken: String) async {
        guard let url = URL(string: "auth/v1/logout", relativeTo: AppConfig.supabaseURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
    }

    private func requestSession(path: String, queryItems: [URLQueryItem] = [], body: [String: String]) async throws -> AuthSession {
        guard let baseURL = URL(string: path, relativeTo: AppConfig.supabaseURL),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseAuthError.server(errorMessage(from: data) ?? "Giriş işlemi tamamlanamadı.")
        }

        if let session = try? JSONDecoder().decode(AuthSession.self, from: data) {
            return session
        }

        throw SupabaseAuthError.emailConfirmationRequired
    }

    private func requestEmpty(path: String, queryItems: [URLQueryItem] = [], body: [String: String]) async throws {
        guard let baseURL = URL(string: path, relativeTo: AppConfig.supabaseURL),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseAuthError.server(errorMessage(from: data) ?? "İşlem tamamlanamadı.")
        }
    }

    private func errorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object["msg"] as? String
            ?? object["message"] as? String
            ?? object["error_description"] as? String
            ?? object["error"] as? String
    }
}
