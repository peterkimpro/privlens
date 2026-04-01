import Foundation

// MARK: - Protocol

/// Protocol for AI-powered document analysis, enabling testability.
public protocol AIAnalysisServiceProtocol: Sendable {
    /// Analyzes a single text chunk and returns extracted insights.
    func analyzeChunk(_ chunk: TextChunk, documentType: String?) async throws -> [Insight]

    /// Generates a human-readable summary from a collection of insights.
    func generateSummary(from insights: [Insight], documentContext: String?) async throws -> String

    /// Analyzes a full document by processing all chunks and aggregating results.
    func analyzeDocument(chunks: [TextChunk], documentType: String?) async throws -> AnalysisResult
}

// MARK: - Errors

public enum AIAnalysisError: Error, LocalizedError, Sendable {
    case unavailable
    case noChunksProvided
    case chunkAnalysisFailed(chunkIndex: Int, underlying: String)

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "AI analysis is not available on this platform. Requires Apple Foundation Models on iOS 26+."
        case .noChunksProvided:
            return "No text chunks were provided for analysis."
        case .chunkAnalysisFailed(let index, let reason):
            return "Analysis failed for chunk \(index): \(reason)"
        }
    }
}

// MARK: - Implementation

#if ENABLE_FOUNDATION_MODELS
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
public final class AIAnalysisService: AIAnalysisServiceProtocol, Sendable {

    public init() {}

    // MARK: - AIAnalysisServiceProtocol

    public func analyzeChunk(_ chunk: TextChunk, documentType: String?) async throws -> [Insight] {
        let session = LanguageModelSession()
        let prompt = PromptTemplates.chunkAnalysisPrompt(text: chunk.text, documentType: documentType)

        let response = try await session.respond(to: prompt, generating: GenerableChunkAnalysisOutput.self)
        let output = response.content.toChunkAnalysisOutput()

        return convertToInsights(output, chunk: chunk)
    }

    public func generateSummary(from insights: [Insight], documentContext: String?) async throws -> String {
        let session = LanguageModelSession()
        let insightDescriptions = insights.map { "[\($0.category.rawValue)] \($0.title): \($0.description)" }
        let prompt = PromptTemplates.summaryPrompt(insights: insightDescriptions, documentType: documentContext)

        let response = try await session.respond(to: prompt)
        return response.content
    }

    public func analyzeDocument(chunks: [TextChunk], documentType: String?) async throws -> AnalysisResult {
        guard !chunks.isEmpty else {
            throw AIAnalysisError.noChunksProvided
        }

        // Analyze each chunk and collect insights
        var allInsights: [Insight] = []
        for chunk in chunks {
            let chunkInsights = try await analyzeChunk(chunk, documentType: documentType)
            allInsights.append(contentsOf: chunkInsights)
        }

        // Generate a meta-summary from all insights
        let summary = try await generateSummary(from: allInsights, documentContext: documentType)

        // Partition insights into categories for the AnalysisResult
        let keyInsightStrings = allInsights
            .filter { $0.category != .risk && $0.category != .recommendation }
            .map { "\($0.title): \($0.description)" }

        let redFlagStrings = allInsights
            .filter { $0.category == .risk }
            .map { "\($0.title): \($0.description)" }

        let actionItemStrings = allInsights
            .filter { $0.category == .recommendation || $0.category == .obligation }
            .map { "\($0.title): \($0.description)" }

        let detectedType = detectDocumentType(from: documentType)

        return AnalysisResult(
            summary: summary,
            keyInsights: keyInsightStrings,
            redFlags: redFlagStrings,
            actionItems: actionItemStrings,
            documentType: detectedType
        )
    }

    // MARK: - Legacy single-pass analysis

    /// Analyzes document text using Apple Foundation Models.
    /// Retries with safer prompt framing if the safety filter rejects the first attempt,
    /// then falls back to chunk-based analysis with smaller text segments.
    public func analyzeDocument(text: String, type: DocumentType) async throws -> AnalysisResult {
        // Attempt 1: single-pass with standard prompt
        do {
            let session = LanguageModelSession()
            let prompt = buildLegacyPrompt(for: type, text: text)
            let response = try await session.respond(to: prompt, generating: GenerableAnalysisResult.self)
            return response.content.toAnalysisResult()
        } catch let error where Self.isSafetyFilterError(error) {
            // Attempt 2: reframed prompt that emphasizes the legitimate document review context
            do {
                let session = LanguageModelSession()
                let prompt = buildSafetyRetryPrompt(for: type, text: text)
                let response = try await session.respond(to: prompt, generating: GenerableAnalysisResult.self)
                return response.content.toAnalysisResult()
            } catch let retryError where Self.isSafetyFilterError(retryError) {
                // Attempt 3: chunk-based analysis with smaller text segments
                let chunkingService = ChunkingService()
                let config = ChunkingConfiguration(maxChunkSize: 500, chunkOverlap: 50)
                let chunks = chunkingService.chunkText(text, configuration: config)
                guard !chunks.isEmpty else { throw AIAnalysisError.noChunksProvided }
                return try await analyzeDocument(chunks: chunks, documentType: type.rawValue)
            }
        }
    }

    /// Checks if an error is from Apple's safety content filter.
    private static func isSafetyFilterError(_ error: Error) -> Bool {
        let desc = String(describing: error).lowercased()
        return desc.contains("unsafe") || desc.contains("safety")
            || desc.contains("not safe") || desc.contains("guardrail")
            || desc.contains("content filter") || desc.contains("responseSafety")
    }

    // MARK: - Private Helpers

    private func convertToInsights(_ output: ChunkAnalysisOutput, chunk: TextChunk) -> [Insight] {
        let count = min(
            output.insightTitles.count,
            min(output.insightDescriptions.count,
                min(output.insightCategories.count,
                    min(output.insightConfidences.count, output.sourceQuotes.count)))
        )

        return (0..<count).map { i in
            let category = InsightCategory(rawValue: output.insightCategories[i]) ?? .other
            let confidence = max(0.0, min(1.0, output.insightConfidences[i]))
            let quote = output.sourceQuotes[i]

            // Find the quote offset within the chunk text for precise attribution
            let startOffset: Int
            let endOffset: Int
            if let range = chunk.text.range(of: quote) {
                startOffset = chunk.text.distance(from: chunk.text.startIndex, to: range.lowerBound)
                endOffset = chunk.text.distance(from: chunk.text.startIndex, to: range.upperBound)
            } else {
                startOffset = 0
                endOffset = min(quote.count, chunk.text.count)
            }

            let attribution = SourceAttribution(
                chunkIndex: chunk.metadata.chunkIndex,
                startOffset: startOffset,
                endOffset: endOffset,
                matchedText: quote,
                pageIndex: chunk.metadata.sourcePageIndex
            )

            return Insight(
                title: output.insightTitles[i],
                description: output.insightDescriptions[i],
                category: category,
                confidence: confidence,
                sourceAttributions: [attribution]
            )
        }
    }

    private func detectDocumentType(from typeString: String?) -> DocumentType {
        guard let typeString else { return .unknown }
        return DocumentType(rawValue: typeString)
            ?? DocumentType.allCases.first { $0.displayName.lowercased() == typeString.lowercased() }
            ?? .unknown
    }

    private func buildLegacyPrompt(for type: DocumentType, text: String) -> String {
        let typeLine: String
        if type != .unknown {
            typeLine = "Document Type: \(type.displayName)\n\n"
        } else {
            typeLine = "First, determine what type of document this is based on its content.\n\n"
        }

        return """
        You are a document analysis assistant specializing in consumer protection. \
        Analyze the following document text and provide a structured analysis.

        \(typeLine)\
        General instructions:
        - Provide a concise 2-3 sentence summary
        - Extract key insights that are actionable and specific
        - Identify any red flags, hidden fees, unusual clauses, or concerning items
        - Suggest concrete action items the user should take
        - Classify the document type based on its content

        DOCUMENT TEXT:
        ---
        \(text)
        ---
        """
    }

    private func buildSafetyRetryPrompt(for type: DocumentType, text: String) -> String {
        // Reframed prompt that clearly establishes the legitimate personal document review context,
        // reducing false positives from Apple's safety filter.
        return """
        You are a helpful personal document assistant. The user has scanned one of their own \
        personal documents and needs help understanding it. This is a routine document review \
        for consumer protection purposes.

        Please review the user's scanned document and provide:
        - A brief 2-3 sentence summary of what this document is about
        - Key information the user should know (dates, amounts, terms)
        - Any items that need the user's attention or action

        The scanned text from the user's document is below. Note that OCR may have introduced \
        errors or picked up background text — focus on the main content.

        USER'S SCANNED DOCUMENT:
        ---
        \(text)
        ---
        """
    }
}

#else

// MARK: - Linux / non-Apple platform stub

public final class AIAnalysisService: AIAnalysisServiceProtocol, Sendable {
    public init() {}

    public func analyzeChunk(_ chunk: TextChunk, documentType: String?) async throws -> [Insight] {
        return mockInsights(for: chunk)
    }

    public func generateSummary(from insights: [Insight], documentContext: String?) async throws -> String {
        let count = insights.count
        let categories = Set(insights.map { $0.category.rawValue })
        let categoryList = categories.sorted().joined(separator: ", ")
        return "Mock summary: Found \(count) insight(s) across categories: \(categoryList). "
            + "This is a stub result — real analysis requires Apple Foundation Models on iOS 26+."
    }

    public func analyzeDocument(chunks: [TextChunk], documentType: String?) async throws -> AnalysisResult {
        guard !chunks.isEmpty else {
            throw AIAnalysisError.noChunksProvided
        }

        var allInsights: [Insight] = []
        for chunk in chunks {
            let chunkInsights = try await analyzeChunk(chunk, documentType: documentType)
            allInsights.append(contentsOf: chunkInsights)
        }

        let summary = try await generateSummary(from: allInsights, documentContext: documentType)

        let keyInsightStrings = allInsights
            .filter { $0.category != .risk && $0.category != .recommendation }
            .map { "\($0.title): \($0.description)" }

        let redFlagStrings = allInsights
            .filter { $0.category == .risk }
            .map { "\($0.title): \($0.description)" }

        let actionItemStrings = allInsights
            .filter { $0.category == .recommendation || $0.category == .obligation }
            .map { "\($0.title): \($0.description)" }

        return AnalysisResult(
            summary: summary,
            keyInsights: keyInsightStrings,
            redFlags: redFlagStrings,
            actionItems: actionItemStrings,
            documentType: .unknown
        )
    }

    /// Legacy single-pass stub for backward compatibility.
    public func analyzeDocument(text: String, type: DocumentType) async throws -> AnalysisResult {
        let chunk = TextChunk(
            text: text,
            metadata: ChunkMetadata(chunkIndex: 0, startOffset: 0, endOffset: text.count, sourcePageIndex: 0)
        )
        return try await analyzeDocument(chunks: [chunk], documentType: type.rawValue)
    }

    // MARK: - Mock Helpers

    private func mockInsights(for chunk: TextChunk) -> [Insight] {
        let quote = String(chunk.text.prefix(80))
        let attribution = SourceAttribution(
            chunkIndex: chunk.metadata.chunkIndex,
            startOffset: 0,
            endOffset: min(80, chunk.text.count),
            matchedText: quote,
            pageIndex: chunk.metadata.sourcePageIndex
        )

        return [
            Insight(
                title: "Mock Insight for Chunk \(chunk.metadata.chunkIndex)",
                description: "This is a mock insight generated on a non-Apple platform. "
                    + "Real analysis requires Apple Foundation Models on iOS 26+.",
                category: .other,
                confidence: 0.1,
                sourceAttributions: [attribution]
            )
        ]
    }
}

#endif
