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
    public static let trialDurationDays = 7

    // MARK: - State

    public private(set) var products: [Product] = []
    public private(set) var hasPurchase: Bool = false
    public private(set) var freeAnalysesUsed: Int = 0
    public private(set) var purchaseError: String?

    private let freeAnalysesKey = "privlens_free_analyses_used"
    private let freeAnalysesMonthKey = "privlens_free_analyses_month"
    private let installDateKey = "privlens_install_date"

    // MARK: - Reverse Trial

    /// The date the app was first launched. Persisted in UserDefaults.
    public var installDate: Date {
        if let stored = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            return stored
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: installDateKey)
        return now
    }

    /// The date the 7-day reverse trial ends, or nil if the user has a purchase.
    public var trialEndDate: Date? {
        guard !hasPurchase else { return nil }
        return Calendar.current.date(byAdding: .day, value: Self.trialDurationDays, to: installDate)
    }

    /// Whether the user is currently within the 7-day reverse trial window.
    public var isInTrial: Bool {
        guard let end = trialEndDate else { return false }
        return Date() < end
    }

    /// Number of full days remaining in the trial (0 when expired or purchased).
    public var trialDaysRemaining: Int {
        guard let end = trialEndDate else { return 0 }
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(0, remaining)
    }

    /// User is Pro if they have a valid purchase OR are within the reverse trial.
    public var isPro: Bool {
        hasPurchase || isInTrial
    }

    // MARK: - Computed Properties

    public var remainingFreeAnalyses: Int {
        max(0, Self.freeAnalysesPerMonth - freeAnalysesUsed)
    }

    /// User can analyze if Pro (purchased or trial) OR has remaining free analyses.
    public var canAnalyze: Bool {
        isPro || remainingFreeAnalyses > 0
    }

    // MARK: - Init

    public init() {
        // Touch installDate to ensure it is persisted on first launch.
        _ = installDate
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
            hasPurchase = true
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
        hasPurchase = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                let productIDs = ProductID.allCases.map(\.rawValue)
                if productIDs.contains(transaction.productID) {
                    hasPurchase = true
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

// MARK: - Linux / Non-Apple Stub

/// Stub for non-Apple platforms. Mirrors the full public API surface.
public final class PaywallManager: Sendable {
    public static let freeAnalysesPerMonth = 3
    public static let trialDurationDays = 7

    private let installDateKey = "privlens_install_date"

    public var installDate: Date {
        if let stored = UserDefaults.standard.object(forKey: installDateKey) as? Date {
            return stored
        }
        let now = Date()
        UserDefaults.standard.set(now, forKey: installDateKey)
        return now
    }

    public var trialEndDate: Date? {
        Calendar.current.date(byAdding: .day, value: Self.trialDurationDays, to: installDate)
    }

    public var isInTrial: Bool {
        guard let end = trialEndDate else { return false }
        return Date() < end
    }

    public var trialDaysRemaining: Int {
        guard let end = trialEndDate else { return 0 }
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(0, remaining)
    }

    public var hasPurchase: Bool { false }
    public var isPro: Bool { hasPurchase || isInTrial }
    public var remainingFreeAnalyses: Int { Self.freeAnalysesPerMonth }
    public var canAnalyze: Bool { isPro || remainingFreeAnalyses > 0 }

    public init() {
        _ = installDate
    }

    public func checkProStatusSync() -> Bool { isPro }
    public func recordAnalysis() {}
}

#endif
