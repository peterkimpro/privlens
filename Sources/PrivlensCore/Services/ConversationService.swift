import Foundation

// MARK: - Protocol

/// Protocol for conversational document Q&A services.
public protocol ConversationServiceProtocol: Sendable {
    /// Sends a user question about a document and returns an assistant response with source attributions.
    func ask(
        question: String,
        context: ConversationContext
    ) async throws -> ConversationMessage

    /// Generates suggested follow-up questions based on the conversation so far.
    func suggestFollowUps(
        context: ConversationContext
    ) async throws -> [String]
}

// MARK: - Errors

public enum ConversationError: Error, LocalizedError, Sendable {
    case unavailable
    case emptyQuestion
    case documentTooShort

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Conversational Q&A is not available on this platform. Requires Apple Foundation Models on iOS 26+."
        case .emptyQuestion:
            return "Please enter a question."
        case .documentTooShort:
            return "The document text is too short to answer questions about."
        }
    }
}

// MARK: - Implementation

#if ENABLE_FOUNDATION_MODELS
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
public final class ConversationService: ConversationServiceProtocol, Sendable {

    public init() {}

    public func ask(
        question: String,
        context: ConversationContext
    ) async throws -> ConversationMessage {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ConversationError.emptyQuestion
        }
        guard context.documentText.count >= 10 else {
            throw ConversationError.documentTooShort
        }

        let session = LanguageModelSession()
        let prompt = buildPrompt(question: trimmed, context: context)

        let response = try await session.respond(to: prompt)
        let answerText = response.content

        // Extract source attributions by finding quoted passages in the answer
        let attributions = extractAttributions(from: answerText, documentText: context.documentText)

        return ConversationMessage(
            role: .assistant,
            content: answerText,
            sourceAttributions: attributions
        )
    }

    public func suggestFollowUps(
        context: ConversationContext
    ) async throws -> [String] {
        let session = LanguageModelSession()
        let prompt = buildFollowUpPrompt(context: context)

        let response = try await session.respond(to: prompt)
        let lines = response.content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { line -> String in
                // Strip leading numbering like "1. " or "- "
                var cleaned = line
                if let range = cleaned.range(of: #"^\d+[\.\)]\s*"#, options: .regularExpression) {
                    cleaned.removeSubrange(range)
                }
                if cleaned.hasPrefix("- ") {
                    cleaned = String(cleaned.dropFirst(2))
                }
                return cleaned
            }
            .filter { !$0.isEmpty }

        return Array(lines.prefix(4))
    }

    // MARK: - Private

    private func buildPrompt(question: String, context: ConversationContext) -> String {
        let historySection: String
        if context.messages.isEmpty {
            historySection = ""
        } else {
            let history = context.messages.suffix(10).map { msg in
                "\(msg.role == .user ? "User" : "Assistant"): \(msg.content)"
            }.joined(separator: "\n\n")
            historySection = """

            CONVERSATION HISTORY:
            ---
            \(history)
            ---

            """
        }

        // Limit document text to avoid exceeding context
        let docSnippet = String(context.documentText.prefix(8000))

        return """
        You are a helpful document analysis assistant. The user has scanned a \
        \(context.documentType.displayName) and wants to ask questions about it.

        Answer the user's question based ONLY on the document text provided below. \
        When possible, quote relevant passages from the document to support your answer. \
        Use quotation marks around direct quotes from the document. \
        If the answer is not in the document, say so clearly.

        IMPORTANT: Respond in plain, natural language only. Do NOT use any markdown \
        formatting — no bold (**), no italic (*), no numbered lists (1. 2. 3.), \
        no bullet points (- or *), no headers (#), no code blocks, and no JSON. \
        Just write naturally as if you're talking to someone.

        DOCUMENT TEXT:
        ---
        \(docSnippet)
        ---
        \(historySection)
        User question: \(question)
        """
    }

    private func buildFollowUpPrompt(context: ConversationContext) -> String {
        let recentHistory = context.messages.suffix(4).map { msg in
            "\(msg.role == .user ? "User" : "Assistant"): \(msg.content)"
        }.joined(separator: "\n")

        return """
        Based on the following conversation about a \(context.documentType.displayName), \
        suggest 3-4 natural follow-up questions the user might want to ask next. \
        Return each question on its own line. Do not add numbering or bullets.

        Recent conversation:
        \(recentHistory)
        """
    }

    private func extractAttributions(from answer: String, documentText: String) -> [SourceAttribution] {
        // Find quoted text in the answer and match against the document
        var attributions: [SourceAttribution] = []
        let pattern = #""([^"]{10,200})""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let nsAnswer = answer as NSString
        let matches = regex.matches(in: answer, range: NSRange(location: 0, length: nsAnswer.length))

        let docLower = documentText.lowercased()
        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            let quotedText = nsAnswer.substring(with: match.range(at: 1))
            let quotedLower = quotedText.lowercased()

            if let range = docLower.range(of: quotedLower) {
                let startOffset = docLower.distance(from: docLower.startIndex, to: range.lowerBound)
                let endOffset = docLower.distance(from: docLower.startIndex, to: range.upperBound)
                let originalText = String(documentText[range])

                let attribution = SourceAttribution(
                    chunkIndex: 0,
                    startOffset: startOffset,
                    endOffset: endOffset,
                    matchedText: originalText,
                    pageIndex: nil
                )
                if !attributions.contains(attribution) {
                    attributions.append(attribution)
                }
            }
        }

        return attributions
    }
}

#else

// MARK: - Linux / non-Apple platform stub

public final class ConversationService: ConversationServiceProtocol, Sendable {

    public init() {}

    public func ask(
        question: String,
        context: ConversationContext
    ) async throws -> ConversationMessage {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ConversationError.emptyQuestion
        }
        guard context.documentText.count >= 10 else {
            throw ConversationError.documentTooShort
        }

        // Return a mock response on non-Apple platforms
        let snippet = String(context.documentText.prefix(100))
        let mockAnswer = "This is a mock response on a non-Apple platform. "
            + "Real conversational Q&A requires Apple Foundation Models on iOS 26+. "
            + "The document begins with: \"\(snippet)...\""

        let attribution = SourceAttribution(
            chunkIndex: 0,
            startOffset: 0,
            endOffset: min(100, context.documentText.count),
            matchedText: snippet,
            pageIndex: nil
        )

        return ConversationMessage(
            role: .assistant,
            content: mockAnswer,
            sourceAttributions: [attribution]
        )
    }

    public func suggestFollowUps(
        context: ConversationContext
    ) async throws -> [String] {
        return context.suggestedQuestions.suffix(3)
    }
}

#endif
