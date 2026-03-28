import Foundation

#if canImport(StoreKit)
import StoreKit

/// Manages in-app purchases and pro subscription status using StoreKit 2.
@MainActor
@Observable
public final class PaywallManager {

    // MARK: - Product Identifiers

    public enum ProductID: String, CaseIterable, Sendable {
        case monthly = "com.privlens.pro.monthly"
        case annual = "com.privlens.pro.annual"
        case lifetime = "com.privlens.pro.lifetime"

        public var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual: return "Annual"
            case .lifetime: return "Lifetime"
            }
        }

        public var price: String {
            switch self {
            case .monthly: return "$4.99/mo"
            case .annual: return "$29.99/yr"
            case .lifetime: return "$49.99"
            }
        }
    }

    // MARK: - Constants

    public static let freeAnalysesPerMonth = 3

    // MARK: - State

    public private(set) var products: [Product] = []
    public private(set) var isPro: Bool = false
    public private(set) var freeAnalysesUsed: Int = 0
    public private(set) var purchaseError: String?

    private let freeAnalysesKey = "privlens_free_analyses_used"
    private let freeAnalysesMonthKey = "privlens_free_analyses_month"

    // MARK: - Computed Properties

    public var remainingFreeAnalyses: Int {
        max(0, Self.freeAnalysesPerMonth - freeAnalysesUsed)
    }

    public var canAnalyze: Bool {
        isPro || remainingFreeAnalyses > 0
    }

    // MARK: - Init

    public init() {
        loadFreeAnalysesCount()
    }

    // MARK: - Product Loading

    public func loadProducts() async {
        do {
            let ids = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            purchaseError = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    public func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isPro = true
            purchaseError = nil

        case .userCancelled:
            break

        case .pending:
            purchaseError = "Purchase is pending approval."

        @unknown default:
            purchaseError = "An unexpected purchase result occurred."
        }
    }

    // MARK: - Restore

    public func restorePurchases() async {
        try? await AppStore.sync()
        await checkProStatus()
    }

    // MARK: - Status Check

    public func checkProStatus() async {
        isPro = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                let productIDs = ProductID.allCases.map(\.rawValue)
                if productIDs.contains(transaction.productID) {
                    isPro = true
                    return
                }
            }
        }
    }

    /// Checks whether the user is currently a Pro subscriber.
    /// Synchronous accessor that returns the cached value.
    public func checkProStatusSync() -> Bool {
        return isPro
    }

    // MARK: - Free Tier Tracking

    public func recordAnalysis() {
        guard !isPro else { return }
        resetMonthlyCountIfNeeded()
        freeAnalysesUsed += 1
        saveFreeAnalysesCount()
    }

    private func loadFreeAnalysesCount() {
        resetMonthlyCountIfNeeded()
        freeAnalysesUsed = UserDefaults.standard.integer(forKey: freeAnalysesKey)
    }

    private func saveFreeAnalysesCount() {
        UserDefaults.standard.set(freeAnalysesUsed, forKey: freeAnalysesKey)
    }

    private func resetMonthlyCountIfNeeded() {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        let stored = UserDefaults.standard.integer(forKey: freeAnalysesMonthKey)

        let storedCombined = stored
        let currentCombined = currentYear * 100 + currentMonth

        if storedCombined != currentCombined {
            freeAnalysesUsed = 0
            UserDefaults.standard.set(currentCombined, forKey: freeAnalysesMonthKey)
            UserDefaults.standard.set(0, forKey: freeAnalysesKey)
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}

#else

// Stub for non-Apple platforms
public final class PaywallManager: Sendable {
    public static let freeAnalysesPerMonth = 3

    public var isPro: Bool { false }
    public var remainingFreeAnalyses: Int { Self.freeAnalysesPerMonth }
    public var canAnalyze: Bool { true }

    public init() {}

    public func checkProStatusSync() -> Bool { false }
    public func recordAnalysis() {}
}
#endif
