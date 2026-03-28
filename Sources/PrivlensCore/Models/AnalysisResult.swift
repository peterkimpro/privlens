import Foundation

#if canImport(FoundationModels)
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

    @Guide(description: "The classified type of document")
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
#endif
