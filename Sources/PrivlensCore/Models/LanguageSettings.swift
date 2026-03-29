import Foundation

// MARK: - SupportedLanguage

/// Languages supported for document analysis and translation.
public enum SupportedLanguage: String, Codable, Sendable, CaseIterable, Hashable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"

    public var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .chinese: return "Chinese"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        }
    }

    public var nativeDisplayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Espa\u{00F1}ol"
        case .french: return "Fran\u{00E7}ais"
        case .german: return "Deutsch"
        case .chinese: return "\u{4E2D}\u{6587}"
        case .japanese: return "\u{65E5}\u{672C}\u{8A9E}"
        case .korean: return "\u{D55C}\u{AD6D}\u{C5B4}"
        }
    }

    /// BCP 47 language tag.
    public var languageTag: String {
        rawValue
    }
}

// MARK: - LanguageDetectionResult

/// Result of language detection on OCR text.
public struct LanguageDetectionResult: Codable, Sendable, Hashable {
    /// The most likely detected language.
    public let primaryLanguage: SupportedLanguage
    /// Confidence score from 0.0 to 1.0.
    public let confidence: Double
    /// All detected languages with their confidence scores, ordered by confidence.
    public let detectedLanguages: [(language: SupportedLanguage, confidence: Double)]

    public init(
        primaryLanguage: SupportedLanguage,
        confidence: Double,
        detectedLanguages: [(language: SupportedLanguage, confidence: Double)] = []
    ) {
        self.primaryLanguage = primaryLanguage
        self.confidence = confidence
        self.detectedLanguages = detectedLanguages
    }

    // MARK: - Codable conformance for tuple array

    enum CodingKeys: String, CodingKey {
        case primaryLanguage, confidence, detectedLanguagesList
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        primaryLanguage = try container.decode(SupportedLanguage.self, forKey: .primaryLanguage)
        confidence = try container.decode(Double.self, forKey: .confidence)
        let pairs = try container.decode([LanguageConfidencePair].self, forKey: .detectedLanguagesList)
        detectedLanguages = pairs.map { ($0.language, $0.confidence) }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(primaryLanguage, forKey: .primaryLanguage)
        try container.encode(confidence, forKey: .confidence)
        let pairs = detectedLanguages.map { LanguageConfidencePair(language: $0.language, confidence: $0.confidence) }
        try container.encode(pairs, forKey: .detectedLanguagesList)
    }

    // MARK: - Hashable conformance for tuple array

    public static func == (lhs: LanguageDetectionResult, rhs: LanguageDetectionResult) -> Bool {
        lhs.primaryLanguage == rhs.primaryLanguage && lhs.confidence == rhs.confidence
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(primaryLanguage)
        hasher.combine(confidence)
    }
}

/// Helper for encoding language-confidence pairs.
private struct LanguageConfidencePair: Codable, Sendable {
    let language: SupportedLanguage
    let confidence: Double
}

// MARK: - LanguageSettings

/// User preferences for language detection and translation.
public struct LanguageSettings: Codable, Sendable, Hashable {
    /// The user's preferred language for analysis output.
    public var preferredLanguage: SupportedLanguage
    /// Whether to automatically detect the document's language.
    public var autoDetectLanguage: Bool
    /// Whether to automatically translate analysis results to the preferred language.
    public var autoTranslateResults: Bool

    public init(
        preferredLanguage: SupportedLanguage = .english,
        autoDetectLanguage: Bool = true,
        autoTranslateResults: Bool = false
    ) {
        self.preferredLanguage = preferredLanguage
        self.autoDetectLanguage = autoDetectLanguage
        self.autoTranslateResults = autoTranslateResults
    }

    /// Default settings with English and auto-detect enabled.
    public static let `default` = LanguageSettings()
}
