import SwiftUI

struct RadarLoadingOverlay: View {
    let title: String
    let message: String
    @State private var isScanning = false
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            VStack(spacing: 16) {
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
                        .rotationEffect(.degrees(isScanning ? 360 : 0))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isScanning)

                    Circle()
                        .fill(AppTheme.dashboardGreen.opacity(isPulsing ? 0.18 : 0.08))
                        .frame(width: isPulsing ? 54 : 42, height: isPulsing ? 54 : 42)
                        .animation(.easeInOut(duration: 0.78).repeatForever(autoreverses: true), value: isPulsing)

                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }

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
        .onAppear {
            isScanning = true
            isPulsing = true
        }
    }
}
