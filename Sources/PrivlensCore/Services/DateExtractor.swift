import Foundation

// MARK: - DateExtractor

/// Utility for extracting key dates from analysis results.
public enum DateExtractor: Sendable {

    /// Date keywords that indicate deadline-type dates.
    private static let dateKeywords: [(pattern: String, label: String)] = [
        ("due\\s+(?:date|by)", "Payment Due Date"),
        ("deadline", "Deadline"),
        ("expir(?:es?|ation|y)", "Expiration Date"),
        ("renewal\\s+date", "Renewal Date"),
        ("effective\\s+date", "Effective Date"),
        ("termination\\s+date", "Termination Date"),
        ("(?:start|begin(?:ning)?)\\s+date", "Start Date"),
        ("(?:end|ending)\\s+date", "End Date"),
        ("payment\\s+due", "Payment Due"),
        ("(?:move[- ]?in|move[- ]?out)\\s+date", "Move Date"),
        ("(?:open\\s+)?enrollment\\s+(?:date|deadline|period)", "Enrollment Deadline"),
        ("filing\\s+deadline", "Filing Deadline"),
        ("grace\\s+period\\s+(?:ends?|expir)", "Grace Period End"),
    ]

    /// Common date formats to try parsing.
    private static let dateFormats: [String] = [
        "MM/dd/yyyy",
        "M/d/yyyy",
        "MM-dd-yyyy",
        "yyyy-MM-dd",
        "MMMM d, yyyy",
        "MMM d, yyyy",
        "MMMM dd, yyyy",
        "MMM dd, yyyy",
        "MM/dd/yy",
        "M/d/yy",
    ]

    /// Extract dates from analysis result text, pairing date-related keywords with parsed dates.
    public static func extractDates(
        from result: AnalysisResult,
        documentId: UUID,
        documentTitle: String
    ) -> [ExtractedDate] {
        let allTextSources = [result.summary] + result.keyInsights + result.redFlags + result.actionItems
        var extractedDates: [ExtractedDate] = []
        var seenDateLabels: Set<String> = []

        for text in allTextSources {
            let found = extractDatesFromText(
                text,
                documentId: documentId,
                documentTitle: documentTitle
            )
            for date in found {
                let key = "\(date.label)-\(date.date.timeIntervalSince1970)"
                if !seenDateLabels.contains(key) {
                    seenDateLabels.insert(key)
                    extractedDates.append(date)
                }
            }
        }

        return extractedDates.sorted { $0.date < $1.date }
    }

    /// Parse a single text fragment for date patterns.
    private static func extractDatesFromText(
        _ text: String,
        documentId: UUID,
        documentTitle: String
    ) -> [ExtractedDate] {
        var results: [ExtractedDate] = []

        for (keywordPattern, label) in dateKeywords {
            // Look for keyword near a date-like string
            let combinedPattern = "\(keywordPattern)[:\\s]+([\\w/\\-,\\s]+)"
            guard let regex = try? NSRegularExpression(pattern: combinedPattern, options: [.caseInsensitive]) else {
                continue
            }

            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                guard match.numberOfRanges >= 2 else { continue }
                let dateCandidate = nsString.substring(with: match.range(at: 1))
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let parsedDate = parseDate(dateCandidate) {
                    let context = nsString.substring(with: match.range)
                    results.append(ExtractedDate(
                        date: parsedDate,
                        label: label,
                        context: context.trimmingCharacters(in: .whitespacesAndNewlines),
                        documentId: documentId,
                        documentTitle: documentTitle
                    ))
                }
            }
        }

        return results
    }

    /// Attempt to parse a date string using common formats.
    private static func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
            // Try with just the first portion of the string (up to first non-date character)
            let shortened = String(trimmed.prefix(format.count + 2))
            if let date = formatter.date(from: shortened.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return date
            }
        }

        return nil
    }
}
