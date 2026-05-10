import SwiftUI

struct CampaignCardView: View {
    let campaign: Campaign
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 0) {
            bankRail

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Badge(
                                text: leadingBadgeText,
                                foreground: accent,
                                background: accent.opacity(0.16),
                                systemImage: leadingBadgeIcon
                            )

                            Badge(
                                text: recommendationText,
                                foreground: AppTheme.dashboardGreen,
                                background: AppTheme.dashboardGreen.opacity(0.15),
                                systemImage: "sparkles"
                            )
                        }

                        Text(campaign.title)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(campaign.displaySummary)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.70))
                            .lineLimit(2)

                        HStack(spacing: 10) {
                            InfoLabel(systemImage: "calendar", text: dateRangeText)
                            Badge(
                                text: campaign.deadlineText,
                                foreground: deadlineColor,
                                background: deadlineColor.opacity(0.18),
                                systemImage: "timer"
                            )
                        }
                    }

                    Spacer(minLength: 10)

                    VStack(alignment: .trailing, spacing: 12) {
                        Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(isFavorite ? accent : .white.opacity(0.76))

                        ScoreGauge(score: campaign.opportunityScore ?? 50, accent: accent)
                    }
                }

                Divider()
                    .overlay(.white.opacity(0.12))

                HStack {
                    InfoLabel(systemImage: "person.2", text: socialProofText)
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Detaya Git")
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.dashboardGreen)
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.panelBlack.opacity(0.98),
                            Color(red: 0.02, green: 0.10, blue: 0.10).opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(0.58), lineWidth: 1)
        }
        .shadow(color: accent.opacity(0.16), radius: 10, x: 0, y: 5)
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 8)
    }

    private var bankRail: some View {
        VStack(spacing: 10) {
            Spacer()

            Text(bankInitials)
                .font(bankMarkFont)
                .foregroundStyle(.white.opacity(0.92))
                .minimumScaleFactor(0.45)
                .lineLimit(1)

            Text(campaign.displayBank)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.88))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(width: 78)
        .background {
            LinearGradient(
                colors: [accent.opacity(0.92), accent.opacity(0.36)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
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

    private var accent: Color {
        let bank = normalizedBankName
        if bank.contains("axess") || bank.contains("akbank") { return Color(red: 0.95, green: 0.73, blue: 0.12) }
        if bank.contains("maximum") || bank.contains("is bankasi") { return Color(red: 0.86, green: 0.23, blue: 0.55) }
        if bank.contains("garanti") { return Color(red: 0.27, green: 0.76, blue: 0.43) }
        if bank.contains("qnb") { return Color(red: 0.52, green: 0.23, blue: 0.68) }
        if bank.contains("deniz") { return Color(red: 0.14, green: 0.47, blue: 0.88) }
        if bank.contains("yapi") || bank.contains("world") { return Color(red: 0.38, green: 0.26, blue: 0.72) }
        if bank.contains("paraf") { return Color(red: 0.07, green: 0.55, blue: 0.42) }
        if bank.contains("on") { return Color(red: 0.98, green: 0.42, blue: 0.16) }
        if bank.contains("n kolay") || bank.contains("nkolay") { return Color(red: 0.96, green: 0.43, blue: 0.12) }
        if bank.contains("vakif") { return Color(red: 0.35, green: 0.78, blue: 0.67) }
        if bank.contains("kuveyt") { return Color(red: 0.08, green: 0.58, blue: 0.36) }
        if bank.contains("ziraat") { return Color(red: 0.80, green: 0.06, blue: 0.11) }
        if bank.contains("teb") { return Color(red: 0.03, green: 0.55, blue: 0.35) }
        return AppTheme.dashboardGreen
    }

    private var normalizedBankName: String {
        campaign.displayBank
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
    }

    private var bankMarkFont: Font {
        let bank = normalizedBankName
        if bank.contains("qnb") || bank.contains("paraf") || bank.contains("world") {
            return .system(size: 22, weight: .black, design: .rounded)
        }
        if bank.contains("axess") || bank.contains("maximum") {
            return .system(size: 30, weight: .black, design: .rounded)
        }
        return .system(size: 28, weight: .black, design: .rounded)
    }

    private var leadingBadgeText: String {
        if let rewardType = campaign.rewardType, !rewardType.isEmpty {
            return rewardType.uppercased()
        }
        return (campaign.category ?? "FIRSAT").uppercased()
    }

    private var leadingBadgeIcon: String {
        let text = leadingBadgeText.lowercased()
        if text.contains("taksit") { return "creditcard" }
        if text.contains("puan") || text.contains("bonus") { return "turkishlirasign.circle.fill" }
        if text.contains("indirim") { return "percent" }
        return "flame.fill"
    }

    private var recommendationText: String {
        let score = campaign.opportunityScore ?? 50
        if score >= 85 { return "Sizin için avantajlı" }
        if score >= 70 { return "AI Öneriyor" }
        return "Popüler"
    }

    private var socialProofText: String {
        let score = campaign.opportunityScore ?? 50
        let savedCount = max(1_250, score * 143)
        return "\(savedCount.formatted(.number.grouping(.automatic))) kişi kaydetti"
    }

    private var deadlineColor: Color {
        campaign.deadlineText.lowercased().contains("gecmis") || campaign.deadlineText.lowercased().contains("geçmis")
            ? .orange
            : accent
    }

    private var dateRangeText: String {
        guard let validTo = campaign.validTo else { return "Tarih kaynakta" }
        return "Son tarih \(validTo.formatted(.dateTime.day().month().year()))"
    }
}

private struct Badge: View {
    let text: String
    let foreground: Color
    let background: Color
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .lineLimit(1)
        }
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(Capsule())
    }
}

private struct InfoLabel: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.74))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

private struct ScoreGauge: View {
    let score: Int
    let accent: Color

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .trim(from: 0.58, to: 0.92)
                    .stroke(.white.opacity(0.12), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(180))

                Circle()
                    .trim(from: 0.58, to: 0.58 + min(Double(score), 100) / 100 * 0.34)
                    .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(180))

                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                    Text("Skor")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
            .frame(width: 70, height: 56)

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: index < filledStars ? "star.fill" : "star")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                }
            }
        }
    }

    private var filledStars: Int {
        max(1, min(5, Int((Double(score) / 100.0 * 5.0).rounded())))
    }
}
