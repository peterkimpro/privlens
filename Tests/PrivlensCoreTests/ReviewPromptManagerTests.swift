import Foundation
import Testing
@testable import PrivlensCore

@Suite("ReviewPromptManager Tests")
struct ReviewPromptManagerTests {

    /// Creates a fresh UserDefaults suite for test isolation.
    private static func freshDefaults() -> UserDefaults {
        let suiteName = "com.privlens.test.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    @Test("Should not request review with zero analyses")
    func noReviewWithZeroAnalyses() {
        let defaults = Self.freshDefaults()
        let manager = ReviewPromptManager(defaults: defaults, keyPrefix: "test")

        #expect(manager.shouldRequestReview() == false)
    }

    @Test("Should not request review with one analysis")
    func noReviewWithOneAnalysis() {
        let defaults = Self.freshDefaults()
        let manager = ReviewPromptManager(defaults: defaults, keyPrefix: "test")

        manager.recordSuccessfulAnalysis()
        #expect(manager.shouldRequestReview() == false)
    }

    @Test("Should request review after threshold analyses")
    func requestReviewAfterThreshold() {
        let defaults = Self.freshDefaults()
        let manager = ReviewPromptManager(defaults: defaults, keyPrefix: "test")

        for _ in 0..<ReviewPromptManager.analysesBeforeFirstPrompt {
            manager.recordSuccessfulAnalysis()
        }

        #expect(manager.shouldRequestReview() == true)
    }

    @Test("Should not request review again immediately after prompt shown")
    func noReviewAfterPromptShown() {
        let defaults = Self.freshDefaults()
        let manager = ReviewPromptManager(defaults: defaults, keyPrefix: "test")

        for _ in 0..<ReviewPromptManager.analysesBeforeFirstPrompt {
            manager.recordSuccessfulAnalysis()
        }

        #expect(manager.shouldRequestReview() == true)

        manager.recordReviewPromptShown()
        #expect(manager.shouldRequestReview() == false)
    }

    @Test("Successful analysis count increments correctly")
    func analysisCountIncrements() {
        let defaults = Self.freshDefaults()
        let manager = ReviewPromptManager(defaults: defaults, keyPrefix: "test")

        #expect(manager.successfulAnalysisCount == 0)
        manager.recordSuccessfulAnalysis()
        #expect(manager.successfulAnalysisCount == 1)
        manager.recordSuccessfulAnalysis()
        #expect(manager.successfulAnalysisCount == 2)
    }

    @Test("Count persists across manager instances")
    func countPersistsAcrossInstances() {
        let defaults = Self.freshDefaults()

        let manager1 = ReviewPromptManager(defaults: defaults, keyPrefix: "test")
        manager1.recordSuccessfulAnalysis()
        manager1.recordSuccessfulAnalysis()

        let manager2 = ReviewPromptManager(defaults: defaults, keyPrefix: "test")
        #expect(manager2.successfulAnalysisCount == 2)
    }
}
