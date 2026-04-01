import Foundation

// MARK: - AnalysisProgress

/// Represents stages of the analysis pipeline.
public enum AnalysisProgress: Sendable {
    case chunkingText
    case analyzingChunks(current: Int, total: Int)
    case savingResults
    case complete
}

// MARK: - AnalysisCoordinatorError

public enum AnalysisCoordinatorError: Error, LocalizedError, Sendable {
    case emptyDocumentText
    case analysisServiceFailed(String)

    public var errorDescription: String? {
        switch self {
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
    private let chunkingConfiguration: ChunkingConfiguration
    private let onProgress: (@Sendable (AnalysisProgress) -> Void)?

    /// - Parameter chunkingConfiguration: Controls chunk size, overlap, and context
    ///   window limits. Swap to `ChunkingConfiguration.turboQuant` (or a custom
    ///   value) when TurboQuant integration lands.
    public init(
        chunkingService: ChunkingServiceProtocol,
        aiAnalysisService: AIAnalysisServiceProtocol,
        storageService: StorageServiceProtocol,
        paywallService: PaywallServiceProtocol,
        chunkingConfiguration: ChunkingConfiguration = .default,
        onProgress: (@Sendable (AnalysisProgress) -> Void)? = nil
    ) {
        self.chunkingService = chunkingService
        self.aiAnalysisService = aiAnalysisService
        self.storageService = storageService
        self.paywallService = paywallService
        self.chunkingConfiguration = chunkingConfiguration
        self.onProgress = onProgress
    }

    public func analyzeDocument(_ document: Document) async throws -> AnalysisResult {
        // Step 1: Validate document text
        guard !document.rawText.isEmpty else {
            throw AnalysisCoordinatorError.emptyDocumentText
        }

        // Step 3: Chunk text
        onProgress?(.chunkingText)

        let chunks = chunkingService.chunkText(
            document.rawText,
            configuration: chunkingConfiguration,
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

        onProgress?(.complete)

        return mergedResult
    }

}
