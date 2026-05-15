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
                return campaigns
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
