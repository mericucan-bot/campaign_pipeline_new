import AuthenticationServices
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
    @State private var purchaseService = PremiumPurchaseService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var hasEnteredApp = false
    @State private var path: [AppRoute] = []
    @State private var isShowingNamePrompt = false

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
                            EarningsView(viewModel: viewModel, favorites: favorites, participation: participation, authState: authState)
                        case .account:
                            AccountView(authState: authState, favorites: favorites, myCards: myCards, participation: participation, purchaseService: purchaseService)
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
            NewCampaignAlertService.checkAndSchedule(
                campaigns: viewModel.campaigns,
                myCardBanks: myCards.banks,
                plan: authState.plan
            )
        }
        .task {
            let activeIDs = await purchaseService.currentPremiumProductIDs()
            authState.applyStoreEntitlements(activeIDs)
            await purchaseService.listenForTransactionUpdates { activeIDs in
                authState.applyStoreEntitlements(activeIDs)
            }
        }
        .onChange(of: authState.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }
            Task {
                let activeIDs = await purchaseService.currentPremiumProductIDs()
                authState.applyStoreEntitlements(activeIDs)
            }
        }
        .onChange(of: authState.plan) { _, newPlan in
            guard newPlan.isPremiumLike, !viewModel.campaigns.isEmpty else { return }
            NewCampaignAlertService.checkAndSchedule(
                campaigns: viewModel.campaigns,
                myCardBanks: myCards.banks,
                plan: newPlan
            )
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
        .sheet(isPresented: $isShowingNamePrompt) {
            DisplayNamePromptSheet(authState: authState) {
                isShowingNamePrompt = false
            }
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
        }
        .onChange(of: authState.needsDisplayNamePrompt) { _, needs in
            if needs { isShowingNamePrompt = true }
        }
        .overlay {
            if authState.isLoading || authState.isSyncing {
                RadarLoadingOverlay(
                    title: authState.isSyncing ? "Senkronlanıyor" : "İşlem yapılıyor",
                    message: authState.isSyncing
                        ? "Hesap verilerin güvenle aktarılıyor."
                        : "Hesap işlemin güvenli şekilde tamamlanıyor."
                )
                .allowsHitTesting(true)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: authState.isLoading || authState.isSyncing)
    }
}

private struct DisplayNamePromptSheet: View {
    @Bindable var authState: AuthStateStore
    let onDone: () -> Void
    @State private var displayName = ""
    @State private var isSaving = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.dashboardBackground
                .ignoresSafeArea()
                .onTapGesture {
                    isNameFocused = false
                }

            VStack(alignment: .leading, spacing: 20) {
                Capsule()
                    .fill(.white.opacity(0.28))
                    .frame(width: 44, height: 5)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Profil adı")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Profilinde görünmesini istediğin ismi gir.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(AppTheme.dashboardGreen)
                    ZStack(alignment: .leading) {
                        if displayName.isEmpty {
                            Text("Ad Soyad")
                                .foregroundStyle(.white.opacity(0.44))
                        }
                        TextField("", text: $displayName)
                            .focused($isNameFocused)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .foregroundStyle(.white)
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

                if let message = authState.authMessage {
                    AuthMessageBanner(message: message, isPositive: authState.isAuthMessagePositive)
                }

                Button {
                    guard !isSaving else { return }
                    isSaving = true
                    Task {
                        await authState.updateDisplayName(displayName)
                        isSaving = false
                        if AuthStateStore.cleanDisplayName(authState.displayName) != nil {
                            onDone()
                        }
                    }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(AppTheme.nearBlack)
                        }
                        Text("Devam et")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.nearBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.dashboardGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .disabled(AuthStateStore.cleanDisplayName(displayName) == nil || isSaving)

                Spacer(minLength: 0)
            }
            .padding(22)
        }
        .onAppear {
            if displayName.isEmpty,
               authState.displayName != "Kullanıcı",
               authState.displayName != "Apple ile giriş" {
                displayName = authState.displayName
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            isNameFocused = true
        }
    }
}

// MARK: - Onboarding

private struct IntroView: View {
    @Bindable var authState: AuthStateStore
    let favorites: FavoritesStore
    let myCards: MyCardsStore
    let participation: ParticipationStore
    let enter: () -> Void

    @State private var currentPage = 0
    @State private var isShowingAuthOptions = false
    private let pageCount = 3

    var body: some View {
        ZStack {
            OnboardingPremiumBackground()
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingRadarPage(page: $currentPage).tag(0)
                OnboardingSavingsPage(page: $currentPage).tag(1)
                OnboardingCardsRadarPage(
                    page: $currentPage,
                    start: { isShowingAuthOptions = true }
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: Binding(
            get: { isShowingAuthOptions || authState.passwordResetAccessToken != nil },
            set: {
                if !$0 {
                    isShowingAuthOptions = false
                    authState.clearPasswordResetToken()
                }
            }
        )) {
            AuthOptionsSheet(
                authState: authState,
                favorites: favorites,
                myCards: myCards,
                participation: participation,
                enter: enter
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Onboarding Shared Layout

private struct OnboardingScaffold<Visual: View>: View {
    @ViewBuilder var visual: () -> Visual
    let activePage: Int
    let title: String
    let subtitle: String
    let buttonTitle: String
    let showsArrow: Bool
    let buttonAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 22)

            visual()
                .frame(height: 500)
                .padding(.horizontal, 18)

            Spacer(minLength: 6)

            VStack(alignment: .leading, spacing: 22) {
                OnboardingLogoBadge()

                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineSpacing(5)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 8)

                Text(subtitle)
                    .font(.system(size: 19, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(3)
                    .lineSpacing(4)

                HStack(alignment: .center) {
                    OnboardingPaginationDots(active: activePage, count: 3)
                    Spacer()
                    OnboardingPrimaryButton(
                        title: buttonTitle,
                        showsArrow: showsArrow,
                        action: buttonAction
                    )
                }
                .padding(.top, 18)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 42)
        }
    }
}

private struct OnboardingPremiumBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.nearBlack, AppTheme.ink, AppTheme.nearBlack],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [AppTheme.dashboardGreen.opacity(0.18), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 390
            )
            .blur(radius: 26)
            .offset(y: -40)
        }
    }
}

private struct OnboardingRadarPage: View {
    @Binding var page: Int

    var body: some View {
        OnboardingScaffold(
            visual: { OnboardingSectorRadarIllustration() },
            activePage: page,
            title: "En iyi fırsatları...",
            subtitle: "Binlerce kampanya içinden sana en uygun olanları radarına al.",
            buttonTitle: "İleri",
            showsArrow: true,
            buttonAction: { withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { page = 1 } }
        )
    }
}

private struct OnboardingSavingsPage: View {
    @Binding var page: Int

    var body: some View {
        OnboardingScaffold(
            visual: { OnboardingSavingsJarImage() },
            activePage: page,
            title: "Tasarruf et,...",
            subtitle: "Kaçırdığın fırsatları bul, birikimini artır, her alışverişte avantaj yakala.",
            buttonTitle: "İleri",
            showsArrow: true,
            buttonAction: { withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { page = 2 } }
        )
    }
}

private struct OnboardingCardsRadarPage: View {
    @Binding var page: Int
    let start: () -> Void

    var body: some View {
        OnboardingScaffold(
            visual: { OnboardingCardsRadarOriginalImage() },
            activePage: page,
            title: "Tüm fırsatlar\ntek radarında!",
            subtitle: "Bankalardan kartlara, avantajlardan kampanyalara kadar aradığın her şey burada.",
            buttonTitle: "Keşfetmeye başla",
            showsArrow: true,
            buttonAction: start
        )
    }
}

// MARK: - Onboarding Visuals

private struct OnboardingCardsRadarOriginalImage: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    AppTheme.dashboardGreen.opacity(0.18),
                    AppTheme.deepBlue.opacity(0.20),
                    .clear
                ],
                center: .center,
                startRadius: 90,
                endRadius: 320
            )
            .blur(radius: 18)

            Image("OnboardingCardsRadarOriginal")
                .resizable()
                .scaledToFit()
                .mask(
                    RadialGradient(
                        colors: [
                            .white,
                            .white,
                            .white.opacity(0.82),
                            .clear
                        ],
                        center: .center,
                        startRadius: 190,
                        endRadius: 430
                    )
                )
                .shadow(color: AppTheme.dashboardGreen.opacity(0.18), radius: 28)
        }
        .frame(maxWidth: .infinity, maxHeight: 500)
    }
}

private struct OnboardingSectorRadarIllustration: View {
    private let sectors = [
        OnboardingSectorItem(title: "Market", icon: "cart.fill", x: -118, y: -112),
        OnboardingSectorItem(title: "Yakıt", icon: "fuelpump.fill", x: 118, y: -104),
        OnboardingSectorItem(title: "Alışveriş", icon: "bag.fill", x: -120, y: 116),
        OnboardingSectorItem(title: "Seyahat", icon: "airplane", x: 118, y: 108)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                OnboardingRadarCore(size: min(geo.size.width * 0.9, 360), strong: true)
                    .offset(y: 16)

                ForEach(sectors) { sector in
                    OnboardingSectorPillView(item: sector)
                        .offset(x: sector.x, y: sector.y + 18)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct OnboardingSectorItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let x: CGFloat
    let y: CGFloat
}

private struct OnboardingSectorPillView: View {
    let item: OnboardingSectorItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.dashboardGreen)

            Text(item.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 20)
        .frame(height: 62)
        .background(.ultraThinMaterial.opacity(0.45), in: Capsule())
        .background(AppTheme.panelBlack.opacity(0.78), in: Capsule())
        .overlay(Capsule().stroke(AppTheme.dashboardGreen.opacity(0.45), lineWidth: 1.2))
        .shadow(color: AppTheme.dashboardGreen.opacity(0.18), radius: 18)
    }
}

private struct OnboardingSavingsJarImage: View {
    var body: some View {
        ZStack {
            // Mint radial glow — arka planla kaynaştırmak için
            RadialGradient(
                colors: [
                    AppTheme.dashboardGreen.opacity(0.32),
                    AppTheme.dashboardGreen.opacity(0.08),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 260
            )
            .blur(radius: 22)

            Image("OnboardingSavingsJar")
                .resizable()
                .scaledToFit()
                .mask(
                    // Kenarları yumuşatıp arka planla eriyor
                    RadialGradient(
                        colors: [.white, .white, .white.opacity(0.7), .clear],
                        center: .center,
                        startRadius: 120,
                        endRadius: 340
                    )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: 500)
    }
}

private struct OnboardingSavingsJarIllustration: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [AppTheme.dashboardGreen.opacity(0.36), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 220
            )
            .blur(radius: 26)

            Circle()
                .stroke(AppTheme.dashboardGreen.opacity(0.28), lineWidth: 1.3)
                .frame(width: 310, height: 310)

            onboardingOrbitIcon("chart.bar.fill", x: -132, y: -118)
            onboardingOrbitIcon("wallet.pass.fill", x: 0, y: -160)
            onboardingOrbitIcon("percent", x: -138, y: 72)
            onboardingOrbitIcon("bell.fill", x: 138, y: 72)

            ZStack {
                RoundedRectangle(cornerRadius: 34)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.dashboardGreen.opacity(0.22),
                                Color(hex: "#1B6F68").opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 170, height: 205)
                    .overlay(
                        RoundedRectangle(cornerRadius: 34)
                            .stroke(AppTheme.dashboardGreen.opacity(0.65), lineWidth: 1.6)
                    )
                    .offset(y: 28)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.dashboardGreen.opacity(0.75), Color(hex: "#1B6F68").opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 176, height: 32)
                    .offset(y: -84)

                VStack(spacing: -2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Capsule()
                            .fill(AppTheme.dashboardGreen.opacity(0.35))
                            .frame(width: 70, height: 16)
                            .overlay(Capsule().stroke(AppTheme.dashboardGreen.opacity(0.5), lineWidth: 1))
                    }
                }
                .offset(x: 34, y: 20)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.dashboardGreen.opacity(0.92), Color(hex: "#1B6F68").opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 86, height: 86)
                    .overlay(Circle().stroke(AppTheme.dashboardGreen.opacity(0.8), lineWidth: 3))
                    .overlay(
                        Text("₺")
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#0B1B26").opacity(0.95))
                    )
                    .offset(x: -34, y: 66)
            }
            .shadow(color: AppTheme.dashboardGreen.opacity(0.35), radius: 28)
        }
    }

    private func onboardingOrbitIcon(_ name: String, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(AppTheme.panelBlack.opacity(0.78))
            .frame(width: 76, height: 76)
            .overlay(Circle().stroke(AppTheme.dashboardGreen.opacity(0.65), lineWidth: 1.4))
            .overlay(
                Image(systemName: name)
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(AppTheme.dashboardGreen)
            )
            .offset(x: x, y: y)
            .shadow(color: AppTheme.dashboardGreen.opacity(0.20), radius: 18)
    }
}

private struct OnboardingRadarCore: View {
    let size: CGFloat
    let strong: Bool

    var body: some View {
        ZStack {
            ForEach(1...4, id: \.self) { index in
                Circle()
                    .stroke(AppTheme.dashboardGreen.opacity(strong ? 0.22 : 0.14), lineWidth: 1)
                    .frame(width: size * CGFloat(index) / 4, height: size * CGFloat(index) / 4)
            }

            Rectangle()
                .fill(AppTheme.dashboardGreen.opacity(0.18))
                .frame(width: size, height: 1)
            Rectangle()
                .fill(AppTheme.dashboardGreen.opacity(0.18))
                .frame(width: 1, height: size)

            Path { path in
                path.move(to: CGPoint(x: size / 2, y: size / 2))
                path.addLine(to: CGPoint(x: size * 0.88, y: size * 0.33))
            }
            .stroke(AppTheme.dashboardGreen, style: StrokeStyle(lineWidth: strong ? 2.5 : 1.8, lineCap: .round))
            .frame(width: size, height: size)
            .shadow(color: AppTheme.dashboardGreen.opacity(0.65), radius: 8)

            Circle()
                .fill(AppTheme.dashboardGreen)
                .frame(width: strong ? 14 : 10, height: strong ? 14 : 10)
                .shadow(color: AppTheme.dashboardGreen, radius: 12)

            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(AppTheme.dashboardGreen)
                    .frame(width: strong ? 6 : 5, height: strong ? 6 : 5)
                    .offset(
                        x: [70, -54, 45, -22][i] * size / 300,
                        y: [-18, 48, 70, -80][i] * size / 300
                    )
                    .shadow(color: AppTheme.dashboardGreen, radius: 8)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct OnboardingLogoBadge: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "scope")
                .font(.system(size: 22, weight: .bold))
            VStack(alignment: .leading, spacing: 0) {
                Text("Kampanya")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.85))
                Text("R A D A R I")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.dashboardGreen)
            }
        }
        .foregroundStyle(AppTheme.dashboardGreen)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(AppTheme.panelBlack.opacity(0.78), in: Capsule())
        .overlay(Capsule().stroke(AppTheme.dashboardGreen.opacity(0.45), lineWidth: 1.1))
    }
}

private struct OnboardingPaginationDots: View {
    let active: Int
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == active ? AppTheme.dashboardGreen : Color.white.opacity(0.22))
                    .frame(width: index == active ? 26 : 9, height: 9)
            }
        }
    }
}

private struct OnboardingPrimaryButton: View {
    let title: String
    let showsArrow: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                if showsArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 19, weight: .bold))
                }
            }
            .foregroundStyle(Color.black.opacity(0.88))
            .padding(.horizontal, 28)
            .frame(height: 62)
            .background(
                LinearGradient(
                    colors: [AppTheme.dashboardGreen, Color(hex: "#4ADDC5")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .shadow(color: AppTheme.dashboardGreen.opacity(0.38), radius: 24, y: 10)
        }
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
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Kampanya")
                            .font(.system(size: 36, weight: .black))
                            .foregroundStyle(.white)
                        Text("Radarı")
                            .font(.system(size: 36, weight: .black))
                            .foregroundStyle(AppTheme.dashboardGreen)
                    }
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
        Group {
            if viewModel.isLoading && viewModel.campaigns.isEmpty {
                LoadingInsightCard()
            } else {
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
            }
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
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(AppTheme.dashboardGreen)
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                HStack(spacing: 12) {
                    DarkStatTile(title: "Katılım", value: "\(participation.joinedCount)")
                    DarkStatTile(title: "Harcama", value: participation.totalSpent.currencyText)
                    DarkStatTile(title: "Kazanç", value: participation.totalEarned.currencyText)
                }

                Text("Kampanya detaylarında katılım ve kazanç bilgilerini işaretleyebilirsin.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.66))
            }
            .padding(18)
            .background {
                LinearGradient(
                    colors: [
                        AppTheme.panelBlack.opacity(0.98),
                        Color(red: 0.03, green: 0.16, blue: 0.14).opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.dashboardGreen.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: AppTheme.dashboardGreen.opacity(0.12), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct LoadingInsightCard: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(AppTheme.dashboardGreen.opacity(0.22), lineWidth: 16)
                    .frame(width: 116, height: 116)
                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(AppTheme.dashboardGreen, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 116, height: 116)
                    .rotationEffect(.degrees(isPulsing ? 360 : 0))
                    .animation(.linear(duration: 1.1).repeatForever(autoreverses: false), value: isPulsing)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Kampanyalar yükleniyor")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Bankalardan gelen güncel veriler hazırlanıyor.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.70))
            }
            Spacer()
        }
        .onAppear {
            isPulsing = true
        }
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
    @State private var visibleCampaigns: [Campaign] = []
    @State private var favoriteIDsSnapshot: Set<String> = []
    @State private var myCardBanksSnapshot: Set<String> = []
    @State private var openingCampaign: Campaign?
    @State private var isShowingRadarScan = false
    @State private var radarScanTask: Task<Void, Never>?
    @State private var isShowingClearFavoritesConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let filteredCampaigns = visibleCampaigns
        let favoriteIDs = favoriteIDsSnapshot

        ZStack(alignment: .bottomTrailing) {
            AppTheme.blueBackground
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.campaigns.isEmpty {
                RadarLoadingOverlay(
                    title: "Kampanyalar yükleniyor",
                    message: "Radar güncel fırsatları tarıyor."
                )
                .allowsHitTesting(false)
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
                                    Button {
                                        openCampaign(campaign)
                                    } label: {
                                        CampaignCardView(
                                            campaign: campaign,
                                            isFavorite: favoriteIDs.contains(campaign.id)
                                        )
                                        .equatable()
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
                        let shouldShow = offset < -80
                        if showScrollToTop != shouldShow {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                showScrollToTop = shouldShow
                            }
                        }
                    }
                    .scrollToTopGeometryTracking { shouldShow in
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
                                .padding(.bottom, 24)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if isShowingRadarScan {
                RadarLoadingOverlay(
                    title: "Radar taraması",
                    message: "Kampanya detayı hazırlanıyor."
                )
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
        .navigationDestination(item: $openingCampaign) { campaign in
            CampaignDetailView(campaign: campaign, favorites: favorites, participation: participation, authState: authState)
                .onAppear {
                    stopRadarScan()
                }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingFilters) {
            FilterSheet(
                viewModel: viewModel,
                favoriteCount: favoriteIDsSnapshot.count,
                myCardCount: myCardBanksSnapshot.count,
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
        .onAppear {
            refreshSnapshotsAndVisibleCampaigns()
        }
        .onChange(of: viewModel.campaignsRevision) { _, _ in
            refreshSnapshotsAndVisibleCampaigns()
        }
        .onChange(of: viewModel.searchText) { _, _ in
            refreshVisibleCampaigns()
        }
        .onChange(of: viewModel.selectedBanks) { _, _ in
            refreshVisibleCampaigns()
        }
        .onChange(of: viewModel.selectedCategories) { _, _ in
            refreshVisibleCampaigns()
        }
        .onChange(of: viewModel.selectedRewardType) { _, _ in
            refreshVisibleCampaigns()
        }
        .onChange(of: viewModel.showFavoritesOnly) { _, _ in
            refreshVisibleCampaigns()
        }
        .onChange(of: viewModel.showMyCardsOnly) { _, _ in
            refreshVisibleCampaigns()
        }
        .onChange(of: viewModel.sortOption) { _, _ in
            refreshVisibleCampaigns()
        }
        .onChange(of: favorites.ids) { _, newIDs in
            favoriteIDsSnapshot = newIDs
            if viewModel.showFavoritesOnly {
                refreshVisibleCampaigns(favoriteIDs: newIDs)
            }
        }
        .onChange(of: myCards.banks) { _, newBanks in
            myCardBanksSnapshot = newBanks
            if viewModel.showMyCardsOnly {
                refreshVisibleCampaigns(myCardBanks: newBanks)
            }
        }
    }

    private func refreshSnapshotsAndVisibleCampaigns() {
        favoriteIDsSnapshot = favorites.ids
        myCardBanksSnapshot = myCards.banks
        refreshVisibleCampaigns(favoriteIDs: favoriteIDsSnapshot, myCardBanks: myCardBanksSnapshot)
    }

    private func refreshVisibleCampaigns(
        favoriteIDs: Set<String>? = nil,
        myCardBanks: Set<String>? = nil
    ) {
        let favoriteIDs = favoriteIDs ?? favoriteIDsSnapshot
        let myCardBanks = myCardBanks ?? myCardBanksSnapshot
        visibleCampaigns = viewModel.filteredCampaigns(favoriteIDs: favoriteIDs, myCardBanks: myCardBanks)
    }

    private func openCampaign(_ campaign: Campaign) {
        radarScanTask?.cancel()
        openingCampaign = campaign
        radarScanTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else { return }
            isShowingRadarScan = openingCampaign == campaign
        }
    }

    private func stopRadarScan() {
        radarScanTask?.cancel()
        radarScanTask = nil
        isShowingRadarScan = false
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
                HStack(alignment: .firstTextBaseline) {
                    Text(listTitle)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    if viewModel.showFavoritesOnly && !favorites.ids.isEmpty {
                        Button {
                            isShowingClearFavoritesConfirmation = true
                        } label: {
                            Label("Tümünü kaldır", systemImage: "trash")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.red.opacity(0.82))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("\(count) sonuç listeleniyor")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))
            }

            searchField
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .confirmationDialog(
            "Tüm favorileri kaldır",
            isPresented: $isShowingClearFavoritesConfirmation,
            titleVisibility: .visible
        ) {
            Button("Tümünü Kaldır", role: .destructive) {
                favorites.removeAll()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("\(favorites.ids.count) favori kampanya listeden kaldırılacak.")
        }
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
                Text("\(favoriteIDsSnapshot.count)")
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
                .foregroundStyle(AppTheme.muted)
            ZStack(alignment: .leading) {
                if viewModel.searchText.isEmpty {
                    Text("Market, ulaşım, taksit…")
                        .foregroundStyle(AppTheme.muted)
                }
                TextField("", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppTheme.deepBlue)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(AppTheme.borderSubtle, lineWidth: 1))
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
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(AppTheme.panelBlack)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(AppTheme.borderSubtle, lineWidth: 1))
                .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 6)
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
                    .foregroundStyle(AppTheme.textPrimary)
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
            return AppTheme.panelBlack
        case let name where name.contains("akaryakit") || name.contains("yakıt") || name.contains("yakit"):
            return AppTheme.deepBlue
        case let name where name.contains("seyahat"):
            return AppTheme.panelBlack
        case let name where name.contains("online"):
            return AppTheme.panelBlack
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
                .foregroundStyle(AppTheme.textPrimary)
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
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.panelBlack)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(AppTheme.borderSubtle, lineWidth: 1))
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
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var appleSignInNonce: String?
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
                        Text("E-posta veya Apple ile hesap oluştur ya da giriş yap. Google sonraki yayın adımında bağlanacak.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.panelBlack)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(AppTheme.borderSubtle, lineWidth: 1))
                    }
                }

                    Picker("Hesap modu", selection: $isSignUp) {
                        Text("Giriş").tag(false)
                        Text("Kayıt").tag(true)
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 12) {
                        if isSignUp {
                            AuthTextField(title: "Adın (isteğe bağlı)", text: $displayName, systemImage: "person.fill")
                                .textInputAutocapitalization(.words)
                        }
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
                                await authState.signUp(email: email, password: password, displayName: displayName)
                            } else {
                                await authState.signIn(email: email, password: password)
                            }
                            if authState.isAuthenticated {
                                dismiss()
                                enter()
                                await syncAfterLogin()
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
                        SignInWithAppleButton(.continue) { request in
                            do {
                                let nonce = try AppleSignInNonce.random()
                                appleSignInNonce = nonce
                                request.requestedScopes = [.email, .fullName]
                                request.nonce = AppleSignInNonce.sha256(nonce)
                            } catch {
                                appleSignInNonce = nil
                                authState.authMessage = "Apple ile giriş başlatılamadı, tekrar dene."
                            }
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .disabled(authState.isLoading)
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
        .overlay {
            if authState.isLoading {
                RadarLoadingOverlay(
                    title: "İşlem yapılıyor",
                    message: "Giriş işlemin güvenli şekilde tamamlanıyor."
                )
                .allowsHitTesting(true)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: authState.isLoading)
    }

    private func syncAfterLogin() async {
        authState.isSyncing = true
        defer { authState.isSyncing = false }
        do {
            try await syncUserDataWithFreshSession()
            authState.authMessage = "Giriş başarılı. Yerel kayıtların bulut hesabınla senkronlandı."
        } catch {
            authState.authMessage = "Giriş başarılı. Senkron beklemede: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        }
    }

    private func syncUserDataWithFreshSession() async throws {
        let session = try await authState.sessionForNetwork()
        do {
            try await syncService.sync(
                session: session,
                favorites: favorites,
                myCards: myCards,
                participation: participation
            )
        } catch let error as UserDataSyncError where error.isExpiredJWT {
            let refreshedSession = try await authState.sessionForNetwork(forceRefresh: true)
            try await syncService.sync(
                session: refreshedSession,
                favorites: favorites,
                myCards: myCards,
                participation: participation
            )
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce = appleSignInNonce else {
                authState.authMessage = "Apple giriş bilgisi okunamadı. Tekrar dene."
                return
            }

            Task {
                await authState.signInWithApple(idToken: idToken, nonce: nonce, preferredName: appleDisplayName(from: credential))
                if authState.isAuthenticated {
                    dismiss()
                    enter()
                    await syncAfterLogin()
                }
            }
        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }
            authState.authMessage = "Apple ile giriş tamamlanamadı. \(error.localizedDescription)"
        }
    }

    private func appleDisplayName(from credential: ASAuthorizationAppleIDCredential) -> String? {
        guard let fullName = credential.fullName else { return nil }
        let formatted = PersonNameComponentsFormatter.localizedString(from: fullName, style: .default)
        return AuthStateStore.cleanDisplayName(formatted)
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
    let purchaseService: PremiumPurchaseService
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
                        Text(authState.accountDescriptionText)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.76))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        AccountStatusRow(title: "Plan", value: authState.plan.displayName, systemImage: "creditcard.fill")
                        AccountStatusRow(
                            title: "Hatırlatıcı",
                            value: EntitlementService.reminderAllowanceText(plan: authState.plan, participation: participation),
                            systemImage: "bell.badge.fill"
                        )
                        AccountStatusRow(
                            title: "Favori",
                            value: EntitlementService.favoriteAllowanceText(plan: authState.plan, favorites: favorites),
                            systemImage: "star.fill"
                        )
                        AccountStatusRow(
                            title: "Kart alarmı",
                            value: authState.plan.isPremiumLike ? "Aktif" : "Premium gerekli",
                            systemImage: "bell.and.waves.left.and.right.fill"
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
        .overlay {
            if authState.isLoading {
                RadarLoadingOverlay(
                    title: "Çıkış yapılıyor",
                    message: "Hesabından güvenli şekilde çıkılıyor."
                )
                .allowsHitTesting(true)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: authState.isLoading)
        .onChange(of: authState.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                dismiss()
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallPreviewSheet(authState: authState, purchaseService: purchaseService)
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
                    Text("Öncelikli hatırlatıcı, reklamsız kullanım ve gelişmiş kazanç raporları için hazır alan.")
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
            try await syncUserDataWithFreshSession()
            syncMessage = "Favoriler, kartlarım ve katılım kayıtların bulut hesabınla senkronlandı."
        } catch {
            syncMessage = "Senkron beklemede: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        }
    }

    private func syncUserDataWithFreshSession() async throws {
        let session = try await authState.sessionForNetwork()
        do {
            try await syncService.sync(
                session: session,
                favorites: favorites,
                myCards: myCards,
                participation: participation
            )
        } catch let error as UserDataSyncError where error.isExpiredJWT {
            let refreshedSession = try await authState.sessionForNetwork(forceRefresh: true)
            try await syncService.sync(
                session: refreshedSession,
                favorites: favorites,
                myCards: myCards,
                participation: participation
            )
        }
    }
}

private struct AccountLegalLinks: View {
    @State private var document: LegalDocument?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Yardım ve yasal bilgiler")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                AccountLinkButton(title: "Gizlilik Politikası", subtitle: "Hangi verileri neden kullandığımız", systemImage: "lock.shield.fill") {
                    document = .privacy
                }
                AccountLinkButton(title: "Destek", subtitle: "Sık sorulan sorular ve yardım", systemImage: "questionmark.circle.fill") {
                    document = .support
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
        .sheet(item: $document) { document in
            LegalDocumentSheet(document: document)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

private enum LegalDocument: Identifiable {
    case privacy
    case support

    var id: String {
        title
    }

    var title: String {
        switch self {
        case .privacy: "Gizlilik Politikası"
        case .support: "Destek"
        }
    }

    var subtitle: String {
        switch self {
        case .privacy:
            "Son güncelleme: 16 Mayıs 2026. Kampanya Radarı, banka ve kart kampanyalarını takip etmeyi kolaylaştıran bilgilendirme uygulamasıdır."
        case .support:
            "Banka ve kart kampanyalarını takip ederken ihtiyaç duyabileceğin temel yardım bilgileri."
        }
    }

    var sections: [LegalSection] {
        switch self {
        case .privacy:
            [
                LegalSection(title: "Toplanan veriler", body: "E-posta adresi ve Apple ile giriş bilgisi hesap oluşturma ve oturum yönetimi için Supabase Auth üzerinden işlenir. Favoriler, Kartlarım tercihleri, kampanya katılım kayıtları, harcadım/kazandım tutarları ve hatırlatıcı tarihleri cihazda saklanır; kullanıcı giriş yaptığında Supabase ile senkronlanabilir."),
                LegalSection(title: "Toplanmayan veriler", body: "Banka kartı numarası, banka hesabı, müşteri numarası veya banka şifresi toplanmaz. Uygulama finansal işlem yapmaz, kullanıcı adına harcama veya kampanya katılımı gerçekleştirmez."),
                LegalSection(title: "Verilerin kullanım amacı", body: "Kampanyaları filtrelemek, favorileri ve kullanıcının kart tercihlerini göstermek; kampanya takibi, kazanç kaydı ve puan son kullanım hatırlatıcısı sunmak; Free ve Premium plan limitlerini uygulamak için kullanılır."),
                LegalSection(title: "Üçüncü taraf hizmetler", body: "Supabase kimlik doğrulama ve senkron veriler için, Apple App Store ve StoreKit abonelik ve satın alma yönetimi için kullanılır. İleride reklam veya analitik SDK'sı eklenirse bu politika ve App Store gizlilik cevapları güncellenecektir."),
                LegalSection(title: "Kullanıcı hakları", body: "Kullanıcı hesabını, favorilerini, kart tercihlerini ve katılım kayıtlarını silme talebi gönderebilir. Destek ekranındaki bilgilerle iletişim kurulabilir.")
            ]
        case .support:
            [
                LegalSection(title: "Kampanya Radarı ne yapar?", body: "Banka ve kart kampanyalarını tek ekranda keşfetmene, favorilere almana, kendi kartlarına göre filtrelemene ve puan son kullanım hatırlatıcıları kurmana yardımcı olur."),
                LegalSection(title: "Kampanyaya uygulama üzerinden katılabilir miyim?", body: "Hayır. Uygulama bilgilendirme ve takip aracıdır. Kampanyaya katılım için ilgili bankanın resmi sitesi veya mobil uygulaması kullanılmalıdır."),
                LegalSection(title: "Banka bilgilerimi giriyor muyum?", body: "Hayır. Uygulama banka kartı numarası, banka hesabı, müşteri numarası veya banka şifresi istemez."),
                LegalSection(title: "Hatırlatıcılar nasıl çalışır?", body: "Bir kampanyada Katıldım seçildiğinde puan son kullanım tarihi ve tutar girilebilir. Bildirim izni verilirse uygulama son kullanım tarihinden önce hatırlatma gönderebilir."),
                LegalSection(title: "Destek talebi için hangi bilgiler gerekir?", body: "Cihaz modeli, iOS sürümü, sorunun oluştuğu ekran, varsa ekran görüntüsü ve yaklaşık tarih/saat bilgisi destek sürecini hızlandırır.")
            ]
        }
    }
}

private struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

private struct LegalDocumentSheet: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.dashboardBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kampanya Radarı")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.dashboardGreen)
                            Text(document.title)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(AppTheme.panelBlack)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(AppTheme.borderSubtle, lineWidth: 1))
                        }
                    }

                    Text(document.subtitle)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.72))

                    VStack(spacing: 12) {
                        ForEach(document.sections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.title)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                Text(section.body)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.68))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(AppTheme.dashboardGreen.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(AppTheme.dashboardGreen.opacity(0.22), lineWidth: 1)
                            }
                        }
                    }
                }
                .padding(22)
            }
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
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
            Spacer()
        }
    }
}

private struct PaywallPreviewSheet: View {
    @Bindable var authState: AuthStateStore
    let purchaseService: PremiumPurchaseService
    @Environment(\.dismiss) private var dismiss

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
                            Text("Kartına özel kampanya alarmı, sınırsız favori ve sınırsız hatırlatıcı.")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.panelBlack)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(AppTheme.borderSubtle, lineWidth: 1))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        PaywallBenefitRow(icon: "bell.and.waves.left.and.right.fill", title: "Kartıma özel yeni kampanya alarmı", text: "Kartlarımda kayıtlı bankalar için yeni kampanya çıktığında bildirim alırsın.")
                        PaywallBenefitRow(icon: "star.fill", title: "Sınırsız favori", text: "Free planda 3 favori hakkın var. Premium ile sınırsız kampanya kaydet.")
                        PaywallBenefitRow(icon: "bell.badge.fill", title: "Sınırsız hatırlatıcı", text: "Birden fazla kampanya için puan son kullanım bildirimleri.")
                        PaywallBenefitRow(icon: "chart.line.uptrend.xyaxis", title: "Gelişmiş kazanç takibi", text: "Harcama, kazanım ve net faydayı takip et.")
                    }

                    VStack(spacing: 12) {
                        ForEach(purchaseService.offerings) { offering in
                            Button {
                                purchaseService.select(offering)
                            } label: {
                                PremiumOfferingCard(
                                    offering: offering,
                                    isSelected: purchaseService.selectedProductID == offering.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mevcut plan")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.62))
                        Text(authState.plan.displayName)
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
                            Task {
                                let didPurchase = await purchaseService.purchaseSelectedOffering()
                                let activeIDs = await purchaseService.currentPremiumProductIDs()
                                if didPurchase {
                                    if activeIDs.isEmpty {
                                        authState.applyPremiumPurchasePreview()
                                    } else {
                                        authState.applyStoreEntitlements(activeIDs)
                                    }
                                } else if !activeIDs.isEmpty {
                                    authState.applyStoreEntitlements(activeIDs)
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if purchaseService.isLoading {
                                    ProgressView()
                                        .tint(AppTheme.nearBlack)
                                }
                                Text(purchaseService.hasStoreProducts ? "Premium'a geç" : "App Store ürünü bekleniyor")
                            }
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
                                let didRestore = await purchaseService.restorePurchases()
                                if didRestore {
                                    let activeIDs = await purchaseService.currentPremiumProductIDs()
                                    authState.applyStoreEntitlements(activeIDs)
                                }
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
    let isSelected: Bool

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
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.dashboardGreen)
                }
            }
        }
        .padding(16)
        .background(isSelected ? AppTheme.dashboardGreen.opacity(0.13) : .white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? AppTheme.dashboardGreen.opacity(0.72) : (offering.isBestValue ? AppTheme.dashboardGreen.opacity(0.42) : .white.opacity(0.08)), lineWidth: 1)
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
    @State private var selectedBanks: Set<String> = []
    @State private var didLoadSelection = false
    @State private var isSavingCards = false
    @State private var didPersistSelection = false

    var body: some View {
        ZStack {
            AppTheme.blueBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        CircleIconButton(systemName: "chevron.left") {
                            saveAndDismiss()
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
                        ProfileStatCard(title: "Seçili", value: "\(selectedBanks.count)")
                        ProfileStatCard(title: "Banka/kart", value: "\(viewModel.banks.count)")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Kart bankaları")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            Spacer()
                            if !selectedBanks.isEmpty {
                                Button("Temizle") {
                                    selectedBanks.removeAll()
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.dashboardGreen)
                            }
                        }

                        VStack(spacing: 10) {
                            ForEach(viewModel.banks, id: \.self) { bank in
                                ProfileBankRow(
                                    title: viewModel.label(for: bank),
                                    isSelected: selectedBanks.contains(bank)
                                ) {
                                    toggleLocalSelection(bank)
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
        .onAppear {
            guard !didLoadSelection else { return }
            selectedBanks = myCards.banks
            didLoadSelection = true
        }
        .onDisappear {
            if !didPersistSelection {
                myCards.replace(with: selectedBanks)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if isSavingCards {
                RadarLoadingOverlay(
                    title: "İşlem yapılıyor",
                    message: "Kart tercihlerin kaydediliyor."
                )
                .allowsHitTesting(true)
                .transition(.opacity)
            }
        }
    }

    private func toggleLocalSelection(_ bank: String) {
        if selectedBanks.contains(bank) {
            selectedBanks.remove(bank)
        } else {
            selectedBanks.insert(bank)
        }
    }

    private func saveAndDismiss() {
        guard !isSavingCards else { return }
        isSavingCards = true
        didPersistSelection = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 90_000_000)
            guard !Task.isCancelled else { return }
            myCards.replace(with: selectedBanks)
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }
            dismiss()
            isSavingCards = false
        }
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
    let favorites: FavoritesStore
    let participation: ParticipationStore
    @Bindable var authState: AuthStateStore
    @State private var openingReminderCampaign: Campaign?
    @State private var isShowingRadarScan = false
    @State private var isShowingClearTrackedConfirmation = false
    @State private var radarScanTitle = "Radar taraması"
    @State private var radarScanMessage = "Hatırlatıcı detayı açılıyor."
    @State private var radarScanTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    private var reminderCampaigns: [(campaign: Campaign, record: CampaignParticipation)] {
        viewModel.campaigns.compactMap { campaign in
            guard let record = participation.records[campaign.id], record.hasReminder else { return nil }
            return (campaign, record)
        }
        .sorted {
            let firstDate = $0.record.rewardExpiresAt ?? .distantFuture
            let secondDate = $1.record.rewardExpiresAt ?? .distantFuture
            if firstDate != secondDate {
                return firstDate < secondDate
            }
            return $0.campaign.title.localizedCaseInsensitiveCompare($1.campaign.title) == .orderedAscending
        }
    }

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
                    remindersSection

                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center) {
                            Text("Takip edilen kampanyalar")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            Spacer()
                            if !trackedCampaigns.isEmpty {
                                Button {
                                    isShowingClearTrackedConfirmation = true
                                } label: {
                                    Label("Takiptekileri temizle", systemImage: "trash")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(AppTheme.dashboardGreen)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 9)
                                        .background(AppTheme.dashboardGreen.opacity(0.14))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }

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
        .overlay {
            ZStack {
                if isShowingClearTrackedConfirmation {
                    ThemedClearTrackedConfirmationOverlay(
                        clearAction: clearTrackedCampaigns,
                        cancelAction: { isShowingClearTrackedConfirmation = false }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                if isShowingRadarScan {
                    RadarLoadingOverlay(
                        title: radarScanTitle,
                        message: radarScanMessage
                    )
                    .allowsHitTesting(true)
                    .transition(.opacity)
                }
            }
        }
        .navigationDestination(item: $openingReminderCampaign) { campaign in
            CampaignDetailView(campaign: campaign, favorites: favorites, participation: participation, authState: authState)
                .onAppear {
                    stopReminderRadarScan()
                }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var earningsSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Özet")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Harcadığın tutara göre geri kazanım oranı")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(rewardReturnRateText)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.dashboardGreen)
                    Text("geri kazanım")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }
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

    private var rewardReturnRateText: String {
        guard participation.totalSpent > 0 else { return "%0" }
        let rate = (participation.totalEarned / participation.totalSpent) * 100
        let precision = rate < 10 && rate != floor(rate) ? 1 : 0
        return "%\(rate.formatted(.number.precision(.fractionLength(precision))))"
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hatırlatıcılarım")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(reminderCampaigns.count) aktif puan hatırlatıcısı")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
                Image(systemName: "bell.badge.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.dashboardGreen)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.dashboardGreen.opacity(0.14))
                    .clipShape(Circle())
            }

            if reminderCampaigns.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Aktif hatırlatıcı yok")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Bir kampanya detayında Katıldım ve puan son kullanım hatırlatıcısını açınca burada listelenecek.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.66))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(reminderCampaigns, id: \.campaign.id) { item in
                        Button {
                            openReminderCampaign(item.campaign)
                        } label: {
                            ReminderCampaignRow(campaign: item.campaign, record: item.record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(AppTheme.dashboardGreen.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.dashboardGreen.opacity(0.24), lineWidth: 1)
        }
    }

    private func openReminderCampaign(_ campaign: Campaign) {
        radarScanTitle = "Radar taraması"
        radarScanMessage = "Kampanya detayı açılıyor."
        isShowingRadarScan = true
        radarScanTask?.cancel()
        radarScanTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 60_000_000)
            guard !Task.isCancelled else { return }
            openingReminderCampaign = campaign
            try? await Task.sleep(nanoseconds: 320_000_000)
            guard !Task.isCancelled else { return }
            isShowingRadarScan = false
        }
    }

    private func stopReminderRadarScan() {
        radarScanTask?.cancel()
        radarScanTask = nil
        isShowingRadarScan = false
    }

    private func clearTrackedCampaigns() {
        isShowingClearTrackedConfirmation = false
        radarScanTitle = "İşlem yapılıyor"
        radarScanMessage = "Takip edilen kampanyalar temizleniyor."
        isShowingRadarScan = true
        radarScanTask?.cancel()
        let items = trackedCampaigns
        radarScanTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000)
            guard !Task.isCancelled else { return }
            let campaignIDs = Set(items.map { $0.campaign.id })
            for item in items where item.record.hasReminder {
                CampaignReminderService.cancelReminders(for: item.campaign)
            }
            participation.removeRecords(forCampaignIDs: campaignIDs)
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            isShowingRadarScan = false
        }
    }
}

private struct ThemedClearTrackedConfirmationOverlay: View {
    let clearAction: () -> Void
    let cancelAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .onTapGesture(perform: cancelAction)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "trash.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.dashboardGreen)
                        .frame(width: 46, height: 46)
                        .background(AppTheme.dashboardGreen.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Takiptekiler temizlensin mi?")
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white)
                        Text("Katılım, harcama, kazanç ve puan hatırlatıcı kayıtları bu cihazdan kaldırılacak.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    Button(action: cancelAction) {
                        Text("Vazgeç")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    Button(action: clearAction) {
                        Text("Temizle")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.nearBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.dashboardGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 360)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.11, blue: 0.10),
                        Color(red: 0.01, green: 0.05, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.dashboardGreen.opacity(0.32), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.34), radius: 24, x: 0, y: 14)
            .padding(.horizontal, 22)
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

private struct ReminderCampaignRow: View {
    let campaign: Campaign
    let record: CampaignParticipation

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.dashboardGreen.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "bell.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.dashboardGreen)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(campaign.displayBank)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.dashboardGreen)
                Text(campaign.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if let rewardExpiresAt = record.rewardExpiresAt {
                        Label(rewardExpiresAt.shortDateText, systemImage: "calendar")
                    }
                    Label(record.earnedAmount.currencyText, systemImage: "banknote")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.46))
                .padding(.top, 12)
        }
        .padding(16)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
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
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.panelBlack)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(AppTheme.borderSubtle, lineWidth: 1))
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
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(AppTheme.panelBlack)
                                    .clipShape(Circle())
                                    .overlay(Circle().strokeBorder(AppTheme.borderSubtle, lineWidth: 1))
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
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.panelBlack)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(AppTheme.borderSubtle, lineWidth: 1))
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

private extension View {
    @ViewBuilder
    func scrollToTopGeometryTracking(_ updateVisibility: @escaping (Bool) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            self.onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y > 80
            } action: { _, shouldShow in
                updateVisibility(shouldShow)
            }
        } else {
            self
        }
    }
}
