import SwiftUI

struct RadarLoadingOverlay: View {
    let title: String
    let message: String
    private let startedAt = Date()

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(startedAt)
                    let rotation = elapsed.truncatingRemainder(dividingBy: 1.0) * 360
                    let pulse = 0.5 + 0.5 * sin(elapsed * 2.0 * .pi / 0.9)

                    ZStack {
                        Circle()
                            .stroke(AppTheme.dashboardGreen.opacity(0.18), lineWidth: 14)
                            .frame(width: 116, height: 116)

                        Circle()
                            .trim(from: 0.05, to: 0.72)
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.dashboardGreen.opacity(0.16), AppTheme.dashboardGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 116, height: 116)
                            .rotationEffect(.degrees(rotation))

                        Circle()
                            .fill(AppTheme.dashboardGreen.opacity(0.08 + (0.10 * pulse)))
                            .frame(width: 42 + (12 * pulse), height: 42 + (12 * pulse))

                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 116, height: 116)

                VStack(spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(maxWidth: 300)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(AppTheme.dashboardGreen.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 16)
        }
    }
}
