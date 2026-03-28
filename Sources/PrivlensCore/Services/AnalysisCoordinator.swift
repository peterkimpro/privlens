import Foundation

// MARK: - AnalysisProgress

/// Represents stages of the analysis pipeline.
public enum AnalysisProgress: Sendable {
    case checkingPaywall
    case chunkingText
    case analyzingChunks(current: Int, total: Int)
    case savingResults
    case complete
}

// MARK: - AnalysisCoordinatorError

public enum AnalysisCoordinatorError: Error, LocalizedError, Sendable {
    case analysisLimitReached(remaining: Int)
    case emptyDocumentText
    case analysisServiceFailed(String)

    public var errorDescription: String? {
        switch self {
        case .analysisLimitReached(let remaining):
            return "Analysis limit reached. Remaining this month: \(remaining). Upgrade to Pro for unlimited analyses."
        case .emptyDocumentText:
            return "The document has no text to analyze."
        case .analysisServiceFailed(let reason):
            return "AI analysis failed: \(reason)"
        }
    }
}

// MARK: - AnalysisCoordinatorProtocol

/// Protocol for the analysis pipeline coordinator.
public protocol AnalysisCoordinatorProtocol: Sendable {
    /// Run the full analysis pipeline for a document.
    func analyzeDocument(_ document: Document) async throws -> AnalysisResult
}

// MARK: - AnalysisCoordinator

public final class AnalysisCoordinator: AnalysisCoordinatorProtocol, Sendable {

    private let chunkingService: ChunkingServiceProtocol
    private let aiAnalysisService: AIAnalysisServiceProtocol
    private let storageService: StorageServiceProtocol
    private let paywallService: PaywallServiceProtocol
    private let onProgress: (@Sendable (AnalysisProgress) -> Void)?

    public init(
        chunkingService: ChunkingServiceProtocol,
        aiAnalysisService: AIAnalysisServiceProtocol,
        storageService: StorageServiceProtocol,
        paywallService: PaywallServiceProtocol,
        onProgress: (@Sendable (AnalysisProgress) -> Void)? = nil
    ) {
        self.chunkingService = chunkingService
        self.aiAnalysisService = aiAnalysisService
        self.storageService = storageService
        self.paywallService = paywallService
        self.onProgress = onProgress
    }

    public func analyzeDocument(_ document: Document) async throws -> AnalysisResult {
        // Step 1: Check paywall
        onProgress?(.checkingPaywall)

        let canAnalyze = await paywallService.canPerformAnalysis()
        guard canAnalyze else {
            let remaining = await paywallService.remainingFreeAnalyses()
            throw AnalysisCoordinatorError.analysisLimitReached(remaining: remaining)
        }

        // Step 2: Validate document text
        guard !document.rawText.isEmpty else {
            throw AnalysisCoordinatorError.emptyDocumentText
        }

        // Step 3: Chunk text
        onProgress?(.chunkingText)

        let chunks = chunkingService.chunkText(
            document.rawText,
            chunkSize: 4000,
            overlap: 200,
            sourcePageIndex: nil
        )

        // Step 4: Analyze chunks
        let totalChunks = chunks.count
        var allInsights: [Insight] = []

        for (index, chunk) in chunks.enumerated() {
            onProgress?(.analyzingChunks(current: index + 1, total: totalChunks))

            let chunkInsights = try await aiAnalysisService.analyzeChunk(
                chunk,
                documentType: document.documentType.rawValue
            )
            allInsights.append(contentsOf: chunkInsights)
        }

        // Step 5: Generate summary and build result
        let documentTypeString = document.documentType.rawValue
        let summary = try await aiAnalysisService.generateSummary(
            from: allInsights,
            documentContext: documentTypeString
        )

        let keyInsightStrings = allInsights
            .filter { $0.category != .risk && $0.category != .recommendation }
            .map { "\($0.title): \($0.description)" }

        let redFlagStrings = allInsights
            .filter { $0.category == .risk }
            .map { "\($0.title): \($0.description)" }

        let actionItemStrings = allInsights
            .filter { $0.category == .recommendation || $0.category == .obligation }
            .map { "\($0.title): \($0.description)" }

        let mergedResult = AnalysisResult(
            summary: summary,
            keyInsights: keyInsightStrings,
            redFlags: redFlagStrings,
            actionItems: actionItemStrings,
            documentType: document.documentType
        )

        // Step 6: Save results
        onProgress?(.savingResults)
        try await storageService.saveAnalysisResult(mergedResult, for: document.id)

        // Step 7: Record analysis usage
        await paywallService.recordAnalysis()

        onProgress?(.complete)

        return mergedResult
    }

}
