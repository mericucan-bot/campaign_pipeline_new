import SwiftUI

enum AppTheme {
    static let electricBlue = Color(red: 0.02, green: 0.08, blue: 0.96)
    static let deepBlue = Color(red: 0.03, green: 0.05, blue: 0.72)
    static let nearBlack = Color(red: 0.04, green: 0.06, blue: 0.06)
    static let panelBlack = Color(red: 0.08, green: 0.10, blue: 0.10)
    static let ink = Color(red: 0.05, green: 0.12, blue: 0.13)
    static let muted = Color(red: 0.46, green: 0.49, blue: 0.53)
    static let coral = Color(red: 0.95, green: 0.32, blue: 0.24)
    static let mint = Color(red: 0.38, green: 0.80, blue: 0.67)
    static let dashboardGreen = Color(red: 0.38, green: 0.80, blue: 0.67)
    static let softGreen = Color(red: 0.82, green: 0.97, blue: 0.91)
    static let aqua = Color(red: 0.44, green: 0.90, blue: 0.92)
    static let softBlue = Color(red: 0.86, green: 0.93, blue: 1.0)
    static let softOrange = Color(red: 1.0, green: 0.89, blue: 0.79)
    static let cream = Color(red: 1.0, green: 0.97, blue: 0.88)

    static let dashboardBackground = LinearGradient(
        colors: [nearBlack, Color(red: 0.06, green: 0.16, blue: 0.15), nearBlack],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let blueBackground = dashboardBackground
}
