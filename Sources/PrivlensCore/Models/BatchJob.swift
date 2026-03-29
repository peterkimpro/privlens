import Foundation

// MARK: - BatchDocumentStatus

/// Status of a single document within a batch analysis job.
public enum BatchDocumentStatus: String, Codable, Sendable {
    case pending
    case analyzing
    case completed
    case failed
    case skippedPaywall
}

// MARK: - BatchDocumentEntry

/// Represents a single document entry within a batch job.
public struct BatchDocumentEntry: Codable, Sendable, Identifiable {
    public let id: UUID
    public let documentId: UUID
    public let title: String
    public var status: BatchDocumentStatus
    public var result: AnalysisResult?
    public var errorMessage: String?

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        title: String,
        status: BatchDocumentStatus = .pending,
        result: AnalysisResult? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.documentId = documentId
        self.title = title
        self.status = status
        self.result = result
        self.errorMessage = errorMessage
    }
}

// MARK: - BatchJobStatus

/// Overall status of a batch analysis job.
public enum BatchJobStatus: String, Codable, Sendable {
    case pending
    case running
    case completed
    case partiallyCompleted
    case failed
}

// MARK: - CrossDocumentInsight

/// An insight that spans multiple documents in a batch.
public struct CrossDocumentInsight: Codable, Sendable, Identifiable {
    public let id: UUID
    /// Human-readable description of the cross-document insight.
    public let description: String
    /// IDs of the documents that share this insight.
    public let relatedDocumentIds: [UUID]
    /// Titles of the related documents for display.
    public let relatedDocumentTitles: [String]
    /// The type of cross-document pattern detected.
    public let patternType: CrossDocumentPatternType

    public init(
        id: UUID = UUID(),
        description: String,
        relatedDocumentIds: [UUID],
        relatedDocumentTitles: [String],
        patternType: CrossDocumentPatternType
    ) {
        self.id = id
        self.description = description
        self.relatedDocumentIds = relatedDocumentIds
        self.relatedDocumentTitles = relatedDocumentTitles
        self.patternType = patternType
    }
}

// MARK: - CrossDocumentPatternType

public enum CrossDocumentPatternType: String, Codable, Sendable {
    case sharedAddress
    case sharedEntity
    case sharedFinancialAmount
    case sharedDate
    case relatedTerms
    case other
}

// MARK: - BatchJob

/// A group of documents to analyze together as a batch.
public struct BatchJob: Codable, Sendable, Identifiable {
    public let id: UUID
    public var title: String
    public var entries: [BatchDocumentEntry]
    public var status: BatchJobStatus
    public let createdAt: Date
    public var completedAt: Date?
    public var crossDocumentInsights: [CrossDocumentInsight]

    public init(
        id: UUID = UUID(),
        title: String,
        entries: [BatchDocumentEntry],
        status: BatchJobStatus = .pending,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        crossDocumentInsights: [CrossDocumentInsight] = []
    ) {
        self.id = id
        self.title = title
        self.entries = entries
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.crossDocumentInsights = crossDocumentInsights
    }

    /// Number of documents that have been completed or failed.
    public var processedCount: Int {
        entries.filter { $0.status == .completed || $0.status == .failed || $0.status == .skippedPaywall }.count
    }

    /// Overall progress as a fraction 0.0 to 1.0.
    public var progress: Double {
        guard !entries.isEmpty else { return 0.0 }
        return Double(processedCount) / Double(entries.count)
    }

    /// Number of entries that completed successfully.
    public var successCount: Int {
        entries.filter { $0.status == .completed }.count
    }

    /// Number of entries that failed.
    public var failedCount: Int {
        entries.filter { $0.status == .failed }.count
    }

    /// Combined summary across all completed documents.
    public var combinedSummary: String {
        let summaries = entries.compactMap { $0.result?.summary }
        guard !summaries.isEmpty else { return "No analysis results available." }
        return summaries.joined(separator: "\n\n")
    }

    /// All red flags from all completed documents.
    public var allRedFlags: [(documentTitle: String, redFlag: String)] {
        entries.compactMap { entry -> [(String, String)]? in
            guard let result = entry.result else { return nil }
            return result.redFlags.map { (entry.title, $0) }
        }.flatMap { $0 }
    }

    /// All action items from all completed documents.
    public var allActionItems: [(documentTitle: String, actionItem: String)] {
        entries.compactMap { entry -> [(String, String)]? in
            guard let result = entry.result else { return nil }
            return result.actionItems.map { (entry.title, $0) }
        }.flatMap { $0 }
    }
}
