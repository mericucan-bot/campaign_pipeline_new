import SwiftUI

struct CampaignCardView: View, Equatable {
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

            BankMarkView(kind: bankMarkKind, accent: accent)
                .frame(width: 54, height: 46)

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

    private var accent: Color {
        let bank = normalizedBankName
        if bank.contains("axess") || bank.contains("akbank") { return Color(red: 0.95, green: 0.65, blue: 0.08) }
        if bank.contains("maximum") || bank.contains("is bankasi") { return Color(red: 0.91, green: 0.18, blue: 0.50) }
        if bank.contains("garanti") { return Color(red: 0.18, green: 0.78, blue: 0.34) }
        if bank.contains("paraf") { return Color(red: 0.02, green: 0.72, blue: 0.86) }
        if bank.contains("saglam") || bank.contains("sağlam") { return Color(red: 0.00, green: 0.68, blue: 0.59) }
        if bank.contains("n kolay") || bank.contains("nkolay") { return Color(red: 0.07, green: 0.50, blue: 0.94) }
        if bank.contains(" on ") || bank == "on" || bank.contains("on kart") { return Color(red: 0.02, green: 0.74, blue: 0.35) }
        if bank.contains("teb") { return Color(red: 0.03, green: 0.57, blue: 0.28) }
        if bank.contains("vakif") { return Color(red: 0.94, green: 0.58, blue: 0.08) }
        if isYapiKrediBank { return Color(red: 0.56, green: 0.19, blue: 0.73) }
        if bank.contains("qnb") { return Color(red: 0.52, green: 0.23, blue: 0.68) }
        if bank.contains("deniz") { return Color(red: 0.14, green: 0.47, blue: 0.88) }
        if bank.contains("kuveyt") { return Color(red: 0.08, green: 0.58, blue: 0.36) }
        if bank.contains("ziraat") { return Color(red: 0.80, green: 0.06, blue: 0.11) }
        return AppTheme.dashboardGreen
    }

    private var normalizedBankName: String {
        campaign.displayBank
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .replacingOccurrences(of: "ı", with: "i")
    }

    private var isYapiKrediBank: Bool {
        let bank = normalizedBankName
        let rawBank = campaign.bank
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .replacingOccurrences(of: "ı", with: "i")
        return bank == "ykb"
            || bank.contains("yapi kredi")
            || bank.contains("world")
            || rawBank.contains("yapi kredi")
            || rawBank.contains("world")
    }

    private var bankMarkKind: BankMarkKind {
        let bank = normalizedBankName
        if bank.contains("axess") || bank.contains("akbank") { return .axess }
        if bank.contains("maximum") || bank.contains("is bankasi") { return .maximum }
        if bank.contains("garanti") { return .garanti }
        if bank.contains("paraf") { return .paraf }
        if bank.contains("saglam") || bank.contains("sağlam") { return .saglam }
        if bank.contains("n kolay") || bank.contains("nkolay") { return .nKolay }
        if bank.contains(" on ") || bank == "on" || bank.contains("on kart") { return .onDigital }
        if bank.contains("teb") { return .teb }
        if bank.contains("vakif") { return .vakif }
        if isYapiKrediBank { return .yapiKredi }
        if bank.contains("qnb") { return .qnb }
        if bank.contains("deniz") { return .deniz }
        if bank.contains("kuveyt") { return .kuveyt }
        if bank.contains("ziraat") { return .ziraat }
        return .monogram(campaign.displayBank)
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

private enum BankMarkKind: Equatable {
    case axess
    case maximum
    case garanti
    case paraf
    case saglam
    case nKolay
    case onDigital
    case teb
    case vakif
    case yapiKredi
    case qnb
    case deniz
    case kuveyt
    case ziraat
    case monogram(String)
}

private struct BankMarkView: View {
    let kind: BankMarkKind
    let accent: Color

    var body: some View {
        ZStack {
            switch kind {
            case .axess:
                Text("axess")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .italic()
            case .maximum:
                Text("M")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, accent.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            case .garanti:
                CloverMark()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.95), accent.opacity(0.62)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
            case .paraf:
                Text("Paraf.")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .italic()
            case .saglam:
                Text("S")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.white.opacity(0.45), lineWidth: 2)
                            .rotationEffect(.degrees(30))
                            .frame(width: 34, height: 34)
                    }
            case .nKolay:
                Text("N")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .italic()
            case .onDigital:
                ZStack {
                    Circle()
                        .trim(from: 0.10, to: 0.92)
                        .stroke(markGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(18))
                    Circle()
                        .fill(.white.opacity(0.92))
                        .frame(width: 8, height: 8)
                        .offset(x: 15, y: -15)
                }
                .frame(width: 34, height: 34)
            case .teb:
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(.white.opacity(0.92))
                        .frame(width: 34, height: 34)
                    HStack(spacing: -2) {
                        ForEach(0..<4, id: \.self) { index in
                            Image(systemName: "sparkle")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(accent)
                                .rotationEffect(.degrees(Double(index) * 18))
                        }
                    }
                }
            case .vakif:
                Text("V")
                    .font(.system(size: 39, weight: .black, design: .rounded))
                    .italic()
            case .yapiKredi:
                HStack(spacing: -8) {
                    LoopMark()
                    LoopMark()
                }
                .frame(width: 42, height: 30)
            case .qnb:
                Text("Q")
                    .font(.system(size: 38, weight: .black, design: .rounded))
            case .deniz:
                Text("DB")
                    .font(.system(size: 25, weight: .black, design: .rounded))
            case .kuveyt:
                Text("KT")
                    .font(.system(size: 24, weight: .black, design: .rounded))
            case .ziraat:
                Text("Z")
                    .font(.system(size: 38, weight: .black, design: .rounded))
            case .monogram(let name):
                Text(initials(for: name))
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(markGradient)
        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
    }

    private var markGradient: LinearGradient {
        LinearGradient(
            colors: markColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var markColors: [Color] {
        switch kind {
        case .axess:
            return [Color(red: 1.00, green: 0.84, blue: 0.28), Color(red: 0.89, green: 0.49, blue: 0.04)]
        case .maximum:
            return [Color(red: 1.00, green: 0.45, blue: 0.70), Color(red: 0.82, green: 0.10, blue: 0.42)]
        case .garanti:
            return [Color(red: 0.52, green: 0.96, blue: 0.58), Color(red: 0.03, green: 0.55, blue: 0.23)]
        case .paraf:
            return [Color(red: 0.25, green: 0.91, blue: 1.00), Color(red: 0.00, green: 0.53, blue: 0.68)]
        case .saglam:
            return [Color(red: 0.23, green: 0.93, blue: 0.83), Color(red: 0.00, green: 0.48, blue: 0.42)]
        case .nKolay:
            return [Color(red: 0.32, green: 0.72, blue: 1.00), Color(red: 0.00, green: 0.35, blue: 0.86)]
        case .onDigital:
            return [Color(red: 0.23, green: 0.93, blue: 0.50), Color(red: 0.00, green: 0.48, blue: 0.25)]
        case .teb:
            return [Color(red: 0.68, green: 0.97, blue: 0.72), Color(red: 0.02, green: 0.52, blue: 0.24)]
        case .vakif:
            return [Color(red: 1.00, green: 0.78, blue: 0.22), Color(red: 0.90, green: 0.44, blue: 0.03)]
        case .yapiKredi:
            return [Color(red: 0.98, green: 0.64, blue: 1.00), Color(red: 0.42, green: 0.14, blue: 0.72)]
        case .qnb:
            return [Color(red: 0.78, green: 0.46, blue: 0.88), Color(red: 0.36, green: 0.12, blue: 0.56)]
        case .deniz:
            return [Color(red: 0.45, green: 0.75, blue: 1.00), Color(red: 0.06, green: 0.36, blue: 0.78)]
        case .kuveyt:
            return [Color(red: 0.38, green: 0.90, blue: 0.54), Color(red: 0.02, green: 0.42, blue: 0.26)]
        case .ziraat:
            return [Color(red: 1.00, green: 0.38, blue: 0.42), Color(red: 0.70, green: 0.02, blue: 0.08)]
        case .monogram:
            return [.white.opacity(0.96), accent.opacity(0.75)]
        }
    }

    private func initials(for name: String) -> String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map { String($0) }
            .joined()
            .uppercased()
    }
}

private struct CloverMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let petalWidth = rect.width * 0.34
        let petalHeight = rect.height * 0.52

        for index in 0..<5 {
            let angle = Angle.degrees(Double(index) * 72 - 90).radians
            let petalCenter = CGPoint(
                x: center.x + cos(angle) * rect.width * 0.18,
                y: center.y + sin(angle) * rect.height * 0.18
            )
            let petalRect = CGRect(
                x: petalCenter.x - petalWidth / 2,
                y: petalCenter.y - petalHeight / 2,
                width: petalWidth,
                height: petalHeight
            )
            var petal = Path(ellipseIn: petalRect)
            petal = petal.applying(.init(translationX: -petalCenter.x, y: -petalCenter.y))
            petal = petal.applying(.init(rotationAngle: angle + .pi / 2))
            petal = petal.applying(.init(translationX: petalCenter.x, y: petalCenter.y))
            path.addPath(petal)
        }

        path.addEllipse(in: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
        return path
    }
}

private struct LoopMark: View {
    var body: some View {
        Circle()
            .trim(from: 0.08, to: 0.92)
            .stroke(.white.opacity(0.92), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            .rotationEffect(.degrees(35))
            .frame(width: 27, height: 20)
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
