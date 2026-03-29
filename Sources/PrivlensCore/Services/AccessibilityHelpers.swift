import Foundation

// MARK: - AccessibilityLabels

/// Centralized accessibility label strings for VoiceOver support.
public enum AccessibilityLabels: Sendable {

    // MARK: - Scan Tab

    public static let scanButton = "Scan a new document"
    public static let scanFromCamera = "Scan document using camera"
    public static let scanFromPhotos = "Import document from Photos"
    public static let scanFromFiles = "Import document from Files"

    // MARK: - Analysis

    public static func analysisInProgress(chunksProcessed: Int, totalChunks: Int) -> String {
        "Analyzing document. Processing chunk \(chunksProcessed) of \(totalChunks)."
    }

    public static let analysisComplete = "Analysis complete"
    public static let analysisFailed = "Analysis failed"

    public static func summarySection(text: String) -> String {
        "Document summary. \(text)"
    }

    public static func redFlagCount(_ count: Int) -> String {
        "\(count) red flag\(count == 1 ? "" : "s") found"
    }

    public static func insightCount(_ count: Int) -> String {
        "\(count) key insight\(count == 1 ? "" : "s") found"
    }

    public static func actionItemCount(_ count: Int) -> String {
        "\(count) action item\(count == 1 ? "" : "s")"
    }

    public static func redFlag(text: String) -> String {
        "Red flag: \(text)"
    }

    public static func insight(text: String) -> String {
        "Key insight: \(text)"
    }

    public static func actionItem(number: Int, text: String) -> String {
        "Action item \(number): \(text)"
    }

    // MARK: - Document List

    public static func documentCell(title: String, type: String, date: String) -> String {
        "\(title). \(type). Scanned \(date)."
    }

    public static let deleteDocument = "Delete document"
    public static let moveToFolder = "Move to folder"

    // MARK: - Folders

    public static func folder(name: String, documentCount: Int) -> String {
        "\(name) folder. \(documentCount) document\(documentCount == 1 ? "" : "s")."
    }

    public static let createFolder = "Create new folder"
    public static let deleteFolder = "Delete folder"

    // MARK: - Paywall

    public static func trialStatus(daysRemaining: Int) -> String {
        "Pro trial. \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining."
    }

    public static func freeAnalysesRemaining(_ count: Int) -> String {
        "\(count) free \(count == 1 ? "analysis" : "analyses") remaining this month."
    }

    public static let upgradeToPro = "Upgrade to Pro for unlimited analyses"
    public static let restorePurchases = "Restore previous purchases"

    // MARK: - Comparison

    public static func comparisonSummary(similarityPercent: Int) -> String {
        "Documents are \(similarityPercent) percent similar."
    }

    public static func differenceCount(_ count: Int) -> String {
        "\(count) difference\(count == 1 ? "" : "s") found between documents."
    }

    public static func differenceItem(label: String) -> String {
        "Difference: \(label)"
    }

    // MARK: - Export

    public static let exportPDF = "Export analysis as PDF"
    public static let exportText = "Share analysis as text"
    public static let exportComparison = "Export comparison report"

    // MARK: - Search

    public static let searchDocuments = "Search across all documents"
    public static func searchResultCount(_ count: Int) -> String {
        "\(count) document\(count == 1 ? "" : "s") found."
    }

    // MARK: - Settings

    public static let settingsButton = "Settings"
    public static let privacyInfo = "All document processing happens on your device. No data is sent to any server."

    // MARK: - Privacy Indicator

    public static let onDeviceProcessing = "Processing on your device. No data leaves your iPhone."

    // MARK: - Document Types

    public static func documentType(_ type: String) -> String {
        "Document type: \(type)"
    }
}

// MARK: - AccessibilityIdentifiers

/// Centralized accessibility identifiers for UI testing.
public enum AccessibilityIdentifiers: Sendable {
    // Tabs
    public static let scanTab = "tab.scan"
    public static let documentsTab = "tab.documents"
    public static let settingsTab = "tab.settings"

    // Scan
    public static let scanCameraButton = "scan.camera"
    public static let scanPhotosButton = "scan.photos"
    public static let scanFilesButton = "scan.files"

    // Analysis
    public static let analysisProgressView = "analysis.progress"
    public static let analysisSummary = "analysis.summary"
    public static let analysisRedFlags = "analysis.redflags"
    public static let analysisInsights = "analysis.insights"
    public static let analysisActionItems = "analysis.actionitems"
    public static let analysisShareButton = "analysis.share"
    public static let analysisReanalyzeButton = "analysis.reanalyze"

    // Documents
    public static let documentList = "documents.list"
    public static let documentSearchField = "documents.search"
    public static let documentCell = "documents.cell"

    // Folders
    public static let folderList = "folders.list"
    public static let createFolderButton = "folders.create"

    // Paywall
    public static let paywallSheet = "paywall.sheet"
    public static let paywallUpgradeButton = "paywall.upgrade"
    public static let paywallRestoreButton = "paywall.restore"

    // Comparison
    public static let comparisonView = "comparison.view"
    public static let comparisonSummary = "comparison.summary"
    public static let comparisonDifferences = "comparison.differences"
    public static let comparisonSelectDocA = "comparison.selectDocA"
    public static let comparisonSelectDocB = "comparison.selectDocB"
    public static let comparisonRunButton = "comparison.run"

    // Export
    public static let exportPDFButton = "export.pdf"
    public static let exportShareButton = "export.share"

    // Search
    public static let searchView = "search.view"
    public static let searchField = "search.field"
    public static let searchResults = "search.results"

    // Settings
    public static let settingsProStatus = "settings.prostatus"
    public static let settingsPrivacy = "settings.privacy"

    // Onboarding
    public static let onboardingView = "onboarding.view"
    public static let onboardingContinueButton = "onboarding.continue"
    public static let onboardingSkipButton = "onboarding.skip"
}
