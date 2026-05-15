import Foundation

enum UserDataSyncError: LocalizedError {
    case missingSession
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingSession:
            return "Senkron için aktif oturum bulunamadı."
        case .requestFailed(let message):
            return message
        }
    }
}

struct UserDataSyncService {
    func sync(
        session: AuthSession?,
        favorites: FavoritesStore,
        myCards: MyCardsStore,
        participation: ParticipationStore
    ) async throws {
        guard let session else { throw UserDataSyncError.missingSession }

        try await uploadLocalData(
            session: session,
            favoriteIDs: favorites.ids,
            cardBanks: myCards.banks,
            participationRecords: participation.records
        )

        let cloud = try await fetchCloudData(session: session)
        await MainActor.run {
            favorites.replace(with: favorites.ids.union(cloud.favoriteIDs))
            myCards.replace(with: myCards.banks.union(cloud.cardBanks))

            var mergedParticipation = participation.records
            for (campaignID, record) in cloud.participationRecords where mergedParticipation[campaignID] == nil {
                mergedParticipation[campaignID] = record
            }
            participation.replace(with: mergedParticipation)
        }
    }

    private func uploadLocalData(
        session: AuthSession,
        favoriteIDs: Set<String>,
        cardBanks: Set<String>,
        participationRecords: [String: CampaignParticipation]
    ) async throws {
        if !cardBanks.isEmpty {
            let rows = cardBanks.sorted().map {
                UserCardRow(userID: session.user.id, bank: $0, bankLabel: nil)
            }
            try await upsert(rows, table: "user_cards", conflict: "user_id,bank", session: session)
        }

        if !favoriteIDs.isEmpty {
            let rows = favoriteIDs.sorted().map {
                UserFavoriteRow(userID: session.user.id, campaignID: $0)
            }
            try await upsert(rows, table: "user_favorites", conflict: "user_id,campaign_id", session: session)
        }

        let participationRows = participationRecords.map { campaignID, record in
            CampaignParticipationRow(
                userID: session.user.id,
                campaignID: campaignID,
                didJoin: record.didJoin,
                spentAmount: record.spentAmount,
                earnedAmount: record.earnedAmount,
                rewardExpiresAt: record.rewardExpiresAt?.yyyyMMddText,
                reminderEnabled: record.hasReminder
            )
        }
        if !participationRows.isEmpty {
            try await upsert(participationRows, table: "campaign_participations", conflict: "user_id,campaign_id", session: session)
        }
    }

    private func fetchCloudData(session: AuthSession) async throws -> CloudUserData {
        async let cards: [UserCardRow] = getRows(table: "user_cards", query: "select=user_id,bank,bank_label", session: session)
        async let favorites: [UserFavoriteRow] = getRows(table: "user_favorites", query: "select=user_id,campaign_id", session: session)
        async let participations: [CampaignParticipationRow] = getRows(
            table: "campaign_participations",
            query: "select=user_id,campaign_id,did_join,spent_amount,earned_amount,reward_expires_at,reminder_enabled",
            session: session
        )

        let cloudCards = try await cards
        let cloudFavorites = try await favorites
        let cloudParticipations = try await participations

        return CloudUserData(
            cardBanks: Set(cloudCards.map(\.bank)),
            favoriteIDs: Set(cloudFavorites.map(\.campaignID)),
            participationRecords: Dictionary(uniqueKeysWithValues: cloudParticipations.map { row in
                (
                    row.campaignID,
                    CampaignParticipation(
                        didJoin: row.didJoin,
                        spentAmount: row.spentAmount,
                        earnedAmount: row.earnedAmount,
                        rewardExpiresAt: row.rewardExpiresAt.flatMap(Date.yyyyMMddFormatter.date(from:))
                    )
                )
            })
        )
    }

    private func upsert<T: Encodable>(_ rows: [T], table: String, conflict: String, session: AuthSession) async throws {
        guard var components = URLComponents(url: AppConfig.supabaseURL.appendingPathComponent("rest/v1/\(table)"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "on_conflict", value: conflict)]
        guard let url = components.url else { throw URLError(.badURL) }

        var request = authorizedRequest(url: url, session: session)
        request.httpMethod = "POST"
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONEncoder.userDataEncoder.encode(rows)
        try await send(request)
    }

    private func getRows<T: Decodable>(table: String, query: String, session: AuthSession) async throws -> [T] {
        guard let url = URL(string: "rest/v1/\(table)?\(query)", relativeTo: AppConfig.supabaseURL) else {
            throw URLError(.badURL)
        }
        let request = authorizedRequest(url: url, session: session)
        let data = try await send(request)
        return try JSONDecoder.userDataDecoder.decode([T].self, from: data)
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
            throw UserDataSyncError.requestFailed(errorMessage(from: data) ?? "Kullanıcı verisi senkronlanamadı.")
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

private struct CloudUserData {
    let cardBanks: Set<String>
    let favoriteIDs: Set<String>
    let participationRecords: [String: CampaignParticipation]
}

private struct UserCardRow: Codable {
    let userID: String
    let bank: String
    let bankLabel: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case bank
        case bankLabel = "bank_label"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(bank, forKey: .bank)
        if let bankLabel {
            try container.encode(bankLabel, forKey: .bankLabel)
        } else {
            try container.encodeNil(forKey: .bankLabel)
        }
    }
}

private struct UserFavoriteRow: Codable {
    let userID: String
    let campaignID: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case campaignID = "campaign_id"
    }
}

private struct CampaignParticipationRow: Codable {
    let userID: String
    let campaignID: String
    let didJoin: Bool
    let spentAmount: Double
    let earnedAmount: Double
    let rewardExpiresAt: String?
    let reminderEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case campaignID = "campaign_id"
        case didJoin = "did_join"
        case spentAmount = "spent_amount"
        case earnedAmount = "earned_amount"
        case rewardExpiresAt = "reward_expires_at"
        case reminderEnabled = "reminder_enabled"
    }

    init(
        userID: String,
        campaignID: String,
        didJoin: Bool,
        spentAmount: Double,
        earnedAmount: Double,
        rewardExpiresAt: String?,
        reminderEnabled: Bool
    ) {
        self.userID = userID
        self.campaignID = campaignID
        self.didJoin = didJoin
        self.spentAmount = spentAmount
        self.earnedAmount = earnedAmount
        self.rewardExpiresAt = rewardExpiresAt
        self.reminderEnabled = reminderEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(String.self, forKey: .userID)
        campaignID = try container.decode(String.self, forKey: .campaignID)
        didJoin = try container.decodeIfPresent(Bool.self, forKey: .didJoin) ?? false
        spentAmount = try container.decodeIfPresent(Double.self, forKey: .spentAmount) ?? 0
        earnedAmount = try container.decodeIfPresent(Double.self, forKey: .earnedAmount) ?? 0
        rewardExpiresAt = try container.decodeIfPresent(String.self, forKey: .rewardExpiresAt)
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(campaignID, forKey: .campaignID)
        try container.encode(didJoin, forKey: .didJoin)
        try container.encode(spentAmount, forKey: .spentAmount)
        try container.encode(earnedAmount, forKey: .earnedAmount)
        if let rewardExpiresAt {
            try container.encode(rewardExpiresAt, forKey: .rewardExpiresAt)
        } else {
            try container.encodeNil(forKey: .rewardExpiresAt)
        }
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
    }
}

private extension JSONEncoder {
    static var userDataEncoder: JSONEncoder {
        JSONEncoder()
    }
}

private extension JSONDecoder {
    static var userDataDecoder: JSONDecoder {
        JSONDecoder()
    }
}

private extension Date {
    static let yyyyMMddFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var yyyyMMddText: String {
        Self.yyyyMMddFormatter.string(from: self)
    }
}
