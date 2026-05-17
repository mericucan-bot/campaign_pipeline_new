import Foundation

struct CampaignService {
    private let pageSize = 1_000

    func fetchActiveCampaigns() async throws -> [Campaign] {
        var campaigns: [Campaign] = []
        var offset = 0

        while true {
            let page = try await fetchCampaignPage(offset: offset)
            campaigns.append(contentsOf: page)

            if page.count < pageSize {
                return campaigns.filter { $0.isCurrentOrUndated && $0.isDisplayableCampaign }
            }
            offset += pageSize
        }
    }

    private func fetchCampaignPage(offset: Int) async throws -> [Campaign] {
        var components = URLComponents(
            url: AppConfig.supabaseURL.appending(path: "rest/v1/campaigns"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(
                name: "select",
                value: [
                    "id",
                    "bank",
                    "bank_label",
                    "title",
                    "summary",
                    "description",
                    "image_url",
                    "source_url",
                    "category",
                    "reward_type",
                    "reward_value",
                    "valid_to",
                    "opportunity_score",
                    "is_active",
                ].joined(separator: ",")
            ),
            URLQueryItem(name: "is_active", value: "eq.true"),
            URLQueryItem(name: "order", value: "valid_to.asc.nullslast"),
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("items", forHTTPHeaderField: "Range-Unit")
        request.setValue("\(offset)-\(offset + pageSize - 1)", forHTTPHeaderField: "Range")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder.campaignDecoder.decode([Campaign].self, from: data)
    }
}

private extension Campaign {
    var isCurrentOrUndated: Bool {
        guard let validTo else { return true }
        let calendar = Calendar.current
        return calendar.startOfDay(for: validTo) >= calendar.startOfDay(for: Date())
    }

    var isDisplayableCampaign: Bool {
        let normalizedTitle = title.normalizedCampaignText
        guard normalizedTitle.count > 2 else { return false }

        let blockedTitles: Set<String> = [
            "70 giyim",
            "8 yurt disi alisverisi",
            "8 yurtdisi alisverisi",
        ]
        if blockedTitles.contains(normalizedTitle) {
            return false
        }

        let body = [title, summary, description]
            .compactMap { $0 }
            .joined(separator: " ")
            .normalizedCampaignText
        if body.contains("tum haklari saklidir"),
           normalizedTitle.hasPrefix("70 ") || normalizedTitle.hasPrefix("8 ") {
            return false
        }

        return true
    }
}

private extension String {
    var normalizedCampaignText: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: #"[^a-z0-9%+ ]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
