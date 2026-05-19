import SwiftUI

enum AppTheme {
    static let nearBlack = Color(hex: "#050B12")
    static let ink = Color(hex: "#07131D")
    static let panelBlack = Color(hex: "#101A24")
    static let deepBlue = Color(hex: "#132430")
    static let borderSubtle = Color.white.opacity(0.08)

    static let goldLight = Color(hex: "#F8D27A")
    static let goldDark = Color(hex: "#B97924")

    static let mint = Color(hex: "#55E0C0")
    static let dashboardGreen = Color(hex: "#55E0C0")

    static let textPrimary = Color(hex: "#F6F3EE")
    static let textSecondary = Color(hex: "#9AA6B2")
    static let muted = Color(hex: "#9AA6B2")

    static let electricBlue = Color(hex: "#132430")
    static let coral = Color(hex: "#F8D27A")
    static let aqua = Color(hex: "#55E0C0")
    static let softGreen = Color(hex: "#0B1B26")
    static let softBlue = Color(hex: "#101A24")
    static let softOrange = Color(hex: "#F8D27A").opacity(0.15)
    static let cream = Color(hex: "#F6F3EE")

    static let dashboardBackground = LinearGradient(
        colors: [Color(hex: "#050B12"), Color(hex: "#07131D"), Color(hex: "#050B12")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [goldLight, goldDark],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let premiumGlow = LinearGradient(
        colors: [goldLight.opacity(0.15), goldDark.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let blueBackground = dashboardBackground

    struct PremiumCardModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(hex: "#101A24"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
                )
        }
    }

    struct GoldButtonModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .foregroundStyle(Color(hex: "#050B12"))
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#F8D27A"), Color(hex: "#B97924")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color(hex: "#F8D27A").opacity(0.25), radius: 12, x: 0, y: 4)
                )
        }
    }
}

extension View {
    func premiumCard() -> some View { modifier(AppTheme.PremiumCardModifier()) }
    func goldButton() -> some View { modifier(AppTheme.GoldButtonModifier()) }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
