import SwiftUI

struct CampaignCardView: View {
    let campaign: Campaign
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(campaign.displayBank)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isFavorite ? .yellow : AppTheme.muted.opacity(0.75))
            }

            Text(campaign.title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)

            Text(campaign.displaySummary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .lineLimit(3)

            HStack(spacing: 8) {
                Badge(text: campaign.category ?? "Genel", foreground: .teal, background: AppTheme.aqua.opacity(0.28))
                Badge(text: campaign.rewardType ?? "Firsat", foreground: .blue, background: AppTheme.softBlue)
                Badge(text: campaign.deadlineText, foreground: .orange, background: AppTheme.softOrange)
            }

            if let score = campaign.opportunityScore {
                ProgressView(value: Double(score), total: 100) {
                    Text("Firsat skoru \(score)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
                .tint(AppTheme.electricBlue)
            }
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

private struct Badge: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(Capsule())
    }
}
