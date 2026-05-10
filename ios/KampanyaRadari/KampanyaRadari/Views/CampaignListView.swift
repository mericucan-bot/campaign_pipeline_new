import SwiftUI

private enum AppRoute: Hashable {
    case list(lockCategoryFilter: Bool)
    case profile
    case earnings
    case account
}

struct CampaignListView: View {
    @State private var viewModel = CampaignListViewModel()
    @State private var favorites = FavoritesStore()
    @State private var myCards = MyCardsStore()
    @State private var participation = ParticipationStore()
    @State private var authState = AuthStateStore()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var hasEnteredApp = false
    @State private var path: [AppRoute] = []

    var body: some View {
        Group {
            if hasCompletedOnboarding || hasEnteredApp {
                NavigationStack(path: $path) {
                    DashboardHomeView(viewModel: viewModel, favorites: favorites, myCards: myCards, participation: participation, authState: authState) {
                        viewModel.showAllCampaigns()
                        path.append(.list(lockCategoryFilter: false))
                    } openFavorites: {
                        viewModel.showFavoriteCampaigns()
                        path.append(.list(lockCategoryFilter: false))
                    } openMyCards: {
                        path.append(.profile)
                    } openMyCardCampaigns: {
                        viewModel.showMyCardCampaigns()
                        path.append(.list(lockCategoryFilter: false))
                    } openEarnings: {
                        path.append(.earnings)
                    } openAccount: {
                        path.append(.account)
                    } openCategory: { category in
                        viewModel.showCampaigns(category: category)
                        path.append(.list(lockCategoryFilter: true))
                    }
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .list(let lockCategoryFilter):
                            CampaignListScreen(
                                viewModel: viewModel,
                                favorites: favorites,
                                myCards: myCards,
                                participation: participation,
                                authState: authState,
                                lockCategoryFilter: lockCategoryFilter
                            )
                        case .profile:
                            ProfileCardsView(viewModel: viewModel, myCards: myCards)
                        case .earnings:
                            EarningsView(viewModel: viewModel, participation: participation)
                        case .account:
                            AccountView(authState: authState, favorites: favorites, myCards: myCards, participation: participation)
                        }
                    }
                }
            } else {
                IntroView(authState: authState, favorites: favorites, myCards: myCards, participation: participation) {
                    hasCompletedOnboarding = true
                    hasEnteredApp = true
                }
            }
        }
        .task {
            if viewModel.campaigns.isEmpty {
                await viewModel.load()
            }
        }
        .onOpenURL { url in
            hasCompletedOnboarding = true
            hasEnteredApp = true
            authState.handlePasswordResetURL(url)
        }
        .sheet(isPresented: Binding(
            get: { authState.passwordResetAccessToken != nil },
            set: { if !$0 { authState.clearPasswordResetToken() } }
        )) {
            if let token = authState.passwordResetAccessToken {
                PasswordResetSheet(authState: authState, accessToken: token) {
                    authState.clearPasswordResetToken()
                }
            }
        }
    }
}

private struct IntroView: View {
    @Bindable var authState: AuthStateStore
    let favorites: FavoritesStore
    let myCards: MyCardsStore
    let participation: ParticipationStore
    let enter: () -> Void
    @State private var isShowingAuthOptions = false
    @State private var onboardingPage = 0

    private let steps = [
        OnboardingStep(
            icon: "magnifyingglass",
            title: "Tüm kart fırsatlarını tek yerde keşfet",
            text: "Bankalara tek tek bakmadan kampanyaları ara, filtrele ve karşılaştır."
        ),
        OnboardingStep(
            icon: "creditcard.and.123",
            title: "Kartlarına göre kişiselleştir",
            text: "Kartlarım filtresiyle sadece sende olan banka ve kartlara uygun fırsatlara odaklan."
        ),
        OnboardingStep(
            icon: "bell.badge.fill",
            title: "Puanlarını kaçırma",
            text: "Katıldığın kampanyalar için kazanç ve son kullanım hatırlatıcısı kur."
        )
    ]

    var body: some View {
        ZStack {
            AppTheme.blueBackground
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Text("Kampanya Radarı")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 20)

                TabView(selection: $onboardingPage) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        OnboardingStepView(step: step)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 315)

                VStack(spacing: 12) {
                    Button {
                        authState.continueAsGuest()
                        enter()
                    } label: {
                        Text("Misafir Olarak Devam Et")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.nearBlack)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 18)
                            .background(AppTheme.dashboardGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: .black.opacity(0.2), radius: 18, x: 0, y: 10)
                    }

                    Button {
                        isShowingAuthOptions = true
                    } label: {
                        Text("Giriş Seçenekleri")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: 280)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(.white.opacity(0.16), lineWidth: 1)
                            }
                    }
                }
                .padding(.top, 2)

                Image("NewRadar")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260)
                    .shadow(color: AppTheme.dashboardGreen.opacity(0.26), radius: 28, x: 0, y: 12)
                    .padding(.bottom, 8)
            }
            .padding(24)
        }
        .sheet(isPresented: Binding(
            get: { isShowingAuthOptions || authState.passwordResetAccessToken != nil },
            set: {
                if !$0 {
                    isShowingAuthOptions = false
                    authState.clearPasswordResetToken()
                }
            }
        )) {
            AuthOptionsSheet(authState: authState, favorites: favorites, myCards: myCards, participation: participation, enter: enter)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct OnboardingStep: Hashable {
    let icon: String
    let title: String
    let text: String
}

private struct OnboardingStepView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: step.icon)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(AppTheme.dashboardGreen)
                .frame(width: 78, height: 78)
                .background(AppTheme.dashboardGreen.opacity(0.14))
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(AppTheme.dashboardGreen.opacity(0.22), lineWidth: 1)
                }

            Text(step.title)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.78)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Text(step.text)
                .font(.headline.weight(.semibold))
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 14)
        }
        .padding(.horizontal, 4)
    }
}

private struct DashboardHomeView: View {
    @Bindable var viewModel: CampaignListViewModel
    let favorites: FavoritesStore
    let myCards: MyCardsStore
    let participation: ParticipationStore
    let authState: AuthStateStore
    let openAllCampaigns: () -> Void
    let openFavorites: () -> Void
    let openMyCards: () -> Void
    let openMyCardCampaigns: () -> Void
    let openEarnings: () -> Void
    let openAccount: () -> Void
    let openCategory: (String) -> Void

    var body: some View {
        ZStack {
            AppTheme.blueBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    insightCard
                    favoriteShortcut
                    myCardsShortcut
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kampanya Radarı")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Text(authState.statusText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.dashboardGreen)
                }
                Spacer()
                CircleIconButton(systemName: authState.isGuest ? "person.crop.circle.badge.questionmark" : "person.crop.circle.fill") {
                    openAccount()
                }
                CircleIconButton(systemName: "creditcard") {
                    openMyCards()
                }
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
                    .background(AppTheme.dashboardGreen)
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
                StatLine(title: "Kartlarım", value: "\(myCards.banks.count)")
                StatLine(title: "Favori", value: "\(favorites.ids.count)")
            }
            Spacer()
        }
        .padding(18)
        .background(AppTheme.dashboardGreen.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private var favoriteShortcut: some View {
        Button(action: openFavorites) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.dashboardGreen.opacity(0.18))
                        .frame(width: 54, height: 54)
                    Image(systemName: "bookmark.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.dashboardGreen)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Favorilerim")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(favorites.ids.isEmpty ? "Kaydettiğin kampanyalar burada görünecek" : "\(favorites.ids.count) kayıtlı kampanya")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.dashboardGreen)
            }
            .padding(18)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.dashboardGreen.opacity(0.34), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var myCardsShortcut: some View {
        HStack(spacing: 12) {
            Button(action: openMyCards) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Kartlarım", systemImage: "creditcard.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(myCards.banks.isEmpty ? "Kartlarını seç" : "\(myCards.banks.count) banka seçili")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.66))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            Button(action: openMyCardCampaigns) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Bana uygun", systemImage: "line.3.horizontal.decrease.circle.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.nearBlack)
                    Text("Kartlarıma göre filtrele")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.nearBlack.opacity(0.66))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppTheme.dashboardGreen)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(myCards.banks.isEmpty)
            .opacity(myCards.banks.isEmpty ? 0.58 : 1)
        }
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kategoriler")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(viewModel.topCategorySummaries) { summary in
                    CategoryTile(summary: summary, iconName: viewModel.iconName(for: summary.name)) {
                        openCategory(summary.name)
                    }
                }
            }
        }
    }

    private var calculatorPreview: some View {
        Button(action: openEarnings) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Kazançlarım")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(AppTheme.dashboardGreen)
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.muted)
                }

                HStack(spacing: 12) {
                    LightStatTile(title: "Katılım", value: "\(participation.joinedCount)")
                    LightStatTile(title: "Harcama", value: participation.totalSpent.currencyText)
                    LightStatTile(title: "Kazanç", value: participation.totalEarned.currencyText)
                }

                Text("Kampanya detaylarında katılım ve kazanç bilgilerini işaretleyebilirsin.")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(18)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CampaignListScreen: View {
    @Bindable var viewModel: CampaignListViewModel
    let favorites: FavoritesStore
    let myCards: MyCardsStore
    let participation: ParticipationStore
    @Bindable var authState: AuthStateStore
    let lockCategoryFilter: Bool
    @State private var isShowingFilters = false
    @State private var isShowingBankFilters = false
    @State private var isShowingSortOptions = false
    @State private var showScrollToTop = false
    @State private var scrollOffset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let filteredCampaigns = viewModel.filteredCampaigns(favoriteIDs: favorites.ids, myCardBanks: myCards.banks)

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
                            favoriteQuickToggle
                            bankFilter

                            LazyVStack(spacing: 16) {
                                resultSummary(count: filteredCampaigns.count)

                                if filteredCampaigns.isEmpty {
                                    ContentUnavailableView("Sonuc bulunamadi", systemImage: "line.3.horizontal.decrease.circle", description: Text("Filtreleri gevsetip tekrar dene."))
                                        .padding(.vertical, 40)
                                }

                                ForEach(filteredCampaigns) { campaign in
                                    NavigationLink {
                                        CampaignDetailView(campaign: campaign, favorites: favorites, participation: participation, authState: authState)
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
                            .background(
                                LinearGradient(
                                    colors: [
                                        AppTheme.nearBlack.opacity(0.94),
                                        Color(red: 0.02, green: 0.10, blue: 0.10).opacity(0.92)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34))
                        }
                        .padding(.top, 8)
                    }
                    .coordinateSpace(name: "campaignListScroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        scrollOffset = offset
                        let shouldShow = offset < -320
                        if showScrollToTop != shouldShow {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                showScrollToTop = shouldShow
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.load()
                    }
                    .safeAreaInset(edge: .bottom) {
                        HStack {
                            Spacer()
                            if showScrollToTop {
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        proxy.scrollTo("top", anchor: .top)
                                    }
                                } label: {
                                    Label("Yukarı", systemImage: "arrow.up")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(AppTheme.nearBlack)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 14)
                                        .background(AppTheme.dashboardGreen)
                                        .clipShape(Capsule())
                                        .shadow(color: .black.opacity(0.24), radius: 16, x: 0, y: 10)
                                }
                                .padding(.trailing, 18)
                                .padding(.bottom, 10)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingFilters) {
            FilterSheet(
                viewModel: viewModel,
                favoriteCount: favorites.ids.count,
                myCardCount: myCards.banks.count,
                showsCategoryFilter: !lockCategoryFilter
            )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingBankFilters) {
            BankFilterSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingSortOptions) {
            SortSheet(viewModel: viewModel)
                .presentationDetents([.medium])
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
                CircleIconButton(systemName: viewModel.hasContentFilters ? "slider.horizontal.3" : "line.3.horizontal.decrease") {
                    isShowingFilters = true
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(listTitle)
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

    private var listTitle: String {
        if viewModel.showFavoritesOnly { return "Favorilerim" }
        if viewModel.showMyCardsOnly { return "Kartlarıma Uygun" }
        return "Tüm Kampanyalar"
    }

    private var favoriteQuickToggle: some View {
        Button {
            viewModel.showFavoritesOnly.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: viewModel.showFavoritesOnly ? "bookmark.fill" : "bookmark")
                    .font(.headline.weight(.bold))
                Text(viewModel.showFavoritesOnly ? "Favoriler gösteriliyor" : "Favorilerim")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("\(favorites.ids.count)")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(.white.opacity(viewModel.showFavoritesOnly ? 0.24 : 0.12))
                    .clipShape(Capsule())
            }
            .foregroundStyle(viewModel.showFavoritesOnly ? AppTheme.nearBlack : .white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(viewModel.showFavoritesOnly ? AppTheme.dashboardGreen : .white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.dashboardGreen.opacity(viewModel.showFavoritesOnly ? 0 : 0.32), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 22)
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
                Button {
                    isShowingBankFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(viewModel.selectedBanks.isEmpty ? .white.opacity(0.18) : AppTheme.dashboardGreen.opacity(0.88))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    isShowingSortOptions = true
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(viewModel.sortOption == .expiringSoon ? .white : AppTheme.nearBlack)
                        .frame(width: 38, height: 38)
                        .background(viewModel.sortOption == .expiringSoon ? .white.opacity(0.18) : AppTheme.dashboardGreen.opacity(0.88))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                BankChip(title: "Tümü", isSelected: viewModel.selectedBanks.isEmpty) {
                    viewModel.clearBanks()
                }
                ForEach(viewModel.banks, id: \.self) { bank in
                    BankChip(title: viewModel.label(for: bank), isSelected: viewModel.selectedBanks.contains(bank)) {
                        viewModel.toggleBank(bank)
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
                .foregroundStyle(.white.opacity(0.72))
            Spacer()
            if viewModel.hasAdvancedFilters {
                Button("Temizle") {
                    viewModel.clearAdvancedFilters()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.dashboardGreen)
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
                .background(isSelected ? AppTheme.dashboardGreen : .white.opacity(0.18))
                .foregroundStyle(isSelected ? AppTheme.nearBlack : .white)
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
    private let colors: [Color] = [AppTheme.dashboardGreen, .yellow, AppTheme.aqua, .orange]

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
    let iconName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.dashboardGreen.opacity(0.16))
                        .frame(width: 46, height: 46)
                    Image(systemName: iconName)
                        .foregroundStyle(AppTheme.dashboardGreen)
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
            return AppTheme.softGreen.opacity(0.88)
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

private struct PasswordResetSheet: View {
    @Bindable var authState: AuthStateStore
    let accessToken: String
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var passwordAgain = ""

    var body: some View {
        ZStack {
            AppTheme.dashboardBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yeni Şifre")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Maildeki güvenli bağlantı açıldı. Yeni şifreni belirleyip giriş ekranına dönebilirsin.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.nearBlack)
                            .frame(width: 44, height: 44)
                            .background(.white)
                            .clipShape(Circle())
                    }
                }

                AuthSecureField(title: "Yeni şifre", text: $password)
                AuthSecureField(title: "Yeni şifre tekrar", text: $passwordAgain)

                if let message = authState.authMessage {
                    AuthMessageBanner(message: message, isPositive: authState.isAuthMessagePositive)
                }

                Button {
                    Task {
                        guard password == passwordAgain else {
                            authState.authMessage = "İki şifre aynı olmalı."
                            return
                        }
                        await authState.updatePassword(accessToken: accessToken, password: password)
                        if authState.isAuthMessagePositive {
                            onDone()
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if authState.isLoading {
                            ProgressView()
                                .tint(AppTheme.nearBlack)
                        }
                        Text("Şifreyi Güncelle")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.nearBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.dashboardGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .disabled(authState.isLoading)

                Spacer(minLength: 0)
            }
            .padding(22)
        }
    }
}

private struct AuthOptionsSheet: View {
    @Bindable var authState: AuthStateStore
    let favorites: FavoritesStore
    let myCards: MyCardsStore
    let participation: ParticipationStore
    let enter: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    private let syncService = UserDataSyncService()

    var body: some View {
        ZStack {
            AppTheme.dashboardBackground
                .ignoresSafeArea()

            ScrollView {
                if let resetToken = authState.passwordResetAccessToken {
                    PasswordResetSheet(authState: authState, accessToken: resetToken) {
                        authState.clearPasswordResetToken()
                    }
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hesap")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                        Text("E-posta ile gerçek Supabase hesabı oluştur veya giriş yap. Google ve Apple sonraki yayın adımında bağlanacak.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.nearBlack)
                            .frame(width: 44, height: 44)
                            .background(.white)
                            .clipShape(Circle())
                    }
                }

                    Picker("Hesap modu", selection: $isSignUp) {
                        Text("Giriş").tag(false)
                        Text("Kayıt").tag(true)
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 12) {
                        AuthTextField(title: "E-posta", text: $email, systemImage: "envelope.fill")
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        AuthSecureField(title: "Şifre", text: $password)
                    }

                    if let message = authState.authMessage {
                        AuthMessageBanner(message: message, isPositive: authState.isAuthMessagePositive)
                    }

                    Button {
                        Task {
                            if isSignUp {
                                await authState.signUp(email: email, password: password)
                            } else {
                                await authState.signIn(email: email, password: password)
                            }
                            if authState.isAuthenticated {
                                await syncAfterLogin()
                                dismiss()
                                enter()
                            }
                        }
                    } label: {
                        HStack {
                            if authState.isLoading {
                                ProgressView()
                                    .tint(AppTheme.nearBlack)
                            }
                            Text(isSignUp ? "Hesap Oluştur" : "Giriş Yap")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.nearBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.dashboardGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .disabled(authState.isLoading)

                    if !isSignUp {
                        Button {
                            Task {
                                await authState.sendPasswordReset(email: email)
                            }
                        } label: {
                            Text("Şifremi sıfırlama maili gönder")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.dashboardGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .disabled(authState.isLoading)
                    }

                    VStack(spacing: 10) {
                        AuthPreviewButton(title: "Google ile giriş", systemImage: "g.circle.fill")
                        AuthPreviewButton(title: "Apple ile giriş", systemImage: "apple.logo")
                    }

                    Button {
                        authState.continueAsGuest()
                        dismiss()
                        enter()
                    } label: {
                        Text("Misafir olarak devam et")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(22)
                }
            }
        }
    }

    private func syncAfterLogin() async {
        do {
            try await syncService.sync(
                session: authState.session,
                favorites: favorites,
                myCards: myCards,
                participation: participation
            )
            authState.authMessage = "Giriş başarılı. Yerel kayıtların bulut hesabınla senkronlandı."
        } catch {
            authState.authMessage = "Giriş başarılı. Senkron beklemede: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        }
    }
}

private struct AuthMessageBanner: View {
    let message: String
    let isPositive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isPositive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(isPositive ? AppTheme.dashboardGreen : AppTheme.softOrange)
            Text(message)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isPositive ? AppTheme.dashboardGreen : AppTheme.softOrange).opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke((isPositive ? AppTheme.dashboardGreen : AppTheme.softOrange).opacity(0.42), lineWidth: 1)
        }
    }
}

private struct AuthTextField: View {
    let title: String
    @Binding var text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AppTheme.dashboardGreen)
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(title)
                        .foregroundStyle(.white.opacity(0.44))
                }
                TextField("", text: $text)
                    .foregroundStyle(.white)
                    .submitLabel(.next)
            }
        }
        .font(.headline.weight(.semibold))
        .padding(16)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct AuthSecureField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundStyle(AppTheme.dashboardGreen)
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(title)
                        .foregroundStyle(.white.opacity(0.44))
                }
                SecureField("", text: $text)
                    .foregroundStyle(.white)
                    .submitLabel(.done)
            }
        }
        .font(.headline.weight(.semibold))
        .padding(16)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct AuthPreviewButton: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.dashboardGreen)
                .frame(width: 34, height: 34)
                .background(AppTheme.dashboardGreen.opacity(0.12))
                .clipShape(Circle())
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Text("Yakında")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
        }
        .padding(14)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(0.72)
    }
}

private struct AccountView: View {
    @Bindable var authState: AuthStateStore
    let favorites: FavoritesStore
    let myCards: MyCardsStore
    let participation: ParticipationStore
    @Environment(\.dismiss) private var dismiss
    @State private var syncMessage: String?
    @State private var isSyncing = false
    @State private var isShowingPaywall = false
    @State private var isShowingAuthOptions = false
    private let syncService = UserDataSyncService()

    var body: some View {
        ZStack {
            AppTheme.blueBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        CircleIconButton(systemName: "chevron.left") {
                            dismiss()
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hesap")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.dashboardGreen)
                        Text(authState.statusText)
                            .font(.system(size: authState.statusText.contains("@") ? 36 : 44, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.62)
                        Text(authState.isAuthenticated ? "Hesabın Supabase Auth ile açık. Favori, kart ve kazanç kayıtlarını buluta senkronlayabilirsin." : "Misafir kullanım açık. Yayın aşamasında Google ve Apple girişi de buraya bağlanacak.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.76))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        AccountStatusRow(title: "Oturum", value: authState.isAuthenticated ? "Supabase hesabı" : "Misafir", systemImage: "person.fill")
                        AccountStatusRow(title: "E-posta", value: authState.email ?? "Bağlı değil", systemImage: "envelope.fill")
                        AccountStatusRow(title: "Senkron", value: authState.isAuthenticated ? "Bulut senkron hazır" : "Cihazda saklanıyor", systemImage: "arrow.triangle.2.circlepath")
                        AccountStatusRow(title: "Plan", value: authState.plan.displayName, systemImage: "creditcard.fill")
                        AccountStatusRow(
                            title: "Hatırlatıcı",
                            value: EntitlementService.reminderAllowanceText(plan: authState.plan, participation: participation),
                            systemImage: "bell.badge.fill"
                        )
                    }
                    .padding(18)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    }

                    premiumPreview

                    AccountLegalLinks()

                    VStack(spacing: 12) {
                        Button {
                            if authState.isAuthenticated {
                                Task {
                                    await syncNow()
                                }
                            } else {
                                syncMessage = nil
                                isShowingAuthOptions = true
                            }
                        } label: {
                            HStack {
                                if isSyncing {
                                    ProgressView()
                                        .tint(AppTheme.nearBlack)
                                }
                                Label(authState.isAuthenticated ? "Verilerimi Senkronla" : "Giriş ekranından hesap bağla", systemImage: authState.isAuthenticated ? "arrow.triangle.2.circlepath" : "person.crop.circle.badge.plus")
                            }
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.nearBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.dashboardGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .disabled(isSyncing)

                        if let syncMessage {
                            Text(syncMessage)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        Button {
                            authState.signOut()
                        } label: {
                            Text(authState.isAuthenticated ? "Çıkış yap ve misafir moda dön" : "Misafir moda dön")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingPaywall) {
            PaywallPreviewSheet(plan: authState.plan)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { isShowingAuthOptions || authState.passwordResetAccessToken != nil },
            set: { newValue in
                if !newValue {
                    isShowingAuthOptions = false
                    authState.clearPasswordResetToken()
                }
            }
        )) {
            AuthOptionsSheet(authState: authState, favorites: favorites, myCards: myCards, participation: participation) {
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var premiumPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Premium")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Sınırsız hatırlatıcı, reklamsız kullanım ve gelişmiş kazanç raporları için hazır alan.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.70))
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.dashboardGreen)
            }

            Button {
                isShowingPaywall = true
            } label: {
                Label("Premium seçeneklerini gör", systemImage: "creditcard.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.nearBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.dashboardGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(18)
        .background(AppTheme.dashboardGreen.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.dashboardGreen.opacity(0.28), lineWidth: 1)
        }
    }

    private func syncNow() async {
        guard authState.isAuthenticated else {
            syncMessage = "Senkron için önce giriş yapman gerekiyor."
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            try await syncService.sync(session: authState.session, favorites: favorites, myCards: myCards, participation: participation)
            syncMessage = "Favoriler, kartlarım ve katılım kayıtların bulut hesabınla senkronlandı."
        } catch {
            syncMessage = "Senkron beklemede: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        }
    }
}

private struct AccountLegalLinks: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Yardım ve yasal bilgiler")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                AccountLinkButton(title: "Gizlilik Politikası", subtitle: "Hangi verileri neden kullandığımız", systemImage: "lock.shield.fill") {
                    openURL(AppLinks.privacy)
                }
                AccountLinkButton(title: "Destek", subtitle: "Sık sorulan sorular ve yardım", systemImage: "questionmark.circle.fill") {
                    openURL(AppLinks.support)
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct AccountLinkButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.dashboardGreen)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.dashboardGreen.opacity(0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(14)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AccountStatusRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.dashboardGreen)
                .frame(width: 38, height: 38)
                .background(AppTheme.dashboardGreen.opacity(0.14))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }
}

private struct PaywallPreviewSheet: View {
    let plan: SubscriptionPlan
    @Environment(\.dismiss) private var dismiss
    @State private var purchaseService = PremiumPurchaseService()

    var body: some View {
        ZStack {
            AppTheme.dashboardBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kampanya Radarı Premium")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Sınırsız hatırlatıcı, reklamsız kullanım ve gelişmiş kazanç takibi için yayın aboneliği.")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.nearBlack)
                                .frame(width: 44, height: 44)
                                .background(.white)
                                .clipShape(Circle())
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        PaywallBenefitRow(icon: "bell.badge.fill", title: "Sınırsız hatırlatıcı", text: "Birden fazla kampanya için puan son kullanım bildirimleri.")
                        PaywallBenefitRow(icon: "chart.line.uptrend.xyaxis", title: "Gelişmiş kazanç raporu", text: "Harcama, kazanım ve net faydayı daha ayrıntılı takip.")
                        PaywallBenefitRow(icon: "rectangle.on.rectangle.slash", title: "Reklamsız deneyim", text: "Ücretsiz sürümdeki reklam alanları Premium’da kapanır.")
                        PaywallBenefitRow(icon: "creditcard.and.123", title: "Kişisel kart önerileri", text: "Kartlarına göre daha alakalı kampanyaları öne çıkarma altyapısı.")
                    }

                    VStack(spacing: 12) {
                        ForEach(purchaseService.offerings) { offering in
                            PremiumOfferingCard(offering: offering)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mevcut plan")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.62))
                        Text(plan.displayName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.dashboardGreen)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    if let statusMessage = purchaseService.statusMessage {
                        Label(statusMessage, systemImage: "info.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.76))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    VStack(spacing: 12) {
                        Button {
                        } label: {
                            Text(purchaseService.hasStoreProducts ? "Premium'a geç" : "App Store ürünü bekleniyor")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.nearBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.dashboardGreen.opacity(purchaseService.hasStoreProducts ? 1 : 0.62))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .disabled(!purchaseService.hasStoreProducts || purchaseService.isLoading)

                        Button {
                            Task {
                                await purchaseService.restorePurchases()
                            }
                        } label: {
                            Text("Satın alımları geri yükle")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.dashboardGreen)
                        }
                    }
                }
                .padding(22)
            }
        }
        .task {
            await purchaseService.loadOfferings()
        }
    }
}

private struct PremiumOfferingCard: View {
    let offering: PremiumOffering

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: offering.id == .yearly ? "sparkles" : "calendar")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.dashboardGreen)
                .frame(width: 42, height: 42)
                .background(AppTheme.dashboardGreen.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(offering.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    if offering.isBestValue {
                        Text("Avantajlı")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.nearBlack)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.dashboardGreen)
                            .clipShape(Capsule())
                    }
                }
                Text(offering.subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(offering.priceText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                Text(offering.isStoreProductReady ? "Hazır" : "Kurulum bekliyor")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(offering.isStoreProductReady ? AppTheme.dashboardGreen : .white.opacity(0.48))
            }
        }
        .padding(16)
        .background(.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(offering.isBestValue ? AppTheme.dashboardGreen.opacity(0.42) : .white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct PaywallBenefitRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.dashboardGreen)
                .frame(width: 38, height: 38)
                .background(AppTheme.dashboardGreen.opacity(0.14))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
            }
        }
        .padding(14)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ProfileCardsView: View {
    @Bindable var viewModel: CampaignListViewModel
    let myCards: MyCardsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.blueBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        CircleIconButton(systemName: "chevron.left") {
                            dismiss()
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profil")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.dashboardGreen)
                        Text("Kartlarım")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Sahip olduğun banka/kartları seç. Sonra genel kampanyalarda sadece sana uygun fırsatları görebileceksin.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.76))
                    }

                    HStack(spacing: 12) {
                        ProfileStatCard(title: "Seçili", value: "\(myCards.banks.count)")
                        ProfileStatCard(title: "Banka/kart", value: "\(viewModel.banks.count)")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Kart bankaları")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            Spacer()
                            if !myCards.banks.isEmpty {
                                Button("Temizle") {
                                    myCards.clear()
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.dashboardGreen)
                            }
                        }

                        VStack(spacing: 10) {
                            ForEach(viewModel.banks, id: \.self) { bank in
                                ProfileBankRow(
                                    title: viewModel.label(for: bank),
                                    isSelected: myCards.contains(bank)
                                ) {
                                    myCards.toggle(bank)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ProfileStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.66))
            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.dashboardGreen.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct ProfileBankRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.dashboardGreen : .white.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: isSelected ? "checkmark" : "creditcard")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? AppTheme.nearBlack : .white.opacity(0.74))
                }

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(14)
            .background(isSelected ? AppTheme.dashboardGreen.opacity(0.16) : .white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct EarningsView: View {
    @Bindable var viewModel: CampaignListViewModel
    let participation: ParticipationStore
    @Environment(\.dismiss) private var dismiss

    private var trackedCampaigns: [(campaign: Campaign, record: CampaignParticipation)] {
        viewModel.campaigns.compactMap { campaign in
            guard let record = participation.records[campaign.id] else { return nil }
            return (campaign, record)
        }
        .sorted {
            if $0.record.didJoin != $1.record.didJoin {
                return $0.record.didJoin && !$1.record.didJoin
            }
            return $0.campaign.title.localizedCaseInsensitiveCompare($1.campaign.title) == .orderedAscending
        }
    }

    var body: some View {
        ZStack {
            AppTheme.blueBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        CircleIconButton(systemName: "chevron.left") {
                            dismiss()
                        }
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hesaplayıcı")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.dashboardGreen)
                        Text("Kazançlarım")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Katıldığın kampanyaları, harcamalarını ve kazançlarını tek ekranda takip et.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.76))
                    }

                    earningsSummary

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Takip edilen kampanyalar")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)

                        if trackedCampaigns.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(AppTheme.dashboardGreen)
                                Text("Henüz takip yok")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("Bir kampanya detayına girip katılım, harcama veya kazanç bilgisi eklediğinde burada görünecek.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.68))
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        } else {
                            VStack(spacing: 12) {
                                ForEach(trackedCampaigns, id: \.campaign.id) { item in
                                    EarningsCampaignRow(campaign: item.campaign, record: item.record)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var earningsSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Özet")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text((participation.totalEarned - participation.totalSpent).currencyText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.dashboardGreen)
            }

            HStack(spacing: 12) {
                DarkStatTile(title: "Katılım", value: "\(participation.joinedCount)")
                DarkStatTile(title: "Harcama", value: participation.totalSpent.currencyText)
                DarkStatTile(title: "Kazanç", value: participation.totalEarned.currencyText)
            }
        }
        .padding(18)
        .background(AppTheme.dashboardGreen.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct DarkStatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct EarningsCampaignRow: View {
    let campaign: Campaign
    let record: CampaignParticipation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(record.didJoin ? AppTheme.dashboardGreen : .white.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: record.didJoin ? "checkmark" : "bookmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(record.didJoin ? AppTheme.nearBlack : .white.opacity(0.74))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(campaign.displayBank)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.dashboardGreen)
                    Text(campaign.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(campaign.deadlineText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                    if let rewardExpiresAt = record.rewardExpiresAt {
                        Label("Puan son kullanım: \(rewardExpiresAt.shortDateText)", systemImage: "bell.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.dashboardGreen)
                    }
                }
            }

            HStack(spacing: 10) {
                MiniMoneyPill(title: "Harcama", value: record.spentAmount.currencyText)
                MiniMoneyPill(title: "Kazanç", value: record.earnedAmount.currencyText)
                MiniMoneyPill(title: "Net", value: (record.earnedAmount - record.spentAmount).currencyText)
            }
        }
        .padding(16)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct MiniMoneyPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.56))
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.68)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct FilterSheet: View {
    @Bindable var viewModel: CampaignListViewModel
    let favoriteCount: Int
    let myCardCount: Int
    let showsCategoryFilter: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.dashboardBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        sheetHeader

                        if showsCategoryFilter {
                            FilterPanel(title: "Kategori", systemImage: "square.grid.2x2") {
                                VStack(spacing: 10) {
                                    FilterOptionPill(title: "Tümü", isSelected: viewModel.selectedCategories.isEmpty) {
                                        viewModel.clearCategories()
                                    }
                                    ForEach(viewModel.categories, id: \.self) { category in
                                        FilterOptionPill(title: category, isSelected: viewModel.selectedCategories.contains(category)) {
                                            viewModel.toggleCategory(category)
                                        }
                                    }
                                }
                            }
                        }

                        FilterPanel(title: "Kazanım", systemImage: "gift") {
                            VStack(spacing: 10) {
                                FilterOptionPill(title: "Tümü", isSelected: viewModel.selectedRewardType == nil) {
                                    viewModel.selectedRewardType = nil
                                }
                                ForEach(viewModel.rewardTypes, id: \.self) { rewardType in
                                    FilterOptionPill(title: rewardType, isSelected: viewModel.selectedRewardType == rewardType) {
                                        viewModel.selectedRewardType = rewardType
                                    }
                                }
                            }
                        }

                        FilterPanel(title: "Görünüm", systemImage: "star") {
                            VStack(spacing: 12) {
                                Toggle(isOn: $viewModel.showFavoritesOnly) {
                                    Label("Sadece favoriler", systemImage: "star.fill")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                                .tint(AppTheme.dashboardGreen)

                                Toggle(isOn: $viewModel.showMyCardsOnly) {
                                    Label("Benim kartlarım", systemImage: "creditcard.fill")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                                .tint(AppTheme.dashboardGreen)
                                .disabled(myCardCount == 0)
                                .opacity(myCardCount == 0 ? 0.48 : 1)

                                HStack {
                                    Text("Favori sayısı")
                                        .foregroundStyle(.white.opacity(0.70))
                                    Spacer()
                                    Text("\(favoriteCount)")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.dashboardGreen)
                                }

                                HStack {
                                    Text("Kartlarım")
                                        .foregroundStyle(.white.opacity(0.70))
                                    Spacer()
                                    Text("\(myCardCount)")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.dashboardGreen)
                                }
                            }
                        }

                        Button {
                            if showsCategoryFilter {
                                viewModel.clearAdvancedFilters()
                            } else {
                                viewModel.selectedRewardType = nil
                                viewModel.showFavoritesOnly = false
                                viewModel.showMyCardsOnly = false
                            }
                        } label: {
                            Text("Filtreleri Temizle")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.nearBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.dashboardGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                    .padding(22)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Filtreler")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Sonuçları hızlıca daralt")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.nearBlack)
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(Circle())
            }
        }
    }
}

private struct BankFilterSheet: View {
    @Bindable var viewModel: CampaignListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.dashboardBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Banka Filtresi")
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("Bir veya birden fazla banka seç")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.68))
                            }
                            Spacer()
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.nearBlack)
                                    .frame(width: 44, height: 44)
                                    .background(.white)
                                    .clipShape(Circle())
                            }
                        }

                        FilterPanel(title: "Bankalar", systemImage: "creditcard") {
                            VStack(spacing: 10) {
                                FilterOptionPill(title: "Tümü", isSelected: viewModel.selectedBanks.isEmpty) {
                                    viewModel.clearBanks()
                                }
                                ForEach(viewModel.banks, id: \.self) { bank in
                                    FilterOptionPill(title: viewModel.label(for: bank), isSelected: viewModel.selectedBanks.contains(bank)) {
                                        viewModel.toggleBank(bank)
                                    }
                                }
                            }
                        }

                        Button {
                            viewModel.clearBanks()
                        } label: {
                            Text("Banka Filtrelerini Temizle")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.nearBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.dashboardGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                    .padding(22)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct SortSheet: View {
    @Bindable var viewModel: CampaignListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.dashboardBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Sıralama")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Liste akışını düzenle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.68))
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.nearBlack)
                                .frame(width: 44, height: 44)
                                .background(.white)
                                .clipShape(Circle())
                        }
                    }

                    FilterPanel(title: "Sıralama türü", systemImage: "arrow.up.arrow.down") {
                        VStack(spacing: 10) {
                            ForEach(CampaignSortOption.allCases) { option in
                                FilterOptionPill(title: option.rawValue, isSelected: viewModel.sortOption == option) {
                                    viewModel.sortOption = option
                                }
                            }
                        }
                    }

                    Button {
                        viewModel.sortOption = .expiringSoon
                    } label: {
                        Text("Varsayılana Dön")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.nearBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.dashboardGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    Spacer()
                }
                .padding(22)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct FilterPanel<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            content
        }
        .padding(18)
        .background(AppTheme.panelBlack.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.dashboardGreen.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct FilterOptionPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? AppTheme.nearBlack : .white)
                    .lineLimit(1)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.nearBlack)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? AppTheme.dashboardGreen : .white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
