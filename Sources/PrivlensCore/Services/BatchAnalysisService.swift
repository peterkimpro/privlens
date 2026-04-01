import Foundation

// MARK: - BatchAnalysisError

public enum BatchAnalysisError: Error, LocalizedError, Sendable {
    case emptyBatch
    case allDocumentsFailed

    public var errorDescription: String? {
        switch self {
        case .emptyBatch:
            return "No documents were provided for batch analysis."
        case .allDocumentsFailed:
            return "All documents in the batch failed to analyze."
        }
    }
}

// MARK: - BatchProgress

/// Reports progress of a batch analysis job.
public struct BatchProgress: Sendable {
    public let currentIndex: Int
    public let totalCount: Int
    public let currentDocumentTitle: String
    public let overallProgress: Double

    public init(currentIndex: Int, totalCount: Int, currentDocumentTitle: String) {
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.currentDocumentTitle = currentDocumentTitle
        self.overallProgress = totalCount > 0 ? Double(currentIndex) / Double(totalCount) : 0.0
    }
}

// MARK: - BatchAnalysisServiceProtocol

/// Protocol for batch document analysis.
public protocol BatchAnalysisServiceProtocol: Sendable {
    /// Analyze a batch of documents sequentially, respecting paywall limits.
    func analyzeBatch(
        _ job: BatchJob,
        documents: [Document],
        onProgress: @Sendable (BatchProgress) -> Void
    ) async throws -> BatchJob
}

// MARK: - BatchAnalysisService

public final class BatchAnalysisService: BatchAnalysisServiceProtocol, Sendable {

    private let analysisCoordinator: AnalysisCoordinatorProtocol

    public init(
        analysisCoordinator: AnalysisCoordinatorProtocol,
        paywallService: PaywallServiceProtocol? = nil
    ) {
        self.analysisCoordinator = analysisCoordinator
    }

    public func analyzeBatch(
        _ job: BatchJob,
        documents: [Document],
        onProgress: @Sendable (BatchProgress) -> Void
    ) async throws -> BatchJob {
        guard !job.entries.isEmpty else {
            throw BatchAnalysisError.emptyBatch
        }

        var updatedJob = job
        updatedJob.status = .running

        let documentMap = Dictionary(uniqueKeysWithValues: documents.map { ($0.id, $0) })

        for (index, entry) in updatedJob.entries.enumerated() {
            // Report progress
            let progress = BatchProgress(
                currentIndex: index,
                totalCount: updatedJob.entries.count,
                currentDocumentTitle: entry.title
            )
            onProgress(progress)

            // Mark as analyzing
            updatedJob.entries[index].status = .analyzing

            // Find the actual document
            guard let document = documentMap[entry.documentId] else {
                updatedJob.entries[index].status = .failed
                updatedJob.entries[index].errorMessage = "Document not found"
                continue
            }

            do {
                let result = try await analysisCoordinator.analyzeDocument(document)
                updatedJob.entries[index].status = .completed
                updatedJob.entries[index].result = result
            } catch {
                updatedJob.entries[index].status = .failed
                updatedJob.entries[index].errorMessage = error.localizedDescription
            }
        }

        // Generate cross-document insights
        updatedJob.crossDocumentInsights = generateCrossDocumentInsights(from: updatedJob)

        // Determine final status
        let completedCount = updatedJob.entries.filter { $0.status == .completed }.count
        let totalCount = updatedJob.entries.count

        if completedCount == totalCount {
            updatedJob.status = .completed
        } else if completedCount > 0 {
            updatedJob.status = .partiallyCompleted
        } else {
            updatedJob.status = .failed
        }

        updatedJob.completedAt = Date()

        return updatedJob
    }

    // MARK: - Cross-Document Insights

    /// Analyze completed batch entries for patterns across documents.
    private func generateCrossDocumentInsights(from job: BatchJob) -> [CrossDocumentInsight] {
        let completedEntries = job.entries.filter { $0.status == .completed && $0.result != nil }
        guard completedEntries.count >= 2 else { return [] }

        var insights: [CrossDocumentInsight] = []

        // Look for shared addresses (simple pattern matching)
        insights.append(contentsOf: findSharedPatterns(
            in: completedEntries,
            patternType: .sharedAddress,
            extractor: { extractAddresses(from: $0) }
        ))

        // Look for shared financial amounts
        insights.append(contentsOf: findSharedPatterns(
            in: completedEntries,
            patternType: .sharedFinancialAmount,
            extractor: { extractFinancialAmounts(from: $0) }
        ))

        // Look for shared entity names
        insights.append(contentsOf: findSharedPatterns(
            in: completedEntries,
            patternType: .sharedEntity,
            extractor: { extractEntityNames(from: $0) }
        ))

        return insights
    }

    private func findSharedPatterns(
        in entries: [BatchDocumentEntry],
        patternType: CrossDocumentPatternType,
        extractor: (AnalysisResult) -> [String]
    ) -> [CrossDocumentInsight] {
        // Map: pattern value -> [(documentId, documentTitle)]
        var patternDocuments: [String: [(UUID, String)]] = [:]

        for entry in entries {
            guard let result = entry.result else { continue }
            let patterns = extractor(result)
            for pattern in patterns {
                let normalized = pattern.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalized.isEmpty else { continue }
                patternDocuments[normalized, default: []].append((entry.documentId, entry.title))
            }
        }

        // Only keep patterns found in 2+ documents
        return patternDocuments.compactMap { (pattern, docs) -> CrossDocumentInsight? in
            guard docs.count >= 2 else { return nil }
            let uniqueDocs = Dictionary(grouping: docs, by: { $0.0 })
            guard uniqueDocs.count >= 2 else { return nil }

            let docIds = Array(uniqueDocs.keys)
            let docTitles = docIds.compactMap { id in docs.first(where: { $0.0 == id })?.1 }

            let description: String
            switch patternType {
            case .sharedAddress:
                description = "These \(docIds.count) documents reference the same address: \(pattern)"
            case .sharedFinancialAmount:
                description = "These \(docIds.count) documents mention the same amount: \(pattern)"
            case .sharedEntity:
                description = "These \(docIds.count) documents reference the same entity: \(pattern)"
            case .sharedDate:
                description = "These \(docIds.count) documents share a common date: \(pattern)"
            case .relatedTerms:
                description = "These \(docIds.count) documents contain related terms: \(pattern)"
            case .other:
                description = "These \(docIds.count) documents share a common pattern: \(pattern)"
            }

            return CrossDocumentInsight(
                description: description,
                relatedDocumentIds: docIds,
                relatedDocumentTitles: docTitles,
                patternType: patternType
            )
        }
    }

    /// Simple address extraction from analysis text.
    private func extractAddresses(from result: AnalysisResult) -> [String] {
        let allText = ([result.summary] + result.keyInsights + result.redFlags + result.actionItems)
            .joined(separator: " ")

        // Simple pattern: look for text that contains typical address indicators
        var addresses: [String] = []
        let patterns = [
            "\\d+\\s+[A-Z][a-zA-Z]+\\s+(?:St|Street|Ave|Avenue|Blvd|Boulevard|Dr|Drive|Rd|Road|Ln|Lane|Way|Ct|Court|Pl|Place)(?:\\s+(?:#|Apt|Suite|Unit)\\s*\\S+)?",
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = allText as NSString
                let matches = regex.matches(in: allText, options: [], range: NSRange(location: 0, length: nsString.length))
                for match in matches {
                    addresses.append(nsString.substring(with: match.range))
                }
            }
        }

        return addresses
    }

    /// Simple financial amount extraction.
    private func extractFinancialAmounts(from result: AnalysisResult) -> [String] {
        let allText = ([result.summary] + result.keyInsights + result.redFlags + result.actionItems)
            .joined(separator: " ")

        var amounts: [String] = []
        let pattern = "\\$[\\d,]+(?:\\.\\d{2})?"

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = allText as NSString
            let matches = regex.matches(in: allText, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                amounts.append(nsString.substring(with: match.range))
            }
        }

        return amounts
    }

    /// Simple entity name extraction (capitalized multi-word names).
    private func extractEntityNames(from result: AnalysisResult) -> [String] {
        let allText = ([result.summary] + result.keyInsights + result.redFlags + result.actionItems)
            .joined(separator: " ")

        var entities: [String] = []
        let pattern = "(?:[A-Z][a-z]+\\s+){1,3}(?:LLC|Inc|Corp|Corporation|Company|Co|Ltd|Group|Partners|Associates)"

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = allText as NSString
            let matches = regex.matches(in: allText, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                entities.append(nsString.substring(with: match.range))
            }
        }

        return entities
    }
}
