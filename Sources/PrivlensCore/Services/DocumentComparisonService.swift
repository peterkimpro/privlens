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

// MARK: - DocumentComparisonService

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

        let textA = documentA.rawText.lowercased()
        let textB = documentB.rawText.lowercased()

        // Extract structured elements from both documents
        let amountsA = extractAmounts(from: textA)
        let amountsB = extractAmounts(from: textB)
        let datesA = extractDates(from: textA)
        let datesB = extractDates(from: textB)

        var differences: [ComparisonDifference] = []

        // Compare financial amounts
        differences.append(contentsOf: compareAmounts(amountsA: amountsA, amountsB: amountsB))

        // Compare dates
        differences.append(contentsOf: compareDates(datesA: datesA, datesB: datesB))

        // Compare key terms
        differences.append(contentsOf: compareKeyTerms(textA: textA, textB: textB))

        // Compute text similarity using Jaccard index on word sets
        let similarityScore = computeSimilarity(textA: textA, textB: textB)

        // Build summary
        let summary = buildSummary(
            documentATitle: documentA.title,
            documentBTitle: documentB.title,
            differences: differences,
            similarity: similarityScore
        )

        return ComparisonResult(
            documentAId: documentA.id,
            documentBId: documentB.id,
            documentATitle: documentA.title,
            documentBTitle: documentB.title,
            summary: summary,
            differences: differences,
            similarityScore: similarityScore
        )
    }

    // MARK: - Extraction Helpers

    private func extractAmounts(from text: String) -> [(label: String, value: String)] {
        var results: [(String, String)] = []
        let patterns: [(String, String)] = [
            ("\\$[\\d,]+\\.?\\d*", "amount"),
            ("(?:rent|salary|compensation|premium|deposit|fee|payment|total|balance|deductible)\\s*(?:of|:)?\\s*\\$[\\d,]+\\.?\\d*", "labeled amount"),
        ]

        for (pattern, _) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let matchText = String(text[range])
                        results.append((matchText, matchText))
                    }
                }
            }
        }

        return results
    }

    private func extractDates(from text: String) -> [(label: String, value: String)] {
        var results: [(String, String)] = []
        let datePattern = "\\d{1,2}/\\d{1,2}/\\d{2,4}|\\w+ \\d{1,2},? \\d{4}"

        if let regex = try? NSRegularExpression(pattern: datePattern, options: []) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let dateStr = String(text[range])
                    results.append(("date", dateStr))
                }
            }
        }

        return results
    }

    // MARK: - Comparison Helpers

    private func compareAmounts(
        amountsA: [(label: String, value: String)],
        amountsB: [(label: String, value: String)]
    ) -> [ComparisonDifference] {
        var differences: [ComparisonDifference] = []

        let setA = Set(amountsA.map { $0.value })
        let setB = Set(amountsB.map { $0.value })

        let onlyInA = setA.subtracting(setB)
        let onlyInB = setB.subtracting(setA)

        for amount in onlyInA {
            differences.append(ComparisonDifference(
                category: .financial,
                label: "Amount in Document A only",
                documentAValue: amount,
                documentBValue: "Not found",
                severity: 0.6
            ))
        }

        for amount in onlyInB {
            differences.append(ComparisonDifference(
                category: .financial,
                label: "Amount in Document B only",
                documentAValue: "Not found",
                documentBValue: amount,
                severity: 0.6
            ))
        }

        return differences
    }

    private func compareDates(
        datesA: [(label: String, value: String)],
        datesB: [(label: String, value: String)]
    ) -> [ComparisonDifference] {
        var differences: [ComparisonDifference] = []

        let setA = Set(datesA.map { $0.value })
        let setB = Set(datesB.map { $0.value })

        let onlyInA = setA.subtracting(setB)
        let onlyInB = setB.subtracting(setA)

        for date in onlyInA {
            differences.append(ComparisonDifference(
                category: .date,
                label: "Date in Document A only",
                documentAValue: date,
                documentBValue: "Not found",
                severity: 0.5
            ))
        }

        for date in onlyInB {
            differences.append(ComparisonDifference(
                category: .date,
                label: "Date in Document B only",
                documentAValue: "Not found",
                documentBValue: date,
                severity: 0.5
            ))
        }

        return differences
    }

    private func compareKeyTerms(textA: String, textB: String) -> [ComparisonDifference] {
        var differences: [ComparisonDifference] = []

        let importantTerms = [
            ("non-compete", DifferenceCategory.legal, 0.8),
            ("arbitration", DifferenceCategory.legal, 0.8),
            ("automatic renewal", DifferenceCategory.term, 0.7),
            ("early termination", DifferenceCategory.term, 0.7),
            ("late fee", DifferenceCategory.financial, 0.6),
            ("penalty", DifferenceCategory.financial, 0.7),
            ("liability", DifferenceCategory.legal, 0.6),
            ("indemnif", DifferenceCategory.legal, 0.7),
            ("waiver", DifferenceCategory.legal, 0.6),
            ("confidential", DifferenceCategory.legal, 0.5),
            ("severance", DifferenceCategory.financial, 0.7),
            ("probation", DifferenceCategory.term, 0.5),
            ("exclusion", DifferenceCategory.coverage, 0.7),
            ("deductible", DifferenceCategory.financial, 0.6),
        ]

        for (term, category, severity) in importantTerms {
            let inA = textA.contains(term)
            let inB = textB.contains(term)

            if inA && !inB {
                differences.append(ComparisonDifference(
                    category: category,
                    label: "Term '\(term)' found only in Document A",
                    documentAValue: "Present",
                    documentBValue: "Not found",
                    severity: severity
                ))
            } else if !inA && inB {
                differences.append(ComparisonDifference(
                    category: category,
                    label: "Term '\(term)' found only in Document B",
                    documentAValue: "Not found",
                    documentBValue: "Present",
                    severity: severity
                ))
            }
        }

        return differences
    }

    private func computeSimilarity(textA: String, textB: String) -> Double {
        let wordsA = Set(textA.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }).map(String.init))
        let wordsB = Set(textB.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation }).map(String.init))

        guard !wordsA.isEmpty || !wordsB.isEmpty else { return 1.0 }

        let intersection = wordsA.intersection(wordsB).count
        let union = wordsA.union(wordsB).count

        guard union > 0 else { return 0.0 }
        return Double(intersection) / Double(union)
    }

    private func buildSummary(
        documentATitle: String,
        documentBTitle: String,
        differences: [ComparisonDifference],
        similarity: Double
    ) -> String {
        let similarityPercent = Int(similarity * 100)
        let criticalCount = differences.filter { $0.severity >= 0.7 }.count
        let financialCount = differences.filter { $0.category == .financial }.count
        let legalCount = differences.filter { $0.category == .legal }.count

        var parts: [String] = []

        parts.append("These documents are \(similarityPercent)% similar.")

        if differences.isEmpty {
            parts.append("No significant differences were detected.")
        } else {
            parts.append("Found \(differences.count) difference\(differences.count == 1 ? "" : "s").")

            if criticalCount > 0 {
                parts.append("\(criticalCount) critical difference\(criticalCount == 1 ? "" : "s") require\(criticalCount == 1 ? "s" : "") attention.")
            }
            if financialCount > 0 {
                parts.append("\(financialCount) financial difference\(financialCount == 1 ? "" : "s") found.")
            }
            if legalCount > 0 {
                parts.append("\(legalCount) legal difference\(legalCount == 1 ? "" : "s") found.")
            }
        }

        return parts.joined(separator: " ")
    }
}
