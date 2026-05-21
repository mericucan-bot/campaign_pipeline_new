import SwiftUI
import UIKit

// MARK: - Usage
// 1) Add this file to your Xcode SwiftUI project.
// 2) Add real logo images to Assets.xcassets with names used in BankLogoAsset.name.
// 3) Show KampanyaRadariOnboardingView() from your app/root view.

struct KampanyaRadariOnboardingView: View {
    @State private var page: Int = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PremiumBackground()

                TabView(selection: $page) {
                    SectorRadarPage(page: $page).tag(0)
                    SavingsPage(page: $page).tag(1)
                    BankCardsPage(page: $page).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Page 1

struct SectorRadarPage: View {
    @Binding var page: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                PremiumBackground()

                RadarSectorIllustration()
                    .frame(width: w * 0.93, height: h * 0.48)
                    .position(x: w / 2, y: h * 0.37)

                OnboardingTextBlock(
                    badgeIcon: "scope",
                    badgeTitle: "Kampanya",
                    badgeHighlight: "RADARI",
                    title: "En iyi fırsatları...",
                    subtitle: "Binlerce kampanya içinden sana en uygun olanları radarına al.",
                    page: 0,
                    buttonTitle: "İleri",
                    showsArrow: true,
                    action: { withAnimation(.spring()) { page = 1 } }
                )
                .frame(width: w, height: h * 0.35)
                .position(x: w / 2, y: h * 0.82)
            }
        }
    }
}

struct RadarSectorIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            let cy = h * 0.52
            let r = min(w, h) * 0.39

            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [AppColors.mint.opacity(0.12), .clear], center: .center, startRadius: 0, endRadius: r * 1.05))
                    .frame(width: r * 2.1, height: r * 2.1)
                    .position(x: cx, y: cy)

                RadarShape(ringCount: 4, sweepAngle: .degrees(28))
                    .stroke(AppColors.mint.opacity(0.22), lineWidth: 1)
                    .background(RadarSweepShape(angle: .degrees(28)).fill(AppColors.mint.opacity(0.18)))
                    .frame(width: r * 2, height: r * 2)
                    .position(x: cx, y: cy)
                    .shadow(color: AppColors.mint.opacity(0.25), radius: 18)

                ForEach(RadarDot.sampleDots, id: \.id) { dot in
                    Circle()
                        .fill(AppColors.mint)
                        .frame(width: dot.size, height: dot.size)
                        .shadow(color: AppColors.mint, radius: 8)
                        .position(x: cx + dot.x * r, y: cy + dot.y * r)
                }

                SectorPill(title: "Market", systemIcon: "cart.fill")
                    .frame(width: w * 0.36, height: 64)
                    .position(x: w * 0.20, y: h * 0.16)

                SectorPill(title: "Yakıt", systemIcon: "fuelpump.fill")
                    .frame(width: w * 0.31, height: 64)
                    .position(x: w * 0.78, y: h * 0.16)

                SectorPill(title: "Alışveriş", systemIcon: "bag.fill")
                    .frame(width: w * 0.38, height: 64)
                    .position(x: w * 0.22, y: h * 0.80)

                SectorPill(title: "Seyahat", systemIcon: "airplane")
                    .frame(width: w * 0.36, height: 64)
                    .position(x: w * 0.76, y: h * 0.78)
            }
        }
    }
}

struct SectorPill: View {
    let title: String
    let systemIcon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemIcon)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(AppColors.mint)
            Text(title)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Capsule()
                .fill(AppColors.cardFill)
                .overlay(Capsule().stroke(AppColors.mint.opacity(0.48), lineWidth: 1.2))
                .shadow(color: AppColors.mint.opacity(0.18), radius: 12)
        )
    }
}

// MARK: - Page 2

struct SavingsPage: View {
    @Binding var page: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                PremiumBackground()

                SavingsJarIllustration()
                    .frame(width: w * 0.9, height: h * 0.48)
                    .position(x: w / 2, y: h * 0.36)

                OnboardingTextBlock(
                    badgeIcon: "scope",
                    badgeTitle: "Kampanya",
                    badgeHighlight: "RADARI",
                    title: "Tasarruf et,...",
                    subtitle: "Kaçırdığın fırsatları bul, birikimini artır, her alışverişte avantaj yakala.",
                    page: 1,
                    buttonTitle: "Başlayalım",
                    showsArrow: false,
                    action: { withAnimation(.spring()) { page = 2 } }
                )
                .frame(width: w, height: h * 0.35)
                .position(x: w / 2, y: h * 0.82)
            }
        }
    }
}

struct SavingsJarIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            let cy = h * 0.55

            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [AppColors.mint.opacity(0.28), AppColors.mint.opacity(0.08), .clear], center: .center, startRadius: 0, endRadius: w * 0.45))
                    .frame(width: w * 0.95, height: w * 0.95)
                    .position(x: cx, y: cy)

                Circle()
                    .stroke(AppColors.mint.opacity(0.35), lineWidth: 1.4)
                    .frame(width: w * 0.64, height: w * 0.64)
                    .position(x: cx, y: cy)

                iconCircle("chart.bar", x: w * 0.16, y: h * 0.27)
                iconCircle("creditcard", x: w * 0.50, y: h * 0.13)
                iconCircle("piggybank", x: w * 0.84, y: h * 0.27)
                iconCircle("percent", x: w * 0.18, y: h * 0.66)
                iconCircle("bell", x: w * 0.82, y: h * 0.66)

                JarBody()
                    .frame(width: w * 0.43, height: h * 0.43)
                    .position(x: cx, y: cy + h * 0.05)

                CoinStack()
                    .frame(width: w * 0.19, height: h * 0.20)
                    .position(x: cx + w * 0.10, y: cy + h * 0.10)

                Text("₺")
                    .font(.system(size: 70, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColors.mint.opacity(0.75))
                    .frame(width: w * 0.22, height: w * 0.22)
                    .background(Circle().fill(AppColors.mint.opacity(0.22)))
                    .overlay(Circle().stroke(AppColors.mint.opacity(0.7), lineWidth: 2))
                    .shadow(color: AppColors.mint.opacity(0.35), radius: 14)
                    .position(x: cx - w * 0.08, y: cy + h * 0.13)
            }
        }
    }

    private func iconCircle(_ name: String, x: CGFloat, y: CGFloat) -> some View {
        Image(systemName: name)
            .font(.system(size: 29, weight: .medium))
            .foregroundStyle(AppColors.mint)
            .frame(width: 82, height: 82)
            .background(Circle().fill(AppColors.cardFill))
            .overlay(Circle().stroke(AppColors.mint.opacity(0.65), lineWidth: 1.4))
            .shadow(color: AppColors.mint.opacity(0.23), radius: 12)
            .position(x: x, y: y)
    }
}

struct JarBody: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(colors: [AppColors.mint.opacity(0.22), AppColors.mint.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(AppColors.mint.opacity(0.70), lineWidth: 2))
            Capsule()
                .fill(AppColors.mint.opacity(0.22))
                .overlay(Capsule().stroke(AppColors.mint.opacity(0.72), lineWidth: 1.8))
                .frame(height: 36)
                .offset(y: -95)
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.08))
                .frame(width: 18)
                .offset(x: -54)
        }
    }
}

struct CoinStack: View {
    var body: some View {
        VStack(spacing: -2) {
            ForEach(0..<6, id: \.self) { _ in
                Capsule()
                    .fill(LinearGradient(colors: [AppColors.mint.opacity(0.6), AppColors.mint.opacity(0.25)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 18)
                    .overlay(Capsule().stroke(AppColors.mint.opacity(0.8), lineWidth: 1))
            }
        }
        .shadow(color: AppColors.mint.opacity(0.28), radius: 10)
    }
}

// MARK: - Page 3

struct BankCardsPage: View {
    @Binding var page: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                PremiumBackground()

                BankCardCloudView()
                    .frame(width: w * 0.96, height: h * 0.58)
                    .position(x: w / 2, y: h * 0.39)

                OnboardingTextBlock(
                    badgeIcon: "scope",
                    badgeTitle: "Kampanya",
                    badgeHighlight: "RADARI",
                    title: "Tüm fırsatlar\ntek radarında!",
                    subtitle: "Bankalardan kartlara, avantajlardan kampanyalara kadar aradığın her şey burada.",
                    page: 2,
                    buttonTitle: "Keşfetmeye başla",
                    showsArrow: true,
                    action: {}
                )
                .frame(width: w, height: h * 0.35)
                .position(x: w / 2, y: h * 0.82)
            }
        }
    }
}

struct BankCardCloudView: View {
    private let assets: [BankLogoAsset] = BankLogoAsset.all

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            let cy = h * 0.52

            ZStack {
                RadarCore()
                    .frame(width: w * 0.42, height: w * 0.42)
                    .position(x: cx, y: cy)

                ForEach(assets) { asset in
                    BankLogoCard(asset: asset)
                        .frame(width: asset.size.width * w, height: asset.size.height * h)
                        .position(x: asset.position.x * w, y: asset.position.y * h)
                }
            }
        }
    }
}

struct RadarCore: View {
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [AppColors.mint.opacity(0.18), .clear], center: .center, startRadius: 0, endRadius: 110))
            ForEach(1...4, id: \.self) { i in
                Circle().stroke(AppColors.mint.opacity(0.18), lineWidth: 1).scaleEffect(CGFloat(i) / 4)
            }
            Rectangle().fill(AppColors.mint.opacity(0.15)).frame(width: 1)
            Rectangle().fill(AppColors.mint.opacity(0.15)).frame(height: 1)
            RadarSweepShape(angle: .degrees(32)).fill(AppColors.mint.opacity(0.20))
            Circle().fill(AppColors.mint).frame(width: 10, height: 10).shadow(color: AppColors.mint, radius: 10)
        }
    }
}

struct BankLogoCard: View {
    let asset: BankLogoAsset

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Color.white.opacity(0.06), AppColors.cardFill], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(asset.color.opacity(0.8), lineWidth: 1.1))
                .shadow(color: asset.color.opacity(0.26), radius: 9)

            if UIImage(named: asset.name) != nil {
                Image(asset.name)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        HStack(spacing: 7) {
            if let symbol = asset.symbol {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(asset.color)
            }
            VStack(spacing: -1) {
                Text(asset.title)
                    .font(.system(size: asset.titleSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(asset.titleColor)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                if let subtitle = asset.subtitle {
                    Text(subtitle)
                        .font(.system(size: asset.titleSize * 0.52, weight: .heavy, design: .rounded))
                        .foregroundStyle(asset.subtitleColor ?? asset.color)
                        .minimumScaleFactor(0.45)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Shared UI

struct OnboardingTextBlock: View {
    let badgeIcon: String
    let badgeTitle: String
    let badgeHighlight: String
    let title: String
    let subtitle: String
    let page: Int
    let buttonTitle: String
    let showsArrow: Bool
    let action: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            VStack(alignment: .leading, spacing: 18) {
                BadgeView(icon: badgeIcon, title: badgeTitle, highlight: badgeHighlight)
                    .padding(.leading, 29)

                Text(title)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineSpacing(6)
                    .shadow(color: .black.opacity(0.32), radius: 6, x: 0, y: 4)
                    .padding(.horizontal, 29)

                Text(subtitle)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(8)
                    .padding(.horizontal, 29)

                Spacer(minLength: 8)

                HStack(alignment: .center) {
                    PaginationDots(current: page, count: 3)
                    Spacer()
                    Button(action: action) {
                        HStack(spacing: 10) {
                            Text(buttonTitle)
                            if showsArrow { Image(systemName: "arrow.right") }
                        }
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.88))
                        .frame(height: 58)
                        .padding(.horizontal, 28)
                        .background(Capsule().fill(LinearGradient(colors: [AppColors.mint, Color(hex: "63EBCB")], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .shadow(color: AppColors.mint.opacity(0.35), radius: 22, y: 10)
                    }
                }
                .padding(.horizontal, 29)
            }
            .frame(width: w, height: geo.size.height)
        }
    }
}

struct BadgeView: View {
    let icon: String
    let title: String
    let highlight: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppColors.mint)
            VStack(alignment: .leading, spacing: -1) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.88))
                Text(highlight)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(AppColors.mint)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Capsule().fill(AppColors.cardFill).overlay(Capsule().stroke(AppColors.mint.opacity(0.45), lineWidth: 1.2)))
    }
}

struct PaginationDots: View {
    let current: Int
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AppColors.mint : Color.white.opacity(0.22))
                    .frame(width: i == current ? 27 : 10, height: 10)
            }
        }
    }
}

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "07131D"), Color(hex: "020B12"), Color(hex: "01070C")], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [AppColors.mint.opacity(0.10), .clear], center: .center, startRadius: 20, endRadius: 360)
            RadialGradient(colors: [Color(hex: "0A2730").opacity(0.35), .clear], center: .topTrailing, startRadius: 0, endRadius: 420)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Shapes / Models

struct RadarShape: Shape {
    let ringCount: Int
    let sweepAngle: Angle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 1...ringCount {
            let rr = r * CGFloat(i) / CGFloat(ringCount)
            p.addEllipse(in: CGRect(x: center.x - rr, y: center.y - rr, width: rr * 2, height: rr * 2))
        }
        p.move(to: CGPoint(x: center.x - r, y: center.y)); p.addLine(to: CGPoint(x: center.x + r, y: center.y))
        p.move(to: CGPoint(x: center.x, y: center.y - r)); p.addLine(to: CGPoint(x: center.x, y: center.y + r))
        let end = CGPoint(x: center.x + cos(sweepAngle.radians) * r, y: center.y - sin(sweepAngle.radians) * r)
        p.move(to: center); p.addLine(to: end)
        return p
    }
}

struct RadarSweepShape: Shape {
    let angle: Angle
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.move(to: center)
        p.addArc(center: center, radius: r, startAngle: .degrees(270), endAngle: angle, clockwise: false)
        p.closeSubpath()
        return p
    }
}

struct RadarDot: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    static let sampleDots = [
        RadarDot(x: -0.33, y: -0.31, size: 6),
        RadarDot(x: 0.28, y: -0.15, size: 7),
        RadarDot(x: -0.29, y: 0.28, size: 7),
        RadarDot(x: 0.39, y: 0.33, size: 6),
        RadarDot(x: 0.00, y: -0.95, size: 5)
    ]
}

struct BankLogoAsset: Identifiable {
    let id = UUID()
    let name: String
    let title: String
    let subtitle: String?
    let color: Color
    let titleColor: Color
    let subtitleColor: Color?
    let symbol: String?
    let position: CGPoint // normalized
    let size: CGSize // normalized
    let titleSize: CGFloat

    static let all: [BankLogoAsset] = [
        .init(name: "maximum", title: "maximum", subtitle: nil, color: AppColors.pink, titleColor: AppColors.pink, subtitleColor: nil, symbol: nil, position: .init(x: 0.22, y: 0.16), size: .init(width: 0.27, height: 0.10), titleSize: 22),
        .init(name: "axess", title: "axess", subtitle: nil, color: AppColors.gold, titleColor: AppColors.gold, subtitleColor: nil, symbol: nil, position: .init(x: 0.50, y: 0.09), size: .init(width: 0.28, height: 0.10), titleSize: 25),
        .init(name: "garanti", title: "Garanti", subtitle: "BBVA", color: AppColors.green, titleColor: .white, subtitleColor: .white, symbol: "clover.fill", position: .init(x: 0.79, y: 0.16), size: .init(width: 0.30, height: 0.10), titleSize: 18),
        .init(name: "paraf", title: "Paraf.", subtitle: nil, color: AppColors.cyan, titleColor: AppColors.cyan, subtitleColor: nil, symbol: nil, position: .init(x: 0.18, y: 0.33), size: .init(width: 0.28, height: 0.10), titleSize: 24),
        .init(name: "saglamkart", title: "Sağlam", subtitle: "KART", color: AppColors.cyan, titleColor: .white, subtitleColor: AppColors.cyan, symbol: "s.hexagon", position: .init(x: 0.50, y: 0.27), size: .init(width: 0.28, height: 0.10), titleSize: 19),
        .init(name: "nkolay", title: "Kolay", subtitle: nil, color: AppColors.blue, titleColor: .white, subtitleColor: nil, symbol: "n.circle.fill", position: .init(x: 0.83, y: 0.34), size: .init(width: 0.27, height: 0.10), titleSize: 20),
        .init(name: "ondigital", title: "ON", subtitle: "DIGITAL", color: AppColors.green, titleColor: .white, subtitleColor: AppColors.green, symbol: "circle.fill", position: .init(x: 0.18, y: 0.50), size: .init(width: 0.28, height: 0.10), titleSize: 20),
        .init(name: "vakifworld", title: "Vakıf", subtitle: "WORLD", color: AppColors.gold, titleColor: .white, subtitleColor: AppColors.gold, symbol: "v.square.fill", position: .init(x: 0.83, y: 0.50), size: .init(width: 0.28, height: 0.10), titleSize: 20),
        .init(name: "qnb", title: "QNB", subtitle: nil, color: AppColors.pink, titleColor: .white, subtitleColor: nil, symbol: "asterisk", position: .init(x: 0.18, y: 0.67), size: .init(width: 0.29, height: 0.10), titleSize: 22),
        .init(name: "denizbank", title: "DenizBank", subtitle: nil, color: AppColors.blue, titleColor: .white, subtitleColor: nil, symbol: "helm", position: .init(x: 0.50, y: 0.72), size: .init(width: 0.28, height: 0.10), titleSize: 18),
        .init(name: "ziraat", title: "Ziraat Bankası", subtitle: nil, color: AppColors.red, titleColor: .white, subtitleColor: nil, symbol: "leaf.fill", position: .init(x: 0.82, y: 0.67), size: .init(width: 0.29, height: 0.10), titleSize: 17),
        .init(name: "yapikredi", title: "YapıKredi", subtitle: "WORLD", color: AppColors.purple, titleColor: .white, subtitleColor: AppColors.purple, symbol: "link", position: .init(x: 0.34, y: 0.88), size: .init(width: 0.30, height: 0.10), titleSize: 18),
        .init(name: "teb", title: "TEB", subtitle: nil, color: AppColors.green, titleColor: .white, subtitleColor: nil, symbol: "sparkles", position: .init(x: 0.68, y: 0.88), size: .init(width: 0.29, height: 0.10), titleSize: 22)
    ]
}

// MARK: - Colors

enum AppColors {
    static let backgroundTop = Color(hex: "07131D")
    static let backgroundMid = Color(hex: "061722")
    static let backgroundBottom = Color(hex: "01070C")
    static let mint = Color(hex: "55E6D0")
    static let mintDark = Color(hex: "1B6F68")
    static let textPrimary = Color(hex: "F5F7F8")
    static let textSecondary = Color(hex: "8E9AA3")
    static let cardFill = Color(hex: "071820").opacity(0.78)
    static let purple = Color(hex: "B64DFF")
    static let gold = Color(hex: "F5B83D")
    static let pink = Color(hex: "FF3E8A")
    static let blue = Color(hex: "178CFF")
    static let green = Color(hex: "16C784")
    static let red = Color(hex: "F32735")
    static let cyan = Color(hex: "19CDE8")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    KampanyaRadariOnboardingView()
}
