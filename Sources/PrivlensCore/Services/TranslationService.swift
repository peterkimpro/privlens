import Foundation

// MARK: - TranslationError

public enum TranslationError: Error, LocalizedError, Sendable {
    case unavailable
    case translationFailed(String)
    case sameLanguage

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Translation is not available on this platform. Requires Apple Foundation Models on iOS 26+."
        case .translationFailed(let reason):
            return "Translation failed: \(reason)"
        case .sameLanguage:
            return "Source and target languages are the same. No translation needed."
        }
    }
}

// MARK: - TranslationServiceProtocol

/// Protocol for translating analysis results to the user's preferred language.
public protocol TranslationServiceProtocol: Sendable {
    /// Translates the given text from the source language to the target language.
    func translate(
        text: String,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) async throws -> String

    /// Translates an entire analysis result to the target language.
    func translateAnalysisResult(
        _ result: AnalysisResult,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) async throws -> AnalysisResult
}

// MARK: - Implementation

#if ENABLE_FOUNDATION_MODELS
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
public final class TranslationService: TranslationServiceProtocol, Sendable {

    public init() {}

    public func translate(
        text: String,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) async throws -> String {
        guard source != target else {
            throw TranslationError.sameLanguage
        }

        let session = LanguageModelSession()
        let prompt = buildTranslationPrompt(text: text, from: source, to: target)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    public func translateAnalysisResult(
        _ result: AnalysisResult,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) async throws -> AnalysisResult {
        guard source != target else {
            throw TranslationError.sameLanguage
        }

        let translatedSummary = try await translate(text: result.summary, from: source, to: target)

        var translatedInsights: [String] = []
        for insight in result.keyInsights {
            let translated = try await translate(text: insight, from: source, to: target)
            translatedInsights.append(translated)
        }

        var translatedRedFlags: [String] = []
        for flag in result.redFlags {
            let translated = try await translate(text: flag, from: source, to: target)
            translatedRedFlags.append(translated)
        }

        var translatedActionItems: [String] = []
        for item in result.actionItems {
            let translated = try await translate(text: item, from: source, to: target)
            translatedActionItems.append(translated)
        }

        return AnalysisResult(
            summary: translatedSummary,
            keyInsights: translatedInsights,
            redFlags: translatedRedFlags,
            actionItems: translatedActionItems,
            documentType: result.documentType
        )
    }

    private func buildTranslationPrompt(
        text: String,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) -> String {
        """
        Translate the following text from \(source.displayName) to \(target.displayName). \
        Preserve all formatting, numbers, and technical terms. \
        Only output the translated text, nothing else.

        TEXT:
        \(text)
        """
    }
}

#else

// MARK: - Linux / non-Apple platform stub

public final class TranslationService: TranslationServiceProtocol, Sendable {

    public init() {}

    public func translate(
        text: String,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) async throws -> String {
        guard source != target else {
            throw TranslationError.sameLanguage
        }
        throw TranslationError.unavailable
    }

    public func translateAnalysisResult(
        _ result: AnalysisResult,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) async throws -> AnalysisResult {
        guard source != target else {
            throw TranslationError.sameLanguage
        }
        throw TranslationError.unavailable
    }
}

#endif
