import SwiftUI

private enum AppRoute: Hashable {
    case list
}

struct CampaignListView: View {
    @State private var viewModel = CampaignListViewModel()
    @State private var favorites = FavoritesStore()
    @State private var hasEnteredApp = false
    @State private var path: [AppRoute] = []

    var body: some View {
        Group {
            if hasEnteredApp {
                NavigationStack(path: $path) {
                    DashboardHomeView(viewModel: viewModel, favorites: favorites) {
                        viewModel.showAllCampaigns()
                        path.append(.list)
                    } openCategory: { category in
                        viewModel.showCampaigns(category: category)
                        path.append(.list)
                    }
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .list:
                            CampaignListScreen(viewModel: viewModel, favorites: favorites)
                        }
                    }
                }
            } else {
                IntroView {
                    hasEnteredApp = true
                }
            }
        }
        .task {
            if viewModel.campaigns.isEmpty {
                await viewModel.load()
            }
        }
    }
}

private struct IntroView: View {
    let enter: () -> Void

    var body: some View {
        ZStack {
            AppTheme.blueBackground
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("Kampanya Radarı")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Kart fırsatlarını tek ekranda keşfet")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)

                Button(action: enter) {
                    Text("Kampanyaları Gör")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 260)
                        .padding(.vertical, 18)
                        .background(AppTheme.coral)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 18, x: 0, y: 10)
                }
                .padding(.top, 10)

                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 300, height: 300)
                    Circle()
                        .fill(AppTheme.mint.opacity(0.72))
                        .frame(width: 238, height: 238)
                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 82, weight: .bold))
                        .foregroundStyle(.white)
                    Image(systemName: "sparkles")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                        .offset(x: 112, y: -112)
                    Image(systemName: "star.fill")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.9))
                        .offset(x: -126, y: -80)
                }
                .padding(.bottom, 22)
            }
            .padding(24)
        }
    }
}

private struct DashboardHomeView: View {
    @Bindable var viewModel: CampaignListViewModel
    let favorites: FavoritesStore
    let openAllCampaigns: () -> Void
    let openCategory: (String) -> Void

    var body: some View {
        ZStack {
            AppTheme.blueBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    insightCard
                    categoryGrid
                    calculatorPreview
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Kampanya Radarı")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                CircleIconButton(systemName: "arrow.clockwise") {
                    Task { await viewModel.load() }
                }
            }

            Text("Bugünün kart fırsatlarını kategoriye, bankaya ve kazanca göre keşfet.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))

            Button(action: openAllCampaigns) {
                Label("Tüm Kampanyalar", systemImage: "rectangle.stack.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.coral)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.top, 6)
        }
    }

    private var insightCard: some View {
        HStack(spacing: 18) {
            CategoryDonutChart(summaries: viewModel.topCategorySummaries, total: viewModel.campaigns.count)
                .frame(width: 128, height: 128)

            VStack(alignment: .leading, spacing: 12) {
                Text("Kampanya özeti")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                StatLine(title: "Toplam kampanya", value: "\(viewModel.campaigns.count)")
                StatLine(title: "Banka/kart", value: "\(viewModel.bankCount)")
                StatLine(title: "Favori", value: "\(favorites.ids.count)")
            }
            Spacer()
        }
        .padding(18)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kategoriler")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(viewModel.topCategorySummaries) { summary in
                    CategoryTile(summary: summary) {
                        openCategory(summary.name)
                    }
                }
            }
        }
    }

    private var calculatorPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Favori ve hesaplayıcı")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(AppTheme.electricBlue)
            }

            HStack(spacing: 12) {
                LightStatTile(title: "Katılım", value: "0")
                LightStatTile(title: "Harcama", value: "0 TL")
                LightStatTile(title: "Kazanç", value: "0 TL")
            }

            Text("Bir sonraki adımda dashboard’daki hesaplayıcıyı buraya taşıyacağız.")
                .font(.footnote)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct CampaignListScreen: View {
    @Bindable var viewModel: CampaignListViewModel
    let favorites: FavoritesStore
    @State private var isShowingFilters = false
    @State private var showScrollToTop = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let filteredCampaigns = viewModel.filteredCampaigns(favoriteIDs: favorites.ids)

        ZStack(alignment: .bottomTrailing) {
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
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 18) {
                            Color.clear
                                .frame(height: 0)
                                .id("top")
                                .background(
                                    GeometryReader { geometry in
                                        Color.clear.preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: geometry.frame(in: .named("campaignListScroll")).minY
                                        )
                                    }
                                )

                            listHeader(count: filteredCampaigns.count)
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
                    .coordinateSpace(name: "campaignListScroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            showScrollToTop = offset < -520
                        }
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if showScrollToTop {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    proxy.scrollTo("top", anchor: .top)
                                }
                            } label: {
                                Image(systemName: "arrow.up")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 52, height: 52)
                                    .background(AppTheme.coral)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.24), radius: 16, x: 0, y: 10)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingFilters) {
            FilterSheet(viewModel: viewModel, favoriteCount: favorites.ids.count)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func listHeader(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                CircleIconButton(systemName: "chevron.left") {
                    dismiss()
                }
                Spacer()
                CircleIconButton(systemName: viewModel.hasAdvancedFilters ? "slider.horizontal.3" : "line.3.horizontal.decrease") {
                    isShowingFilters = true
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tüm Kampanyalar")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(count) sonuç listeleniyor")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))
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
                .foregroundStyle(.white)
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

private struct CategoryDonutChart: View {
    let summaries: [CategorySummary]
    let total: Int
    private let colors: [Color] = [AppTheme.mint, AppTheme.coral, .yellow, AppTheme.aqua]

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.22), lineWidth: 18)

            ForEach(Array(summaries.enumerated()), id: \.element.id) { index, summary in
                Circle()
                    .trim(from: start(for: index), to: end(for: index))
                    .stroke(colors[index % colors.count], style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("\(total)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("kampanya")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.76))
            }
        }
    }

    private func start(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        let previous = summaries.prefix(index).reduce(0) { $0 + $1.count }
        return Double(previous) / Double(total)
    }

    private func end(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        let current = summaries.prefix(index + 1).reduce(0) { $0 + $1.count }
        return Double(current) / Double(total)
    }
}

private struct CategoryTile: View {
    let summary: CategorySummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.coral.opacity(0.14))
                        .frame(width: 46, height: 46)
                    Image(systemName: iconName)
                        .foregroundStyle(AppTheme.coral)
                        .font(.title3.weight(.bold))
                }

                Text(summary.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)

                Text("\(summary.count) kampanya")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .frame(minHeight: 156)
            .background(tileColor)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var tileColor: Color {
        switch summary.name.lowercased() {
        case let name where name.contains("market"):
            return Color(red: 1.0, green: 0.94, blue: 0.94)
        case let name where name.contains("akaryakit") || name.contains("yakıt") || name.contains("yakit"):
            return AppTheme.cream
        case let name where name.contains("seyahat"):
            return Color(red: 0.92, green: 0.98, blue: 0.90)
        case let name where name.contains("online"):
            return Color(red: 0.92, green: 0.94, blue: 1.0)
        default:
            return .white.opacity(0.92)
        }
    }

    private var iconName: String {
        switch summary.name.lowercased() {
        case let name where name.contains("market"):
            return "cart.fill"
        case let name where name.contains("akaryakit") || name.contains("yakıt") || name.contains("yakit"):
            return "fuelpump.fill"
        case let name where name.contains("seyahat"):
            return "airplane"
        case let name where name.contains("online"):
            return "network"
        default:
            return "tag.fill"
        }
    }
}

private struct StatLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

private struct LightStatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.softBlue.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
