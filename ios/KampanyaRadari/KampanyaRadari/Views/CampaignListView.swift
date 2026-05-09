import SwiftUI

struct CampaignListView: View {
    @State private var viewModel = CampaignListViewModel()
    @State private var favorites = FavoritesStore()
    @State private var isShowingFilters = false

    var body: some View {
        NavigationStack {
            let filteredCampaigns = viewModel.filteredCampaigns(favoriteIDs: favorites.ids)

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

                        resultSummary(count: filteredCampaigns.count)
                            .listRowSeparator(.hidden)

                        if filteredCampaigns.isEmpty {
                            ContentUnavailableView("Sonuc bulunamadi", systemImage: "line.3.horizontal.decrease.circle", description: Text("Filtreleri gevsetip tekrar dene."))
                                .listRowSeparator(.hidden)
                        }

                        ForEach(filteredCampaigns) { campaign in
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingFilters = true
                    } label: {
                        Image(systemName: viewModel.hasAdvancedFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filtreler")
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Market, taksit, seyahat")
            .sheet(isPresented: $isShowingFilters) {
                FilterSheet(viewModel: viewModel, favoriteCount: favorites.ids.count)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
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

    private func resultSummary(count: Int) -> some View {
        HStack(spacing: 10) {
            Label("\(count) sonuc", systemImage: "rectangle.stack")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if viewModel.hasAdvancedFilters {
                Button("Temizle") {
                    viewModel.clearAdvancedFilters()
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
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

private struct FilterSheet: View {
    @Bindable var viewModel: CampaignListViewModel
    let favoriteCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Siralama") {
                    Picker("Siralama", selection: $viewModel.sortOption) {
                        ForEach(CampaignSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Kategori") {
                    FilterOptionRow(title: "Tumu", isSelected: viewModel.selectedCategory == nil) {
                        viewModel.selectedCategory = nil
                    }
                    ForEach(viewModel.categories, id: \.self) { category in
                        FilterOptionRow(title: category, isSelected: viewModel.selectedCategory == category) {
                            viewModel.selectedCategory = category
                        }
                    }
                }

                Section("Kazanim") {
                    FilterOptionRow(title: "Tumu", isSelected: viewModel.selectedRewardType == nil) {
                        viewModel.selectedRewardType = nil
                    }
                    ForEach(viewModel.rewardTypes, id: \.self) { rewardType in
                        FilterOptionRow(title: rewardType, isSelected: viewModel.selectedRewardType == rewardType) {
                            viewModel.selectedRewardType = rewardType
                        }
                    }
                }

                Section("Gorunum") {
                    Toggle("Sadece favoriler", isOn: $viewModel.showFavoritesOnly)
                    LabeledContent("Favori sayisi", value: "\(favoriteCount)")
                }

                Section {
                    Button("Tum filtreleri temizle", role: .destructive) {
                        viewModel.resetFilters()
                    }
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bitti") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct FilterOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
        }
    }
}
