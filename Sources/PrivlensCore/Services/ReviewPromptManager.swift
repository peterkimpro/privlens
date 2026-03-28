import Foundation

// MARK: - ReviewPromptManagerProtocol

/// Protocol for managing App Store review prompt timing.
public protocol ReviewPromptManagerProtocol: Sendable {
    /// Records a successful analysis completion.
    func recordSuccessfulAnalysis()

    /// Returns whether it is appropriate to show a review prompt now.
    func shouldRequestReview() -> Bool

    /// Records that a review prompt was shown.
    func recordReviewPromptShown()
}

// MARK: - ReviewPromptManager

/// Manages App Store review prompt timing based on user engagement.
///
/// Strategy: Prompt after the 2nd successful analysis, then at most once
/// every 90 days. This balances getting reviews with not annoying users.
public final class ReviewPromptManager: ReviewPromptManagerProtocol, @unchecked Sendable {

    private let lock = NSLock()

    /// Number of successful analyses before first prompt.
    public static let analysesBeforeFirstPrompt = 2

    /// Minimum days between review prompts.
    public static let minimumDaysBetweenPrompts = 90

    private let analysisCountKey: String
    private let lastPromptDateKey: String
    private let defaults: UserDefaults

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "privlens"
    ) {
        self.defaults = defaults
        self.analysisCountKey = "\(keyPrefix)_successful_analysis_count"
        self.lastPromptDateKey = "\(keyPrefix)_last_review_prompt_date"
    }

    public func recordSuccessfulAnalysis() {
        recordSuccessfulAnalysisSync()
    }

    public func shouldRequestReview() -> Bool {
        shouldRequestReviewSync()
    }

    public func recordReviewPromptShown() {
        recordReviewPromptShownSync()
    }

    /// Returns the total number of successful analyses recorded.
    public var successfulAnalysisCount: Int {
        getAnalysisCountSync()
    }

    // MARK: - Synchronous Lock-Protected Helpers

    private func recordSuccessfulAnalysisSync() {
        lock.lock()
        defer { lock.unlock() }
        let current = defaults.integer(forKey: analysisCountKey)
        defaults.set(current + 1, forKey: analysisCountKey)
    }

    private func shouldRequestReviewSync() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let analysisCount = defaults.integer(forKey: analysisCountKey)

        // Not enough analyses yet
        guard analysisCount >= Self.analysesBeforeFirstPrompt else {
            return false
        }

        // Check if we've shown a prompt recently
        if let lastPromptDate = defaults.object(forKey: lastPromptDateKey) as? Date {
            let daysSinceLastPrompt = Calendar.current.dateComponents(
                [.day], from: lastPromptDate, to: Date()
            ).day ?? 0
            if daysSinceLastPrompt < Self.minimumDaysBetweenPrompts {
                return false
            }
        }

        return true
    }

    private func recordReviewPromptShownSync() {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(Date(), forKey: lastPromptDateKey)
    }

    private func getAnalysisCountSync() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return defaults.integer(forKey: analysisCountKey)
    }
}
