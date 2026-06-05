import Foundation
import Observation
import StoreKit

enum PremiumProductID: String, CaseIterable, Identifiable {
    case monthly = "com.mericucan.KampanyaRadari.premium.monthly"
    case yearly = "com.mericucan.KampanyaRadari.premium.yearly"

    var id: String { rawValue }

    var fallbackTitle: String {
        switch self {
        case .monthly: return "Aylık Premium"
        case .yearly: return "Yıllık Premium"
        }
    }

    var fallbackSubtitle: String {
        switch self {
        case .monthly: return "Esnek deneme için aylık plan"
        case .yearly: return "Daha uygun uzun dönem plan"
        }
    }

    var fallbackDurationText: String {
        switch self {
        case .monthly: return "Aylık"
        case .yearly: return "Yıllık"
        }
    }

    var fallbackPriceText: String {
        switch self {
        case .monthly: return "App Store'da tanımlanacak"
        case .yearly: return "App Store'da tanımlanacak"
        }
    }
}

struct PremiumOffering: Identifiable, Equatable {
    let id: PremiumProductID
    let title: String
    let subtitle: String
    let durationText: String
    let priceText: String
    let isBestValue: Bool
    let isStoreProductReady: Bool
}

@MainActor
@Observable
final class PremiumPurchaseService {
    private(set) var offerings: [PremiumOffering] = PremiumPurchaseService.fallbackOfferings
    private(set) var isLoading = false
    private(set) var statusMessage: String?
    var selectedProductID: PremiumProductID = .yearly

    private var storeProducts: [PremiumProductID: Product] = [:]

    var hasStoreProducts: Bool {
        !storeProducts.isEmpty
    }

    func loadOfferings() async {
        isLoading = true
        statusMessage = nil
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: PremiumProductID.allCases.map(\.rawValue))
            storeProducts = Dictionary(
                uniqueKeysWithValues: products.compactMap { product in
                    guard let id = PremiumProductID(rawValue: product.id) else { return nil }
                    return (id, product)
                }
            )
            offerings = PremiumProductID.allCases.map { id in
                let product = storeProducts[id]
                return PremiumOffering(
                    id: id,
                    title: product?.displayName.isEmpty == false ? product!.displayName : id.fallbackTitle,
                    subtitle: id.fallbackSubtitle,
                    durationText: product?.subscription?.subscriptionPeriod.localizedDurationText ?? id.fallbackDurationText,
                    priceText: product?.displayPrice ?? id.fallbackPriceText,
                    isBestValue: id == .yearly,
                    isStoreProductReady: product != nil
                )
            }

            if storeProducts.isEmpty {
                statusMessage = "App Store ürünleri henüz tanımlı değil. Ürünler App Store Connect'te açılınca bu ekran satın almaya hazır olacak."
            }
        } catch {
            offerings = Self.fallbackOfferings
            statusMessage = "Premium ürünleri şu an yüklenemedi. App Store Connect kurulumu tamamlanınca tekrar denenecek."
        }
    }

    func select(_ offering: PremiumOffering) {
        selectedProductID = offering.id
    }

    func purchaseSelectedOffering() async -> Bool {
        guard let product = storeProducts[selectedProductID] ?? storeProducts.values.first else {
            statusMessage = "App Store ürünü henüz hazır değil. Ürünler App Store Connect'te açılınca satın alma test edilecek."
            return false
        }

        isLoading = true
        statusMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                statusMessage = "Satın alma başarılı. Premium hakların bu oturumda açıldı."
                return true
            case .userCancelled:
                statusMessage = "Satın alma iptal edildi."
                return false
            case .pending:
                statusMessage = "Satın alma beklemede. App Store onayı tamamlanınca tekrar kontrol edilecek."
                return false
            @unknown default:
                statusMessage = "Satın alma sonucu beklenmeyen bir durum döndürdü."
                return false
            }
        } catch {
            statusMessage = "Satın alma tamamlanamadı: \(readableMessage(from: error))"
            return false
        }
    }

    func restorePurchases() async -> Bool {
        guard hasStoreProducts else {
            statusMessage = "Geri yükleme App Store ürünleri tanımlandıktan sonra aktif olacak."
            return false
        }

        isLoading = true
        statusMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            let activeIDs = await currentPremiumProductIDs()
            if activeIDs.isEmpty {
                statusMessage = "Geri yüklenecek aktif Premium abonelik bulunamadı."
                return false
            }
            statusMessage = "Satın alma geri yüklendi. Premium hakların bu oturumda açıldı."
            return true
        } catch {
            statusMessage = "Geri yükleme tamamlanamadı: \(readableMessage(from: error))"
            return false
        }
    }

    func currentPremiumProductIDs() async -> Set<PremiumProductID> {
        var ids = Set<PremiumProductID>()
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  let productID = PremiumProductID(rawValue: transaction.productID) else {
                continue
            }
            ids.insert(productID)
        }
        return ids
    }

    func listenForTransactionUpdates(onEntitlementsChanged: @escaping @MainActor (Set<PremiumProductID>) -> Void) async {
        for await result in Transaction.updates {
            guard let transaction = try? checkVerified(result) else {
                continue
            }
            await transaction.finish()
            let activeIDs = await currentPremiumProductIDs()
            onEntitlementsChanged(activeIDs)
        }
    }

    private static var fallbackOfferings: [PremiumOffering] {
        PremiumProductID.allCases.map { id in
            PremiumOffering(
                id: id,
                title: id.fallbackTitle,
                subtitle: id.fallbackSubtitle,
                durationText: id.fallbackDurationText,
                priceText: id.fallbackPriceText,
                isBestValue: id == .yearly,
                isStoreProductReady: false
            )
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw PremiumPurchaseError.unverifiedTransaction
        }
    }

    private func readableMessage(from error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

private enum PremiumPurchaseError: LocalizedError {
    case unverifiedTransaction

    var errorDescription: String? {
        switch self {
        case .unverifiedTransaction:
            return "App Store işlemi doğrulanamadı."
        }
    }
}

private extension Product.SubscriptionPeriod {
    var localizedDurationText: String {
        switch unit {
        case .day:
            return value == 1 ? "Günlük" : "\(value) günlük"
        case .week:
            return value == 1 ? "Haftalık" : "\(value) haftalık"
        case .month:
            return value == 1 ? "Aylık" : "\(value) aylık"
        case .year:
            return value == 1 ? "Yıllık" : "\(value) yıllık"
        @unknown default:
            return "\(value) dönem"
        }
    }
}
