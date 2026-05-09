import SwiftUI

struct CampaignListView: View {
    @State private var viewModel = CampaignListViewModel()
    @State private var favorites = FavoritesStore()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.campaigns.isEmpty {
                    ProgressView("Kampanyalar yukleniyor")
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView("Baglanti hatasi", systemImage: "wifi.exclamationmark", description: Text(errorMessage))
                } else {
                    List {
                        bankFilter
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)

                        ForEach(viewModel.filteredCampaigns) { campaign in
                            NavigationLink {
                                CampaignDetailView(campaign: campaign, favorites: favorites)
                            } label: {
                                CampaignCardView(
                                    campaign: campaign,
                                    isFavorite: favorites.contains(campaign)
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("Kampanya Radar")
            .searchable(text: $viewModel.searchText, prompt: "Market, taksit, seyahat")
            .task {
                if viewModel.campaigns.isEmpty {
                    await viewModel.load()
                }
            }
        }
    }

    private var bankFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                BankChip(title: "Tumu", isSelected: viewModel.selectedBank == nil) {
                    viewModel.selectedBank = nil
                }
                ForEach(viewModel.banks, id: \.self) { bank in
                    BankChip(title: viewModel.label(for: bank), isSelected: viewModel.selectedBank == bank) {
                        viewModel.selectedBank = bank
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

private struct BankChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green.opacity(0.18) : Color.secondary.opacity(0.12))
                .foregroundStyle(isSelected ? .green : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

