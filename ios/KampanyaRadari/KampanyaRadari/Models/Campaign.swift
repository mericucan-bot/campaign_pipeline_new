import Foundation

struct Campaign: Identifiable, Codable, Hashable {
    let id: String
    let bank: String
    let bankLabel: String?
    let title: String
    let summary: String?
    let description: String?
    let imageURL: URL?
    let sourceURL: URL?
    let category: String?
    let rewardType: String?
    let rewardValue: Double?
    let validTo: Date?
    let opportunityScore: Int?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case bank
        case bankLabel = "bank_label"
        case title
        case summary
        case description
        case imageURL = "image_url"
        case sourceURL = "source_url"
        case category
        case rewardType = "reward_type"
        case rewardValue = "reward_value"
        case validTo = "valid_to"
        case opportunityScore = "opportunity_score"
        case isActive = "is_active"
    }

    var displayBank: String {
        guard let bankLabel, !bankLabel.isEmpty else { return bank }
        return bankLabel
    }

    var displaySummary: String {
        if let summary, !summary.isEmpty { return summary }
        if let description, !description.isEmpty { return description }
        return "Detaylar kaynak sayfada."
    }

    var deadlineText: String {
        guard let validTo else { return "Tarih kaynakta" }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let deadline = calendar.startOfDay(for: validTo)
        let days = calendar.dateComponents([.day], from: today, to: deadline).day ?? 0

        if days < 0 { return "Suresi gecmis" }
        if days == 0 { return "Bugun bitiyor" }
        if days <= 7 { return "Son \(days) gun" }

        return validTo.formatted(.dateTime.day().month().year())
    }
}

extension JSONDecoder {
    static var campaignDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
            if let date = ISO8601DateFormatter().date(from: value) {
                return date
            }
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: value) {
                return date
            }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(value)")
            )
        }
        return decoder
    }
}
