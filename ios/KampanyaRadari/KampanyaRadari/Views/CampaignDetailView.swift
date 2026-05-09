import SwiftUI

struct CampaignDetailView: View {
    let campaign: Campaign
    @Bindable var favorites: FavoritesStore

    var body: some View {
        ZStack {
            AppTheme.blueBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 18) {
                        AsyncImage(url: campaign.imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                placeholder
                            case .empty:
                                placeholder.overlay {
                                    ProgressView()
                                }
                            @unknown default:
                                placeholder
                            }
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 10)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(campaign.displayBank)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.electricBlue)
                            Text(campaign.title)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppTheme.ink)
                            Text(campaign.deadlineText)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.orange)
                        }

                        Text(campaign.displaySummary)
                            .font(.body)
                            .foregroundStyle(AppTheme.muted)

                        HStack {
                            Button {
                                favorites.toggle(campaign)
                            } label: {
                                Label(
                                    favorites.contains(campaign) ? "Favorilerden cikar" : "Favoriye ekle",
                                    systemImage: favorites.contains(campaign) ? "star.fill" : "star"
                                )
                                .font(.subheadline.weight(.bold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.coral)

                            if let sourceURL = campaign.sourceURL {
                                Link(destination: sourceURL) {
                                    Label("Kaynak", systemImage: "safari")
                                        .font(.subheadline.weight(.bold))
                                }
                                .buttonStyle(.bordered)
                                .tint(AppTheme.electricBlue)
                            }
                        }
                    }
                    .padding(20)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                }
                .padding(18)
            }
        }
        .navigationTitle("Detay")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppTheme.softBlue)
            .overlay {
                Image(systemName: "creditcard")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.electricBlue)
            }
    }
}
