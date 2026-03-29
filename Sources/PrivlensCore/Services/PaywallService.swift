import Foundation

// MARK: - SubscriptionTier

public enum SubscriptionTier: String, Codable, Sendable {
    case free
    case pro
    case proPlus
}

// MARK: - PaywallError

public enum PaywallError: Error, LocalizedError, Sendable {
    case analysisLimitReached(remaining: Int)

    public var errorDescription: String? {
        switch self {
        case .analysisLimitReached:
            return "You've reached your free analysis limit for this month. Upgrade to Pro for unlimited analyses."
        }
    }
}

// MARK: - UsageRecord

/// Tracks monthly usage for paywall enforcement.
struct UsageRecord: Codable, Sendable {
    let analysisCount: Int
    let monthYear: String

    init(analysisCount: Int, monthYear: String) {
        self.analysisCount = analysisCount
        self.monthYear = monthYear
    }
}

// MARK: - PaywallServiceProtocol

/// Protocol for paywall gating of AI analysis.
public protocol PaywallServiceProtocol: Sendable {
    /// Check if the user can perform an analysis given their tier and usage.
    func canPerformAnalysis() async -> Bool

    /// Record that an analysis was performed, incrementing the monthly counter.
    func recordAnalysis() async

    /// Get the number of remaining free analyses this month.
    func remainingFreeAnalyses() async -> Int

    /// The current subscription tier.
    var currentTier: SubscriptionTier { get }
}

// MARK: - PaywallService

public final class PaywallService: PaywallServiceProtocol, @unchecked Sendable {

    public static let freeMonthlyLimit: Int = 3

    public let currentTier: SubscriptionTier

    private let usageFilePath: String
    private let lock = NSLock()

    public init(tier: SubscriptionTier = .free) {
        self.currentTier = tier

        #if canImport(UIKit)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first ?? NSTemporaryDirectory()
        self.usageFilePath = documentsPath + "/PrivlensUsage/usage.json"
        #elseif canImport(AppKit)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first ?? NSTemporaryDirectory()
        self.usageFilePath = documentsPath + "/PrivlensUsage/usage.json"
        #else
        self.usageFilePath = "/tmp/PrivlensUsage/usage.json"
        #endif
    }

    /// Initialize with a custom usage file path (useful for testing).
    public init(tier: SubscriptionTier, usageFilePath: String) {
        self.currentTier = tier
        self.usageFilePath = usageFilePath
    }

    /// Whether the current tier is any paid tier (Pro or Pro+).
    public var isPaid: Bool {
        currentTier == .pro || currentTier == .proPlus
    }

    /// Whether the current tier supports comparison features (Pro+ only).
    public var supportsComparison: Bool {
        currentTier == .proPlus
    }

    public func canPerformAnalysis() async -> Bool {
        if isPaid {
            return true
        }
        let remaining = await remainingFreeAnalyses()
        return remaining > 0
    }

    public func recordAnalysis() async {
        if isPaid {
            return
        }
        recordAnalysisSync()
    }

    public func remainingFreeAnalyses() async -> Int {
        if isPaid {
            return Int.max
        }
        return remainingFreeAnalysesSync()
    }

    // MARK: - Synchronous Lock-Protected Helpers

    private func recordAnalysisSync() {
        lock.lock()
        defer { lock.unlock() }

        let currentMonthYear = Self.currentMonthYear()
        var record = loadUsageRecord()

        if record.monthYear == currentMonthYear {
            record = UsageRecord(
                analysisCount: record.analysisCount + 1,
                monthYear: currentMonthYear
            )
        } else {
            record = UsageRecord(
                analysisCount: 1,
                monthYear: currentMonthYear
            )
        }

        saveUsageRecord(record)
    }

    private func remainingFreeAnalysesSync() -> Int {
        lock.lock()
        defer { lock.unlock() }

        let currentMonthYear = Self.currentMonthYear()
        let record = loadUsageRecord()

        if record.monthYear != currentMonthYear {
            return Self.freeMonthlyLimit
        }

        return max(0, Self.freeMonthlyLimit - record.analysisCount)
    }

    // MARK: - Private Helpers

    private static func currentMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private func loadUsageRecord() -> UsageRecord {
        let url = URL(fileURLWithPath: usageFilePath)

        guard FileManager.default.fileExists(atPath: usageFilePath),
              let data = try? Data(contentsOf: url),
              let record = try? JSONDecoder().decode(UsageRecord.self, from: data) else {
            return UsageRecord(analysisCount: 0, monthYear: Self.currentMonthYear())
        }

        return record
    }

    private func saveUsageRecord(_ record: UsageRecord) {
        let url = URL(fileURLWithPath: usageFilePath)
        let directory = url.deletingLastPathComponent().path

        if !FileManager.default.fileExists(atPath: directory) {
            try? FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        if let data = try? JSONEncoder().encode(record) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
