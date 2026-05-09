import SwiftUI

struct CampaignListView: View {
    @State private var viewModel = CampaignListViewModel()
    @State private var favorites = FavoritesStore()
    @State private var isShowingFilters = false

    var body: some View {
        NavigationStack {
            let filteredCampaigns = viewModel.filteredCampaigns(favoriteIDs: favorites.ids)

            ZStack {
                AppTheme.blueBackground
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.campaigns.isEmpty {
                    ProgressView("Kampanyalar yukleniyor")
                        .tint(.white)
                        .foregroundStyle(.white)
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView("Baglanti hatasi", systemImage: "wifi.exclamationmark", description: Text(errorMessage))
                        .foregroundStyle(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            dashboardHeader(total: viewModel.campaigns.count, count: filteredCampaigns.count)
                            bankFilter

                            VStack(spacing: 16) {
                                resultSummary(count: filteredCampaigns.count)

                                if filteredCampaigns.isEmpty {
                                    ContentUnavailableView("Sonuc bulunamadi", systemImage: "line.3.horizontal.decrease.circle", description: Text("Filtreleri gevsetip tekrar dene."))
                                        .padding(.vertical, 40)
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
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity)
                            .background(.white)
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34))
                        }
                        .padding(.top, 8)
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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

    private func dashboardHeader(total: Int, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                CircleIconButton(systemName: "line.3.horizontal") {
                    isShowingFilters = true
                }
                Spacer()
                CircleIconButton(systemName: viewModel.hasAdvancedFilters ? "slider.horizontal.3" : "line.3.horizontal.decrease") {
                    isShowingFilters = true
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Kampanya Radarı")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Kart fırsatlarını tek ekranda keşfet")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))
            }

            HStack(spacing: 12) {
                StatTile(title: "Aktif", value: "\(total)")
                StatTile(title: "Sonuc", value: "\(count)")
                StatTile(title: "Favori", value: "\(favorites.ids.count)")
            }

            searchField
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
            TextField("Market, taksit, seyahat", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
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
        }
    }

    private func resultSummary(count: Int) -> some View {
        HStack(spacing: 10) {
            Label("\(count) sonuc", systemImage: "rectangle.stack")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(isSelected ? AppTheme.coral : .white.opacity(0.18))
                .foregroundStyle(isSelected ? .white : .white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 46, height: 46)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 8)
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
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
