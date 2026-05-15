import SwiftUI

struct CampaignDetailView: View {
    let campaign: Campaign
    @Bindable var favorites: FavoritesStore
    @Bindable var participation: ParticipationStore
    @Bindable var authState: AuthStateStore
    @State private var record = CampaignParticipation()
    @State private var spentText = ""
    @State private var earnedText = ""
    @State private var rewardExpiresAt = Date()
    @State private var hasRewardReminder = false
    @State private var entitlementPrompt: EntitlementRule?
    @State private var pendingMoneySaveTask: Task<Void, Never>?

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
                                .foregroundStyle(AppTheme.dashboardGreen)
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

                        participationPanel

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
                            .tint(AppTheme.dashboardGreen)

                            if let sourceURL = campaign.sourceURL {
                                Link(destination: sourceURL) {
                                    Label("Kaynak", systemImage: "safari")
                                        .font(.subheadline.weight(.bold))
                                }
                                .buttonStyle(.bordered)
                                .tint(AppTheme.dashboardGreen)
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
        .onAppear {
            loadParticipation()
        }
        .onDisappear {
            pendingMoneySaveTask?.cancel()
            saveMoneyFields()
        }
        .navigationTitle("Detay")
        .overlay {
            if let entitlementPrompt {
                EntitlementPromptOverlay(rule: entitlementPrompt) {
                    self.entitlementPrompt = nil
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: entitlementPrompt)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var participationPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kampanya takibi")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text("Katılım, harcama ve kazancını burada tut.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
                Toggle("", isOn: joinedBinding)
                    .labelsHidden()
                    .tint(AppTheme.dashboardGreen)
            }

            VStack(spacing: 10) {
                MoneyInputRow(title: "Harcadım", text: $spentText) {
                    scheduleMoneySave()
                }
                MoneyInputRow(title: "Kazandım", text: $earnedText) {
                    scheduleMoneySave()
                }
            }

            rewardReminderPanel

            HStack(spacing: 12) {
                DetailStatPill(title: "Durum", value: record.didJoin ? "Katıldım" : "Takipte")
                DetailStatPill(title: "Hatırlatma", value: record.hasReminder ? "Açık" : "Kapalı")
            }
        }
        .padding(16)
        .background(AppTheme.softGreen.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var joinedBinding: Binding<Bool> {
        Binding {
            record.didJoin
        } set: { newValue in
            record.didJoin = newValue
            if !newValue {
                hasRewardReminder = false
                record.rewardExpiresAt = nil
            } else if hasRewardReminder {
                record.rewardExpiresAt = rewardExpiresAt
            }
            participation.update(record, for: campaign)
            CampaignReminderService.syncReminder(for: campaign, record: record)
        }
    }

    private func loadParticipation() {
        record = participation.record(for: campaign)
        spentText = record.spentAmount.moneyInputText
        earnedText = record.earnedAmount.moneyInputText
        hasRewardReminder = record.rewardExpiresAt != nil
        rewardExpiresAt = record.rewardExpiresAt ?? defaultRewardExpiryDate
    }

    private func saveMoneyFields() {
        record.spentAmount = Double(spentText.replacingOccurrences(of: ",", with: ".")) ?? 0
        record.earnedAmount = Double(earnedText.replacingOccurrences(of: ",", with: ".")) ?? 0
        participation.update(record, for: campaign)
        if record.hasReminder {
            CampaignReminderService.syncReminder(for: campaign, record: record)
        }
    }

    private func scheduleMoneySave() {
        pendingMoneySaveTask?.cancel()
        pendingMoneySaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled else { return }
            saveMoneyFields()
        }
    }

    private var rewardReminderPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: reminderBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Puan harcama hatırlatıcısı")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text("Katıldım seçiliyken son kullanımdan 7 gün, 3 gün ve son gün önce bildirim gönderirim.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .tint(AppTheme.dashboardGreen)

            if hasRewardReminder {
                DatePicker(
                    "Son kullanım",
                    selection: rewardDateBinding,
                    in: Date()...,
                    displayedComponents: .date
                )
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .padding(12)
                .background(.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Text(EntitlementService.reminderAllowanceText(plan: authState.plan, participation: participation))
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.dashboardGreen)
        }
        .padding(12)
        .background(.white.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var reminderBinding: Binding<Bool> {
        Binding {
            hasRewardReminder
        } set: { newValue in
            if newValue {
                let rule = EntitlementService.canUseRewardReminder(
                    plan: authState.plan,
                    participation: participation,
                    campaignID: campaign.id
                )
                guard rule.allowed else {
                    hasRewardReminder = false
                    entitlementPrompt = rule
                    return
                }
            }
            hasRewardReminder = newValue
            if newValue {
                record.didJoin = true
                record.rewardExpiresAt = rewardExpiresAt
            } else {
                record.rewardExpiresAt = nil
            }
            participation.update(record, for: campaign)
            CampaignReminderService.syncReminder(for: campaign, record: record)
        }
    }

    private var rewardDateBinding: Binding<Date> {
        Binding {
            rewardExpiresAt
        } set: { newValue in
            rewardExpiresAt = newValue
            record.rewardExpiresAt = newValue
            participation.update(record, for: campaign)
            CampaignReminderService.syncReminder(for: campaign, record: record)
        }
    }

    private var defaultRewardExpiryDate: Date {
        Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppTheme.softGreen)
            .overlay {
                Image(systemName: "creditcard")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.dashboardGreen)
            }
    }
}

private struct MoneyInputRow: View {
    let title: String
    @Binding var text: String
    let onChange: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: 120)
                .onChange(of: text) { _, _ in
                    onChange()
                }
            Text("TL")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(12)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DetailStatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct EntitlementPromptOverlay: View {
    let rule: EntitlementRule
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppTheme.dashboardGreen)

                Text(rule.title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)

                Text(rule.message)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: dismiss) {
                    Text("Anladım")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.dashboardGreen)
                        .foregroundStyle(AppTheme.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .frame(maxWidth: 320)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 22, x: 0, y: 12)
            .padding(.horizontal, 26)
        }
    }
}
