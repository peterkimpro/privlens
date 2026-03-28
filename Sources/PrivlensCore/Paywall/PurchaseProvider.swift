import Foundation

// MARK: - Purchase Provider Protocol

/// Abstraction over StoreKit 2 / RevenueCat for purchasing.
/// Allows swapping the concrete implementation without touching view-layer code.
public protocol PurchaseProviderProtocol: Sendable {
    func fetchProducts() async throws -> [ProductInfo]
    func purchase(productId: String) async throws -> PurchaseResult
    func restorePurchases() async throws -> Bool
    func checkEntitlement() async -> Bool
}

// MARK: - Supporting Types

public struct ProductInfo: Sendable, Identifiable {
    public let id: String
    public let displayName: String
    public let displayPrice: String
    public let price: Decimal
    public let productType: ProductType

    public enum ProductType: Sendable {
        case subscription
        case nonConsumable
    }

    public init(
        id: String,
        displayName: String,
        displayPrice: String,
        price: Decimal,
        productType: ProductType
    ) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.price = price
        self.productType = productType
    }
}

public enum PurchaseResult: Sendable {
    case success
    case cancelled
    case pending
}

// MARK: - Linux Stub

#if !canImport(StoreKit)

/// No-op provider for Linux / non-Apple platforms.
public struct StubPurchaseProvider: PurchaseProviderProtocol {
    public init() {}

    public func fetchProducts() async throws -> [ProductInfo] { [] }
    public func purchase(productId: String) async throws -> PurchaseResult { .cancelled }
    public func restorePurchases() async throws -> Bool { false }
    public func checkEntitlement() async -> Bool { false }
}

#endif
