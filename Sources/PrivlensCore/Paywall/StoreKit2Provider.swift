import Foundation

#if canImport(StoreKit)
import StoreKit

/// Concrete ``PurchaseProviderProtocol`` backed by StoreKit 2.
/// Drop-in replacement target: swap this for a RevenueCat provider later.
public struct StoreKit2Provider: PurchaseProviderProtocol {

    private let productIDs: [String]

    public init(productIDs: [String] = PaywallManager.ProductID.allCases.map(\.rawValue)) {
        self.productIDs = productIDs
    }

    // MARK: - PurchaseProviderProtocol

    public func fetchProducts() async throws -> [ProductInfo] {
        let products = try await Product.products(for: productIDs)
            .sorted { $0.price < $1.price }
        return products.map { product in
            ProductInfo(
                id: product.id,
                displayName: product.displayName,
                displayPrice: product.displayPrice,
                price: product.price,
                productType: product.type == .autoRenewable || product.type == .nonRenewable
                    ? .subscription
                    : .nonConsumable
            )
        }
    }

    public func purchase(productId: String) async throws -> PurchaseResult {
        let products = try await Product.products(for: [productId])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try verify(verification)
            await transaction.finish()
            return .success

        case .userCancelled:
            return .cancelled

        case .pending:
            return .pending

        @unknown default:
            return .pending
        }
    }

    public func restorePurchases() async throws -> Bool {
        try? await AppStore.sync()
        return await checkEntitlement()
    }

    public func checkEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? verify(result),
               productIDs.contains(transaction.productID) {
                return true
            }
        }
        return false
    }

    // MARK: - Helpers

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors

public enum PurchaseError: Error, Sendable {
    case productNotFound
}

#endif
