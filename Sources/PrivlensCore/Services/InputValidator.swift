import Foundation

// MARK: - ValidationError

/// Errors from input validation.
public enum ValidationError: Error, LocalizedError, Sendable {
    case emptyText
    case textTooShort(minimum: Int, actual: Int)
    case textTooLong(maximum: Int, actual: Int)
    case noReadableContent
    case unsupportedCharacterRatio(Double)

    public var errorDescription: String? {
        switch self {
        case .emptyText:
            return "The document text is empty. Please scan a document with visible text."
        case .textTooShort(let minimum, let actual):
            return "The document text is too short (\(actual) characters). At least \(minimum) characters are needed for meaningful analysis."
        case .textTooLong(let maximum, let actual):
            return "The document text is very large (\(actual) characters, maximum \(maximum)). Consider scanning fewer pages."
        case .noReadableContent:
            return "No readable text was found in the document. The scan may be blurry or the document may contain only images."
        case .unsupportedCharacterRatio(let ratio):
            return String(format: "The document contains %.0f%% unrecognized characters. The scan quality may be too low.", ratio * 100)
        }
    }
}

// MARK: - ValidationResult

/// Result of an input validation check.
public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let warnings: [String]
    public let sanitizedText: String?

    public static let valid = ValidationResult(isValid: true, warnings: [], sanitizedText: nil)

    public init(isValid: Bool, warnings: [String], sanitizedText: String?) {
        self.isValid = isValid
        self.warnings = warnings
        self.sanitizedText = sanitizedText
    }
}

// MARK: - InputValidatorProtocol

/// Protocol for document input validation.
public protocol InputValidatorProtocol: Sendable {
    /// Validates document text for analysis readiness.
    func validateDocumentText(_ text: String) -> ValidationResult

    /// Sanitizes OCR output text by removing artifacts and normalizing whitespace.
    func sanitizeOCRText(_ text: String) -> String

    /// Validates a document title.
    func validateTitle(_ title: String) -> String
}

// MARK: - InputValidator

/// Validates and sanitizes document inputs before analysis.
public final class InputValidator: InputValidatorProtocol, Sendable {

    /// Minimum character count for meaningful analysis.
    public static let minimumTextLength = 20

    /// Maximum character count before warning.
    public static let maximumTextLength = 500_000

    /// Maximum ratio of non-printable/garbage characters before flagging.
    public static let maxGarbageRatio = 0.4

    /// Maximum title length.
    public static let maxTitleLength = 200

    public init() {}

    public func validateDocumentText(_ text: String) -> ValidationResult {
        var warnings: [String] = []

        // Check empty
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ValidationResult(isValid: false, warnings: ["Document text is empty."], sanitizedText: nil)
        }

        // Check minimum length
        guard trimmed.count >= Self.minimumTextLength else {
            return ValidationResult(
                isValid: false,
                warnings: ["Document text is too short for analysis (\(trimmed.count) characters)."],
                sanitizedText: nil
            )
        }

        // Check maximum length
        if trimmed.count > Self.maximumTextLength {
            warnings.append("Document is very large (\(trimmed.count) characters). Analysis may take longer.")
        }

        // Check character quality - ratio of printable characters
        let printableCount = trimmed.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) ||
            CharacterSet.punctuationCharacters.contains(scalar) ||
            CharacterSet.whitespaces.contains(scalar)
        }.count

        let totalCount = trimmed.unicodeScalars.count
        let garbageRatio = totalCount > 0 ? 1.0 - (Double(printableCount) / Double(totalCount)) : 0.0

        if garbageRatio > Self.maxGarbageRatio {
            warnings.append(String(format: "Document contains %.0f%% unrecognized characters. OCR quality may be low.", garbageRatio * 100))
        }

        // Check for readable words (at least some word-like content)
        let wordPattern = trimmed.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        let readableWords = wordPattern.filter { word in
            word.count >= 2 && word.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "'" }
        }

        if readableWords.count < 3 {
            return ValidationResult(
                isValid: false,
                warnings: ["No readable content found in the document."],
                sanitizedText: nil
            )
        }

        let sanitized = sanitizeOCRText(trimmed)
        return ValidationResult(isValid: true, warnings: warnings, sanitizedText: sanitized)
    }

    public func sanitizeOCRText(_ text: String) -> String {
        var result = text

        // Normalize line endings
        result = result.replacingOccurrences(of: "\r\n", with: "\n")
        result = result.replacingOccurrences(of: "\r", with: "\n")

        // Collapse multiple blank lines into at most two
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        // Collapse multiple spaces into single space
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        // Remove leading/trailing whitespace per line
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        result = lines.map { line in
            String(line).trimmingCharacters(in: .whitespaces)
        }.joined(separator: "\n")

        // Final trim
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result
    }

    public func validateTitle(_ title: String) -> String {
        var cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.isEmpty {
            cleaned = "Untitled Document"
        }

        if cleaned.count > Self.maxTitleLength {
            cleaned = String(cleaned.prefix(Self.maxTitleLength))
        }

        return cleaned
    }
}
