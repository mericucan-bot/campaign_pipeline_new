import SwiftUI

struct CampaignCardView: View {
    let campaign: Campaign
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(bankInitials)
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppTheme.nearBlack)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.dashboardGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(campaign.displayBank)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(campaign.deadlineText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }

                Spacer()

                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isFavorite ? AppTheme.dashboardGreen : AppTheme.muted.opacity(0.75))
            }

            Text(campaign.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(3)

            Text(campaign.displaySummary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
                .lineLimit(3)

            HStack(spacing: 8) {
                Badge(text: campaign.category ?? "Genel", foreground: AppTheme.nearBlack, background: AppTheme.softGreen)
                Badge(text: campaign.rewardType ?? "Firsat", foreground: AppTheme.nearBlack, background: AppTheme.dashboardGreen.opacity(0.22))
                Badge(text: campaign.deadlineText, foreground: .orange, background: AppTheme.softOrange)
            }

            if let score = campaign.opportunityScore {
                ProgressView(value: Double(score), total: 100) {
                    Text("Firsat skoru \(score)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }
                .tint(AppTheme.dashboardGreen)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, AppTheme.softGreen.opacity(0.30)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppTheme.dashboardGreen.opacity(0.24), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    private var bankInitials: String {
        campaign.displayBank
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map { String($0) }
            .joined()
            .uppercased()
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
