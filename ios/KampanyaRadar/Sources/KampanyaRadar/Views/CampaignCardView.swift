import SwiftUI

struct CampaignCardView: View {
    let campaign: Campaign
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(campaign.displayBank)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
            }

            Text(campaign.title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(campaign.displaySummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack(spacing: 8) {
                Badge(text: campaign.category ?? "Genel", color: .teal)
                Badge(text: campaign.rewardType ?? "Firsat", color: .blue)
                Badge(text: campaign.deadlineText, color: .orange)
            }

            if let score = campaign.opportunityScore {
                ProgressView(value: Double(score), total: 100) {
                    Text("Firsat skoru \(score)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

