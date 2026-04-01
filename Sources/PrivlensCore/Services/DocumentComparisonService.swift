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
    /// ID of the first document (A).
    public let documentAId: UUID
    /// ID of the second document (B).
    public let documentBId: UUID
    /// Title of document A.
    public let documentATitle: String
    /// Title of document B.
    public let documentBTitle: String
    /// Summary of the comparison.
    public let summary: String
    /// Individual differences found.
    public let differences: [ComparisonDifference]
    /// Overall similarity score from 0.0 (completely different) to 1.0 (identical).
    public let similarityScore: Double
    /// When the comparison was performed.
    public let comparedAt: Date

    public init(
        id: UUID = UUID(),
        documentAId: UUID,
        documentBId: UUID,
        documentATitle: String,
        documentBTitle: String,
        summary: String,
        differences: [ComparisonDifference],
        similarityScore: Double,
        comparedAt: Date = Date()
    ) {
        self.id = id
        self.documentAId = documentAId
        self.documentBId = documentBId
        self.documentATitle = documentATitle
        self.documentBTitle = documentBTitle
        self.summary = summary
        self.differences = differences
        self.similarityScore = similarityScore
        self.comparedAt = comparedAt
    }

    /// Differences filtered by severity threshold.
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
        You are a document comparison assistant. Compare these two documents and explain \
        the meaningful differences to the user in plain, natural language.

        DOCUMENT A ("\(titleA)"):
        ---
        \(textA)
        ---

        DOCUMENT B ("\(titleB)"):
        ---
        \(textB)
        ---

        Provide your comparison in this exact format (keep the labels exactly as shown):

        SIMILARITY: [a number from 0 to 100 representing how similar these documents are]

        SUMMARY: [A 2-4 sentence plain language summary of how these documents compare. \
        What are they? How do they relate? What are the most important differences a person should know about?]

        DIFFERENCES:
        [For each meaningful difference, write one line in this format:]
        DIFF|[category]|[short label]|[what document A says]|[what document B says]|[severity 0-100]

        Categories must be one of: financial, legal, date, term, obligation, coverage, other
        Severity: 0 = minor/informational, 100 = critical/needs immediate attention

        Focus on differences that actually matter to the person reading these documents. \
        Do not list trivial wording differences. Do not use markdown formatting. \
        Write naturally as if explaining to someone.
        """
    }

    private func parseAIResponse(
        _ response: String,
        documentA: Document,
        documentB: Document
    ) -> ComparisonResult {
        var similarity = 0.5
        var summary = "Comparison complete."
        var differences: [ComparisonDifference] = []

        let lines = response.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("SIMILARITY:") {
                let value = trimmed.replacingOccurrences(of: "SIMILARITY:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "%", with: "")
                if let num = Double(value) {
                    similarity = min(1.0, max(0.0, num / 100.0))
                }
            } else if trimmed.hasPrefix("SUMMARY:") {
                summary = trimmed.replacingOccurrences(of: "SUMMARY:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
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

        // If AI didn't produce SUMMARY on its own line, use first meaningful paragraph
        if summary == "Comparison complete." {
            let paragraphs = response.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix("SIMILARITY") && !$0.hasPrefix("DIFF") && !$0.hasPrefix("DIFFERENCES") }
            if let first = paragraphs.first {
                summary = first
            }
        }

        return ComparisonResult(
            documentAId: documentA.id,
            documentBId: documentB.id,
            documentATitle: documentA.title,
            documentBTitle: documentB.title,
            summary: summary,
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
