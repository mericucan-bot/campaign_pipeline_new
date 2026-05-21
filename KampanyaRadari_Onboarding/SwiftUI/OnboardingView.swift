import SwiftUI

// MARK: - Kampanya Radarı Onboarding
// Bu dosyayı Xcode projenize ekleyin.
// Logo assetleri Assets.xcassets içine şu isimlerle koyarsanız 3. sayfa otomatik kullanır:
// axess, maximum, garanti, paraf, saglam, kolay, onDigital, vakifWorld, qnb, denizbank, ziraat, yapikrediWorld, teb

struct OnboardingView: View {
    @State private var page = 0

    var body: some View {
        ZStack {
            PremiumBackground()
                .ignoresSafeArea()

            TabView(selection: $page) {
                SectorRadarPage(page: $page).tag(0)
                SavingsPage(page: $page).tag(1)
                CardsRadarPage(page: $page).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

// MARK: - Pages

struct SectorRadarPage: View {
    @Binding var page: Int

    var body: some View {
        OnboardingScaffold(
            visual: { SectorRadarIllustration() },
            activePage: page,
            title: "En iyi fırsatları...",
            subtitle: "Binlerce kampanya içinden sana en uygun olanları radarına al.",
            buttonTitle: "İleri",
            showsArrow: true,
            buttonAction: { withAnimation(.spring()) { page = 1 } }
        )
    }
}

struct SavingsPage: View {
    @Binding var page: Int

    var body: some View {
        OnboardingScaffold(
            visual: { SavingsJarIllustration() },
            activePage: page,
            title: "Tasarruf et,...",
            subtitle: "Kaçırdığın fırsatları bul, birikimini artır, her alışverişte avantaj yakala.",
            buttonTitle: "Başlayalım",
            showsArrow: false,
            buttonAction: { withAnimation(.spring()) { page = 2 } }
        )
    }
}

struct CardsRadarPage: View {
    @Binding var page: Int

    var body: some View {
        OnboardingScaffold(
            visual: { BankCardCloudView() },
            activePage: page,
            title: "Tüm fırsatlar\ntek radarında!",
            subtitle: "Bankalardan kartlara, avantajlardan kampanyalara kadar aradığın her şey burada.",
            buttonTitle: "Keşfetmeye başla",
            showsArrow: true,
            buttonAction: {}
        )
    }
}

// MARK: - Shared Layout

struct OnboardingScaffold<Visual: View>: View {
    @ViewBuilder var visual: () -> Visual
    let activePage: Int
    let title: String
    let subtitle: String
    let buttonTitle: String
    let showsArrow: Bool
    let buttonAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 26)

            visual()
                .frame(height: 500)
                .padding(.horizontal, 18)

            Spacer(minLength: 6)

            VStack(alignment: .leading, spacing: 22) {
                RadarBadge()

                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineSpacing(5)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 8)

                Text(subtitle)
                    .font(.system(size: 19, weight: .regular, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(4)

                HStack(alignment: .center) {
                    PaginationDots(active: activePage, count: 3)
                    Spacer()
                    PrimaryButton(title: buttonTitle, showsArrow: showsArrow, action: buttonAction)
                }
                .padding(.top, 18)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 42)
        }
    }
}

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColors.backgroundTop, AppColors.backgroundMid, AppColors.backgroundBottom], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [AppColors.mint.opacity(0.18), .clear], center: .center, startRadius: 20, endRadius: 390)
                .blur(radius: 26)
                .offset(y: -40)
        }
    }
}

// MARK: - Page 1: Sector Radar

struct SectorRadarIllustration: View {
    private let sectors = [
        SectorItem(title: "Market", icon: "cart.fill", x: -118, y: -112),
        SectorItem(title: "Yakıt", icon: "fuelpump.fill", x: 118, y: -104),
        SectorItem(title: "Alışveriş", icon: "bag.fill", x: -120, y: 116),
        SectorItem(title: "Seyahat", icon: "airplane", x: 118, y: 108)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadarCore(size: min(geo.size.width * 0.9, 360), strong: true)
                    .offset(y: 16)

                ForEach(sectors) { sector in
                    SectorPillView(item: sector)
                        .offset(x: sector.x, y: sector.y + 18)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct SectorItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let x: CGFloat
    let y: CGFloat
}

struct SectorPillView: View {
    let item: SectorItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.mint)

            Text(item.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 20)
        .frame(height: 62)
        .background(.ultraThinMaterial.opacity(0.45), in: Capsule())
        .background(AppColors.cardFill, in: Capsule())
        .overlay(Capsule().stroke(AppColors.cardStroke, lineWidth: 1.2))
        .shadow(color: AppColors.mint.opacity(0.18), radius: 18)
    }
}

// MARK: - Page 2: Savings

struct SavingsJarIllustration: View {
    var body: some View {
        ZStack {
            RadialGradient(colors: [AppColors.mint.opacity(0.36), .clear], center: .center, startRadius: 20, endRadius: 220)
                .blur(radius: 26)

            Circle()
                .stroke(AppColors.mint.opacity(0.28), lineWidth: 1.3)
                .frame(width: 310, height: 310)

            orbitIcon("chart.bar.fill", x: -132, y: -118)
            orbitIcon("wallet.pass.fill", x: 0, y: -160)
            orbitIcon("piggy.bank.fill", x: 136, y: -116)
            orbitIcon("percent", x: -138, y: 72)
            orbitIcon("bell.fill", x: 138, y: 72)

            ZStack {
                RoundedRectangle(cornerRadius: 34)
                    .fill(LinearGradient(colors: [AppColors.mint.opacity(0.22), AppColors.mintDark.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 170, height: 205)
                    .overlay(RoundedRectangle(cornerRadius: 34).stroke(AppColors.mint.opacity(0.65), lineWidth: 1.6))
                    .offset(y: 28)

                Capsule()
                    .fill(LinearGradient(colors: [AppColors.mint.opacity(0.75), AppColors.mintDark.opacity(0.45)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 176, height: 32)
                    .offset(y: -84)

                VStack(spacing: -2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Capsule()
                            .fill(AppColors.mint.opacity(0.35))
                            .frame(width: 70, height: 16)
                            .overlay(Capsule().stroke(AppColors.mint.opacity(0.5), lineWidth: 1))
                    }
                }
                .offset(x: 34, y: 20)

                Circle()
                    .fill(LinearGradient(colors: [AppColors.mint.opacity(0.92), AppColors.mintDark.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 86, height: 86)
                    .overlay(Circle().stroke(AppColors.mint.opacity(0.8), lineWidth: 3))
                    .overlay(Text("₺").font(.system(size: 46, weight: .bold, design: .rounded)).foregroundStyle(AppColors.mintDark.opacity(0.95)))
                    .offset(x: -34, y: 66)
            }
            .shadow(color: AppColors.mint.opacity(0.35), radius: 28)
        }
    }

    private func orbitIcon(_ name: String, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(AppColors.cardFill)
            .frame(width: 76, height: 76)
            .overlay(Circle().stroke(AppColors.mint.opacity(0.65), lineWidth: 1.4))
            .overlay(Image(systemName: name).font(.system(size: 27, weight: .medium)).foregroundStyle(AppColors.mint))
            .offset(x: x, y: y)
            .shadow(color: AppColors.mint.opacity(0.20), radius: 18)
    }
}

// MARK: - Page 3: Cards Radar

struct BankCardCloudView: View {
    private let cards: [BankCardItem] = [
        .init(asset: "axess", fallback: "axess", color: AppColors.gold, x: 0, y: -194, w: 128),
        .init(asset: "maximum", fallback: "maximum", color: AppColors.pink, x: -118, y: -146, w: 126),
        .init(asset: "garanti", fallback: "Garanti\nBBVA", color: AppColors.green, x: 120, y: -146, w: 134),
        .init(asset: "saglam", fallback: "Sağlam\nKART", color: AppColors.mint, x: 0, y: -86, w: 126),
        .init(asset: "paraf", fallback: "Paraf.", color: AppColors.cyan, x: -132, y: -50, w: 122),
        .init(asset: "kolay", fallback: "N Kolay", color: AppColors.blue, x: 132, y: -50, w: 122),
        .init(asset: "onDigital", fallback: "ON\nDIGITAL", color: AppColors.green, x: -132, y: 44, w: 122),
        .init(asset: "vakifWorld", fallback: "Vakıf\nWORLD", color: AppColors.gold, x: 132, y: 44, w: 124),
        .init(asset: "qnb", fallback: "QNB", color: AppColors.pink, x: -132, y: 136, w: 124),
        .init(asset: "ziraat", fallback: "Ziraat Bankası", color: AppColors.red, x: 132, y: 136, w: 132),
        .init(asset: "denizbank", fallback: "DenizBank", color: AppColors.blue, x: 0, y: 178, w: 128),
        .init(asset: "yapikrediWorld", fallback: "YapıKredi\nWORLD", color: AppColors.purple, x: -76, y: 252, w: 132),
        .init(asset: "teb", fallback: "TEB", color: AppColors.green, x: 92, y: 252, w: 126)
    ]

    var body: some View {
        ZStack {
            RadarCore(size: 210, strong: false)
                .offset(y: 34)

            ForEach(cards) { card in
                BankLogoCard(item: card)
                    .offset(x: card.x, y: card.y)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BankCardItem: Identifiable {
    let id = UUID()
    let asset: String
    let fallback: String
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
}

struct BankLogoCard: View {
    let item: BankCardItem

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardFill)
                .frame(width: item.w, height: 58)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(item.color.opacity(0.75), lineWidth: 1))
                .shadow(color: item.color.opacity(0.22), radius: 14)

            Image(item.asset)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(width: item.w, height: 58)

            // Asset yoksa geçici text görünsün diye opacity fallback hilesi.
            Text(item.fallback)
                .font(.system(size: item.fallback.count > 10 ? 15 : 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(item.asset == "yapikrediWorld" ? AppColors.purple : AppColors.textPrimary)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 10)
                .opacity(0) // Asset yoksa bu satırı 1 yapabilirsiniz.
        }
    }
}

// MARK: - Shared Visual Components

struct RadarCore: View {
    let size: CGFloat
    let strong: Bool

    var body: some View {
        ZStack {
            ForEach(1...4, id: \.self) { index in
                Circle()
                    .stroke(AppColors.mint.opacity(strong ? 0.22 : 0.14), lineWidth: 1)
                    .frame(width: size * CGFloat(index) / 4, height: size * CGFloat(index) / 4)
            }

            Rectangle().fill(AppColors.mint.opacity(0.18)).frame(width: size, height: 1)
            Rectangle().fill(AppColors.mint.opacity(0.18)).frame(width: 1, height: size)

            Path { path in
                path.move(to: CGPoint(x: size / 2, y: size / 2))
                path.addLine(to: CGPoint(x: size * 0.88, y: size * 0.33))
            }
            .stroke(AppColors.mint, style: StrokeStyle(lineWidth: strong ? 2.5 : 1.8, lineCap: .round))
            .frame(width: size, height: size)
            .shadow(color: AppColors.mint.opacity(0.65), radius: 8)

            Circle()
                .fill(AppColors.mint)
                .frame(width: strong ? 14 : 10, height: strong ? 14 : 10)
                .shadow(color: AppColors.mint, radius: 12)

            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(AppColors.mint)
                    .frame(width: strong ? 6 : 5, height: strong ? 6 : 5)
                    .offset(x: [70, -54, 45, -22][i] * size / 300, y: [-18, 48, 70, -80][i] * size / 300)
                    .shadow(color: AppColors.mint, radius: 8)
            }
        }
        .frame(width: size, height: size)
    }
}

struct RadarBadge: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "scope")
                .font(.system(size: 22, weight: .bold))
            VStack(alignment: .leading, spacing: 0) {
                Text("Kampanya")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.85))
                Text("R A D A R I")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.mint)
            }
        }
        .foregroundStyle(AppColors.mint)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(AppColors.cardFill, in: Capsule())
        .overlay(Capsule().stroke(AppColors.cardStroke, lineWidth: 1.1))
    }
}

struct PaginationDots: View {
    let active: Int
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == active ? AppColors.mint : Color.white.opacity(0.22))
                    .frame(width: index == active ? 26 : 9, height: 9)
            }
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let showsArrow: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                if showsArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 19, weight: .bold))
                }
            }
            .foregroundStyle(Color.black.opacity(0.88))
            .padding(.horizontal, 28)
            .frame(height: 62)
            .background(
                LinearGradient(colors: [AppColors.mint, Color(hex: "4ADDC5")], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Capsule()
            )
            .shadow(color: AppColors.mint.opacity(0.38), radius: 24, y: 10)
        }
    }
}

// MARK: - Colors

enum AppColors {
    static let backgroundTop = Color(hex: "020B12")
    static let backgroundMid = Color(hex: "061722")
    static let backgroundBottom = Color(hex: "02070C")
    static let mint = Color(hex: "55E6D0")
    static let mintDark = Color(hex: "1B6F68")
    static let textPrimary = Color(hex: "F5F7F8")
    static let textSecondary = Color(hex: "8E9AA3")
    static let cardFill = Color(hex: "071820").opacity(0.78)
    static let cardStroke = Color(hex: "55E6D0").opacity(0.45)
    static let purple = Color(hex: "B64DFF")
    static let gold = Color(hex: "F5B83D")
    static let pink = Color(hex: "FF3E8A")
    static let blue = Color(hex: "178CFF")
    static let cyan = Color(hex: "00C9F5")
    static let green = Color(hex: "16C784")
    static let red = Color(hex: "F32735")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 255, (int >> 8) & 255, int & 255)
        default:
            (r, g, b) = (255, 255, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

#Preview {
    OnboardingView()
}
