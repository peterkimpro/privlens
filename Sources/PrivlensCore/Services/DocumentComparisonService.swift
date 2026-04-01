import Foundation

// MARK: - ComparisonDifference

/// Represents a single difference found between two documents.
public struct ComparisonDifference: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    /// Category of the difference.
    public let category: DifferenceCategory
    /// Human-readable label for the difference.
    public let label: String
    /// The value or text from the first document.
    public let documentAValue: String
    /// The value or text from the second document.
    public let documentBValue: String
    /// Severity of the difference (0.0 = informational, 1.0 = critical).
    public let severity: Double

    public init(
        id: UUID = UUID(),
        category: DifferenceCategory,
        label: String,
        documentAValue: String,
        documentBValue: String,
        severity: Double
    ) {
        self.id = id
        self.category = category
        self.label = label
        self.documentAValue = documentAValue
        self.documentBValue = documentBValue
        self.severity = severity
    }
}

// MARK: - DifferenceCategory

public enum DifferenceCategory: String, Codable, Sendable, Hashable, CaseIterable {
    case financial
    case legal
    case date
    case term
    case obligation
    case coverage
    case other

    public var displayName: String {
        switch self {
        case .financial: return "Financial"
        case .legal: return "Legal"
        case .date: return "Date"
        case .term: return "Term"
        case .obligation: return "Obligation"
        case .coverage: return "Coverage"
        case .other: return "Other"
        }
    }

    public var systemIcon: String {
        switch self {
        case .financial: return "dollarsign.circle.fill"
        case .legal: return "scale.3d"
        case .date: return "calendar"
        case .term: return "doc.text.fill"
        case .obligation: return "checklist"
        case .coverage: return "shield.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

// MARK: - ComparisonResult

/// The full result of comparing two documents.
public struct ComparisonResult: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public let documentAId: UUID
    public let documentBId: UUID
    public let documentATitle: String
    public let documentBTitle: String
    /// What type of document A is (e.g. "window replacement quote")
    public let documentAType: String
    /// What type of document B is (e.g. "HOA agreement")
    public let documentBType: String
    /// Whether the two documents are the same type and directly comparable
    public let areRelated: Bool
    public let summary: String
    /// Key things to know about document A
    public let highlightsA: [String]
    /// Key things to know about document B
    public let highlightsB: [String]
    /// Direct differences (only meaningful when documents are related)
    public let differences: [ComparisonDifference]
    public let similarityScore: Double
    public let comparedAt: Date

    public init(
        id: UUID = UUID(),
        documentAId: UUID,
        documentBId: UUID,
        documentATitle: String,
        documentBTitle: String,
        documentAType: String = "",
        documentBType: String = "",
        areRelated: Bool = true,
        summary: String,
        highlightsA: [String] = [],
        highlightsB: [String] = [],
        differences: [ComparisonDifference],
        similarityScore: Double,
        comparedAt: Date = Date()
    ) {
        self.id = id
        self.documentAId = documentAId
        self.documentBId = documentBId
        self.documentATitle = documentATitle
        self.documentBTitle = documentBTitle
        self.documentAType = documentAType
        self.documentBType = documentBType
        self.areRelated = areRelated
        self.summary = summary
        self.highlightsA = highlightsA
        self.highlightsB = highlightsB
        self.differences = differences
        self.similarityScore = similarityScore
        self.comparedAt = comparedAt
    }

    public func criticalDifferences(threshold: Double = 0.7) -> [ComparisonDifference] {
        differences.filter { $0.severity >= threshold }
    }
}

// MARK: - DocumentComparisonServiceProtocol

/// Protocol for comparing two documents.
public protocol DocumentComparisonServiceProtocol: Sendable {
    func compare(documentA: Document, documentB: Document) async throws -> ComparisonResult
}

// MARK: - DocumentComparisonError

public enum DocumentComparisonError: Error, LocalizedError, Sendable {
    case emptyDocument(String)
    case sameDocument
    case comparisonFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyDocument(let name):
            return "Document '\(name)' has no text content to compare."
        case .sameDocument:
            return "Cannot compare a document with itself."
        case .comparisonFailed(let reason):
            return "Comparison failed: \(reason)"
        }
    }
}

// MARK: - AI-Powered Implementation

#if ENABLE_FOUNDATION_MODELS
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
public final class DocumentComparisonService: DocumentComparisonServiceProtocol, Sendable {

    public init() {}

    public func compare(documentA: Document, documentB: Document) async throws -> ComparisonResult {
        guard documentA.id != documentB.id else {
            throw DocumentComparisonError.sameDocument
        }
        guard !documentA.rawText.isEmpty else {
            throw DocumentComparisonError.emptyDocument(documentA.title)
        }
        guard !documentB.rawText.isEmpty else {
            throw DocumentComparisonError.emptyDocument(documentB.title)
        }

        // Truncate texts to fit context window
        let maxChars = 3500
        let textA = String(documentA.rawText.prefix(maxChars))
        let textB = String(documentB.rawText.prefix(maxChars))

        let session = LanguageModelSession()
        let prompt = buildComparisonPrompt(
            titleA: documentA.title,
            titleB: documentB.title,
            textA: textA,
            textB: textB
        )

        let response = try await session.respond(to: prompt)
        let aiOutput = response.content

        // Parse the AI response into structured result
        return parseAIResponse(
            aiOutput,
            documentA: documentA,
            documentB: documentB
        )
    }

    private func buildComparisonPrompt(
        titleA: String,
        titleB: String,
        textA: String,
        textB: String
    ) -> String {
        """
        Compare these two documents for the user.

        DOCUMENT A ("\(titleA)"):
        ---
        \(textA)
        ---

        DOCUMENT B ("\(titleB)"):
        ---
        \(textB)
        ---

        Here is an example of the output format for two DIFFERENT types of documents:

        TYPE_A: window replacement quote
        TYPE_B: HOA agreement
        RELATED: no
        SIMILARITY: 10
        SUMMARY: These are two completely different documents. "\(titleA)" is a window replacement quote with pricing and installation details, while "\(titleB)" is an HOA agreement covering community rules and fees. They serve different purposes and cannot be directly compared.
        ABOUT_A|The quoted price for window replacement is $5,000 for 10 windows
        ABOUT_A|Installation is estimated at 2-3 weeks
        ABOUT_B|Monthly HOA dues are $250
        ABOUT_B|There is a pet policy limiting pets to 2 per household

        Here is an example for two SIMILAR documents:

        TYPE_A: window replacement quote
        TYPE_B: window replacement quote
        RELATED: yes
        SIMILARITY: 70
        SUMMARY: Both documents are window replacement quotes from different companies. "\(titleA)" quotes $5,000 for 10 windows without warranty, while "\(titleB)" quotes $6,500 for the same work but includes a 10-year warranty.
        ABOUT_A|Total price is $5,000 for 10 windows
        ABOUT_A|No warranty is mentioned
        ABOUT_B|Total price is $6,500 for 10 windows
        ABOUT_B|Includes a 10-year warranty on all windows
        DIFF|financial|Total price|$5,000|$6,500|60
        DIFF|coverage|Warranty|No warranty mentioned|10-year warranty included|70

        Now write your actual analysis of the two documents above. Do not copy the examples. \
        Write real content based on what is actually in the documents. \
        Do not include brackets or placeholder text. Do not use markdown formatting.
        """
    }

    private func parseAIResponse(
        _ response: String,
        documentA: Document,
        documentB: Document
    ) -> ComparisonResult {
        var similarity = 0.5
        var summary = "Comparison complete."
        var typeA = ""
        var typeB = ""
        var areRelated = true
        var highlightsA: [String] = []
        var highlightsB: [String] = []
        var differences: [ComparisonDifference] = []

        let lines = response.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("TYPE_A:") {
                typeA = trimmed.replacingOccurrences(of: "TYPE_A:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("TYPE_B:") {
                typeB = trimmed.replacingOccurrences(of: "TYPE_B:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("RELATED:") {
                let value = trimmed.replacingOccurrences(of: "RELATED:", with: "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                areRelated = value.hasPrefix("yes")
            } else if trimmed.hasPrefix("SIMILARITY:") {
                let value = trimmed.replacingOccurrences(of: "SIMILARITY:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "%", with: "")
                if let num = Double(value) {
                    similarity = min(1.0, max(0.0, num / 100.0))
                }
            } else if trimmed.hasPrefix("SUMMARY:") {
                summary = trimmed.replacingOccurrences(of: "SUMMARY:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmed.hasPrefix("ABOUT_A|") {
                let content = trimmed.replacingOccurrences(of: "ABOUT_A|", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty { highlightsA.append(content) }
            } else if trimmed.hasPrefix("ABOUT_B|") {
                let content = trimmed.replacingOccurrences(of: "ABOUT_B|", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !content.isEmpty { highlightsB.append(content) }
            } else if trimmed.hasPrefix("DIFF|") {
                let parts = trimmed.components(separatedBy: "|")
                if parts.count >= 6 {
                    let category = DifferenceCategory(rawValue: parts[1].trimmingCharacters(in: .whitespaces)) ?? .other
                    let label = parts[2].trimmingCharacters(in: .whitespaces)
                    let docAValue = parts[3].trimmingCharacters(in: .whitespaces)
                    let docBValue = parts[4].trimmingCharacters(in: .whitespaces)
                    let severityStr = parts[5].trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "%", with: "")
                    let severity = Double(severityStr).map { min(1.0, max(0.0, $0 / 100.0)) } ?? 0.5

                    differences.append(ComparisonDifference(
                        category: category,
                        label: label,
                        documentAValue: docAValue,
                        documentBValue: docBValue,
                        severity: severity
                    ))
                }
            }
        }

        // Fallback summary
        if summary == "Comparison complete." {
            let paragraphs = response.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix("SIMILARITY") && !$0.hasPrefix("DIFF") && !$0.hasPrefix("TYPE_") && !$0.hasPrefix("RELATED") && !$0.hasPrefix("ABOUT_") }
            if let first = paragraphs.first {
                summary = first
            }
        }

        return ComparisonResult(
            documentAId: documentA.id,
            documentBId: documentB.id,
            documentATitle: documentA.title,
            documentBTitle: documentB.title,
            documentAType: typeA,
            documentBType: typeB,
            areRelated: areRelated,
            summary: summary,
            highlightsA: highlightsA,
            highlightsB: highlightsB,
            differences: differences,
            similarityScore: similarity
        )
    }
}

#else

// MARK: - Linux / non-Apple platform stub

public final class DocumentComparisonService: DocumentComparisonServiceProtocol, Sendable {

    public init() {}

    public func compare(documentA: Document, documentB: Document) async throws -> ComparisonResult {
        guard documentA.id != documentB.id else {
            throw DocumentComparisonError.sameDocument
        }
        guard !documentA.rawText.isEmpty else {
            throw DocumentComparisonError.emptyDocument(documentA.title)
        }
        guard !documentB.rawText.isEmpty else {
            throw DocumentComparisonError.emptyDocument(documentB.title)
        }

        // Simple word-overlap similarity for non-Apple platforms
        let wordsA = Set(documentA.rawText.lowercased().split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }).map(String.init))
        let wordsB = Set(documentB.rawText.lowercased().split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }).map(String.init))
        let union = wordsA.union(wordsB).count
        let intersection = wordsA.intersection(wordsB).count
        let similarity = union > 0 ? Double(intersection) / Double(union) : 0.0

        return ComparisonResult(
            documentAId: documentA.id,
            documentBId: documentB.id,
            documentATitle: documentA.title,
            documentBTitle: documentB.title,
            summary: "Mock comparison: \(Int(similarity * 100))% word overlap. AI-powered comparison requires iOS 26+.",
            differences: [],
            similarityScore: similarity
        )
    }
}

#endif
