import Foundation
import Testing
@testable import PrivlensCore

@Suite("AccessibilityHelpers Tests")
struct AccessibilityHelpersTests {

    // MARK: - AccessibilityLabels

    @Test("Analysis progress label includes counts")
    func analysisProgressLabel() {
        let label = AccessibilityLabels.analysisInProgress(chunksProcessed: 3, totalChunks: 10)
        #expect(label.contains("3"))
        #expect(label.contains("10"))
    }

    @Test("Red flag count label is grammatically correct")
    func redFlagCountLabel() {
        let singular = AccessibilityLabels.redFlagCount(1)
        #expect(singular.contains("1 red flag"))
        #expect(!singular.contains("flags"))

        let plural = AccessibilityLabels.redFlagCount(3)
        #expect(plural.contains("3 red flags"))
    }

    @Test("Insight count label is grammatically correct")
    func insightCountLabel() {
        let singular = AccessibilityLabels.insightCount(1)
        #expect(singular.contains("1 key insight"))
        #expect(!singular.contains("insights"))

        let plural = AccessibilityLabels.insightCount(5)
        #expect(plural.contains("5 key insights"))
    }

    @Test("Action item count label is grammatically correct")
    func actionItemCountLabel() {
        let singular = AccessibilityLabels.actionItemCount(1)
        #expect(singular.contains("1 action item"))
        #expect(!singular.contains("items"))

        let plural = AccessibilityLabels.actionItemCount(4)
        #expect(plural.contains("4 action items"))
    }

    @Test("Document cell label includes all info")
    func documentCellLabel() {
        let label = AccessibilityLabels.documentCell(
            title: "Lease Agreement",
            type: "Lease",
            date: "March 2026"
        )
        #expect(label.contains("Lease Agreement"))
        #expect(label.contains("Lease"))
        #expect(label.contains("March 2026"))
    }

    @Test("Folder label includes document count")
    func folderLabel() {
        let singular = AccessibilityLabels.folder(name: "Medical", documentCount: 1)
        #expect(singular.contains("Medical"))
        #expect(singular.contains("1 document"))

        let plural = AccessibilityLabels.folder(name: "Bills", documentCount: 5)
        #expect(plural.contains("5 documents"))
    }

    @Test("Trial status label includes days")
    func trialStatusLabel() {
        let label = AccessibilityLabels.trialStatus(daysRemaining: 5)
        #expect(label.contains("5"))
        #expect(label.contains("days"))
    }

    @Test("Free analyses remaining label")
    func freeAnalysesLabel() {
        let singular = AccessibilityLabels.freeAnalysesRemaining(1)
        #expect(singular.contains("1 free analysis"))

        let plural = AccessibilityLabels.freeAnalysesRemaining(3)
        #expect(plural.contains("3 free analyses"))
    }

    // MARK: - AccessibilityIdentifiers

    @Test("All identifiers are non-empty strings")
    func identifiersAreNonEmpty() {
        #expect(!AccessibilityIdentifiers.scanTab.isEmpty)
        #expect(!AccessibilityIdentifiers.documentsTab.isEmpty)
        #expect(!AccessibilityIdentifiers.settingsTab.isEmpty)
        #expect(!AccessibilityIdentifiers.analysisSummary.isEmpty)
        #expect(!AccessibilityIdentifiers.analysisRedFlags.isEmpty)
        #expect(!AccessibilityIdentifiers.analysisInsights.isEmpty)
        #expect(!AccessibilityIdentifiers.analysisActionItems.isEmpty)
        #expect(!AccessibilityIdentifiers.onboardingView.isEmpty)
        #expect(!AccessibilityIdentifiers.paywallSheet.isEmpty)
    }

    @Test("Identifiers use consistent naming convention")
    func identifiersUseConsistentNaming() {
        // All identifiers should use dot-separated format
        #expect(AccessibilityIdentifiers.scanTab.contains("."))
        #expect(AccessibilityIdentifiers.documentsTab.contains("."))
        #expect(AccessibilityIdentifiers.analysisSummary.contains("."))
        #expect(AccessibilityIdentifiers.paywallSheet.contains("."))
    }
}
