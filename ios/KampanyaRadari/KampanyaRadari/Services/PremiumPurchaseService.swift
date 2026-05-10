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

    func restorePurchases() async {
        statusMessage = "Geri yükleme App Store ürünleri tanımlandıktan sonra aktif olacak."
    }

    private static var fallbackOfferings: [PremiumOffering] {
        PremiumProductID.allCases.map { id in
            PremiumOffering(
                id: id,
                title: id.fallbackTitle,
                subtitle: id.fallbackSubtitle,
                priceText: id.fallbackPriceText,
                isBestValue: id == .yearly,
                isStoreProductReady: false
            )
        }
    }
}
