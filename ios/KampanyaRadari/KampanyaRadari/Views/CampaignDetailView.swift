import SwiftUI

struct CampaignDetailView: View {
    let campaign: Campaign
    @Bindable var favorites: FavoritesStore
    @Bindable var participation: ParticipationStore
    @State private var record = CampaignParticipation()
    @State private var spentText = ""
    @State private var earnedText = ""

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
        .navigationTitle("Detay")
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
                    saveMoneyFields()
                }
                MoneyInputRow(title: "Kazandım", text: $earnedText) {
                    saveMoneyFields()
                }
            }

            HStack(spacing: 12) {
                DetailStatPill(title: "Durum", value: record.didJoin ? "Katıldım" : "Takipte")
                DetailStatPill(title: "Net", value: (record.earnedAmount - record.spentAmount).currencyText)
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
            participation.update(record, for: campaign)
        }
    }

    private func loadParticipation() {
        record = participation.record(for: campaign)
        spentText = record.spentAmount.moneyInputText
        earnedText = record.earnedAmount.moneyInputText
    }

    private func saveMoneyFields() {
        record.spentAmount = Double(spentText.replacingOccurrences(of: ",", with: ".")) ?? 0
        record.earnedAmount = Double(earnedText.replacingOccurrences(of: ",", with: ".")) ?? 0
        participation.update(record, for: campaign)
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
