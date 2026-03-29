import Foundation

#if ENABLE_FOUNDATION_MODELS
import FoundationModels

@Generable
public struct AnalysisResult: Codable, Sendable {
    @Guide(description: "A concise 2-3 sentence summary of the document's key points")
    public var summary: String

    @Guide(description: "Important insights extracted from the document, each as a standalone statement")
    public var keyInsights: [String]

    @Guide(description: "Potential red flags or concerning items that warrant attention")
    public var redFlags: [String]

    @Guide(description: "Recommended next steps or actions the user should take")
    public var actionItems: [String]

    @Guide(description: "The classified document type as a raw string, e.g. medicalBill, lease, insurance, taxForm, employmentContract, nda, governmentForm, loanAgreement, homePurchase, unknown")
    public var documentTypeRaw: String

    public var documentType: DocumentType {
        DocumentType(rawValue: documentTypeRaw) ?? .unknown
    }

    public init(
        summary: String,
        keyInsights: [String],
        redFlags: [String],
        actionItems: [String],
        documentType: DocumentType
    ) {
        self.summary = summary
        self.keyInsights = keyInsights
        self.redFlags = redFlags
        self.actionItems = actionItems
        self.documentTypeRaw = documentType.rawValue
    }
}

/// Structured output type for chunk-level AI analysis via @Generable.
@Generable
public struct ChunkAnalysisOutput: Codable, Sendable {
    @Guide(description: "List of insight titles extracted from this chunk")
    public var insightTitles: [String]

    @Guide(description: "List of insight descriptions corresponding to each title")
    public var insightDescriptions: [String]

    @Guide(description: "List of insight categories as raw strings: personalInfo, financialInfo, legalClause, expirationDate, obligation, risk, recommendation, keyTerm, other")
    public var insightCategories: [String]

    @Guide(description: "List of confidence values from 0.0 to 1.0 for each insight")
    public var insightConfidences: [Double]

    @Guide(description: "List of short source quotes from the text that support each insight")
    public var sourceQuotes: [String]

    public init(
        insightTitles: [String],
        insightDescriptions: [String],
        insightCategories: [String],
        insightConfidences: [Double],
        sourceQuotes: [String]
    ) {
        self.insightTitles = insightTitles
        self.insightDescriptions = insightDescriptions
        self.insightCategories = insightCategories
        self.insightConfidences = insightConfidences
        self.sourceQuotes = sourceQuotes
    }
}

#else
public struct AnalysisResult: Codable, Sendable {
    public var summary: String
    public var keyInsights: [String]
    public var redFlags: [String]
    public var actionItems: [String]
    public var documentType: DocumentType

    public init(
        summary: String,
        keyInsights: [String],
        redFlags: [String],
        actionItems: [String],
        documentType: DocumentType
    ) {
        self.summary = summary
        self.keyInsights = keyInsights
        self.redFlags = redFlags
        self.actionItems = actionItems
        self.documentType = documentType
    }
}

/// Stub for chunk analysis output on non-Apple platforms.
public struct ChunkAnalysisOutput: Codable, Sendable {
    public var insightTitles: [String]
    public var insightDescriptions: [String]
    public var insightCategories: [String]
    public var insightConfidences: [Double]
    public var sourceQuotes: [String]

    public init(
        insightTitles: [String],
        insightDescriptions: [String],
        insightCategories: [String],
        insightConfidences: [Double],
        sourceQuotes: [String]
    ) {
        self.insightTitles = insightTitles
        self.insightDescriptions = insightDescriptions
        self.insightCategories = insightCategories
        self.insightConfidences = insightConfidences
        self.sourceQuotes = sourceQuotes
    }
}

#endif

// MARK: - InsightCategory

/// Categories for classified insights extracted from document analysis.
public enum InsightCategory: String, Codable, Sendable, Hashable, CaseIterable {
    case personalInfo
    case financialInfo
    case legalClause
    case expirationDate
    case obligation
    case risk
    case recommendation
    case keyTerm
    case other
}

// MARK: - SourceAttribution

/// Links an insight back to a specific span of text in the original document.
public struct SourceAttribution: Codable, Sendable, Hashable {
    /// Index of the chunk this attribution was found in.
    public let chunkIndex: Int
    /// Character start offset within the chunk text.
    public let startOffset: Int
    /// Character end offset within the chunk text (exclusive).
    public let endOffset: Int
    /// The matched text from the source document.
    public let matchedText: String
    /// Page index in the original document, if known.
    public let pageIndex: Int?

    public init(
        chunkIndex: Int,
        startOffset: Int,
        endOffset: Int,
        matchedText: String,
        pageIndex: Int? = nil
    ) {
        self.chunkIndex = chunkIndex
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.matchedText = matchedText
        self.pageIndex = pageIndex
    }
}

// MARK: - Insight

/// A single insight extracted from document analysis, with source attribution.
public struct Insight: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    /// Short title describing the insight.
    public let title: String
    /// Detailed description of the insight.
    public let description: String
    /// Category classifying the type of insight.
    public let category: InsightCategory
    /// Confidence score from 0.0 to 1.0.
    public let confidence: Double
    /// Source attributions linking this insight to original document text.
    public let sourceAttributions: [SourceAttribution]

    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: InsightCategory,
        confidence: Double,
        sourceAttributions: [SourceAttribution] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.confidence = confidence
        self.sourceAttributions = sourceAttributions
    }
}

// MARK: - AttributedAnalysisResult

/// A complete analysis result with structured insights and source attributions.
public struct AttributedAnalysisResult: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The document this analysis belongs to.
    public let documentId: UUID
    /// Structured insights extracted from the document.
    public let insights: [Insight]
    /// A concise summary of the document.
    public let summary: String
    /// When the analysis was performed.
    public let analyzedAt: Date
    /// Total number of text chunks processed during analysis.
    public let totalChunksProcessed: Int

    public init(
        id: UUID = UUID(),
        documentId: UUID,
        insights: [Insight],
        summary: String,
        analyzedAt: Date = Date(),
        totalChunksProcessed: Int
    ) {
        self.id = id
        self.documentId = documentId
        self.insights = insights
        self.summary = summary
        self.analyzedAt = analyzedAt
        self.totalChunksProcessed = totalChunksProcessed
    }
}
