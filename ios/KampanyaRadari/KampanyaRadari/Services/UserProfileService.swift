import Foundation

struct UserProfile: Decodable {
    let id: String
    let displayName: String?
    let plan: SubscriptionPlan
    let planStatus: String
    let trialEndsAt: String?
    let premiumUntil: String?

    var effectivePlan: SubscriptionPlan {
        guard planStatus == "active" else { return .free }

        switch plan {
        case .trial:
            guard let trialEndsAt = trialEndsAt.flatMap(Self.date(from:)) else { return .trial }
            return trialEndsAt > Date() ? .trial : .free
        case .premium:
            guard let premiumUntil = premiumUntil.flatMap(Self.date(from:)) else { return .premium }
            return premiumUntil > Date() ? .premium : .free
        case .free:
            return .free
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case plan
        case planStatus = "plan_status"
        case trialEndsAt = "trial_ends_at"
        case premiumUntil = "premium_until"
    }

    nonisolated private static func date(from text: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: text) {
            return date
        }
        return ISO8601DateFormatter().date(from: text)
    }
}

struct UserProfileService {
    func ensureProfile(session: AuthSession) async throws {
        guard var components = URLComponents(url: AppConfig.supabaseURL.appendingPathComponent("rest/v1/profiles"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "on_conflict", value: "id")]
        guard let url = components.url else { throw URLError(.badURL) }

        let row = ProfileInsertRow(
            id: session.user.id,
            displayName: session.user.metadata?.displayName,
            avatarURL: nil,
            plan: SubscriptionPlan.free.rawValue,
            planStatus: "active"
        )

        var request = authorizedRequest(url: url, session: session)
        request.httpMethod = "POST"
        request.setValue("resolution=ignore-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode([row])
        try await send(request)
    }

    func updateDisplayName(session: AuthSession, displayName: String) async throws {
        guard var components = URLComponents(url: AppConfig.supabaseURL.appendingPathComponent("rest/v1/profiles"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "id", value: "eq.\(session.user.id)")]
        guard let url = components.url else { throw URLError(.badURL) }

        var request = authorizedRequest(url: url, session: session)
        request.httpMethod = "PATCH"
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder().encode(ProfileDisplayNameUpdateRow(displayName: displayName))
        try await send(request)
    }

    func fetchProfile(session: AuthSession) async throws -> UserProfile? {
        guard var components = URLComponents(url: AppConfig.supabaseURL.appendingPathComponent("rest/v1/profiles"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "select", value: "id,display_name,plan,plan_status,trial_ends_at,premium_until"),
            URLQueryItem(name: "id", value: "eq.\(session.user.id)"),
            URLQueryItem(name: "limit", value: "1")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let request = authorizedRequest(url: url, session: session)
        let data = try await send(request)
        return try JSONDecoder.profileDecoder.decode([UserProfile].self, from: data).first
    }

    private func authorizedRequest(url: URL, session: AuthSession) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    @discardableResult
    private func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UserProfileError.requestFailed(errorMessage(from: data) ?? "Profil bilgisi okunamadı.")
        }
        return data
    }

    private func errorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return object["message"] as? String
            ?? object["hint"] as? String
            ?? object["details"] as? String
    }
}

private enum UserProfileError: LocalizedError {
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message):
            return message
        }
    }
}

private struct ProfileInsertRow: Encodable {
    let id: String
    let displayName: String?
    let avatarURL: String?
    let plan: String
    let planStatus: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case plan
        case planStatus = "plan_status"
    }
}

private struct ProfileDisplayNameUpdateRow: Encodable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

private extension JSONDecoder {
    static var profileDecoder: JSONDecoder {
        JSONDecoder()
    }
}
