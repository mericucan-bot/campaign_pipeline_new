import SwiftUI

struct CampaignDetailView: View {
    let campaign: Campaign
    @Bindable var favorites: FavoritesStore

    var body: some View {
        ScrollView {
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
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text(campaign.displayBank)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                    Text(campaign.title)
                        .font(.title2.weight(.bold))
                    Text(campaign.deadlineText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                }

                Text(campaign.displaySummary)
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack {
                    Button {
                        favorites.toggle(campaign)
                    } label: {
                        Label(
                            favorites.contains(campaign) ? "Favorilerden cikar" : "Favoriye ekle",
                            systemImage: favorites.contains(campaign) ? "star.fill" : "star"
                        )
                    }
                    .buttonStyle(.borderedProminent)

                    if let sourceURL = campaign.sourceURL {
                        Link(destination: sourceURL) {
                            Label("Kaynak", systemImage: "safari")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Detay")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.secondary.opacity(0.15))
            .overlay {
                Image(systemName: "creditcard")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
}
