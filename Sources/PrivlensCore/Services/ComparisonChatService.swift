import Foundation

#if ENABLE_FOUNDATION_MODELS
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
public final class ComparisonChatService: Sendable {

    public init() {}

    public func ask(
        question: String,
        documentA: Document,
        documentB: Document,
        comparisonSummary: String,
        history: [ConversationMessage]
    ) async throws -> String {
        let session = LanguageModelSession()

        let maxChars = 3000
        let textA = String(documentA.rawText.prefix(maxChars))
        let textB = String(documentB.rawText.prefix(maxChars))

        var historySection = ""
        if !history.isEmpty {
            let recent = history.suffix(10).map { msg in
                "\(msg.role == .user ? "User" : "Assistant"): \(msg.content)"
            }.joined(separator: "\n\n")
            historySection = """

            CONVERSATION SO FAR:
            ---
            \(recent)
            ---

            """
        }

        let prompt = """
        You are a helpful document comparison assistant. The user has two documents and \
        wants to understand how they compare.

        DOCUMENT A ("\(documentA.title)"):
        ---
        \(textA)
        ---

        DOCUMENT B ("\(documentB.title)"):
        ---
        \(textB)
        ---

        COMPARISON SUMMARY:
        \(comparisonSummary)
        \(historySection)
        Answer the user's question about these two documents. Be specific — reference \
        actual content from the documents. Respond in plain, natural language. \
        Do not use any markdown formatting like bold, italic, numbered lists, or bullets. \
        Just write naturally as if talking to someone.

        User question: \(question)
        """

        let response = try await session.respond(to: prompt)

        // Strip any markdown the model might still produce
        return Self.stripMarkdown(response.content)
    }

    private static func stripMarkdown(_ text: String) -> String {
        var result = text
        let patterns: [(String, String)] = [
            (#"\*\*\*(.+?)\*\*\*"#, "$1"),
            (#"\*\*(.+?)\*\*"#, "$1"),
            (#"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, "$1"),
            (#"__(.+?)__"#, "$1"),
            (#"_(.+?)_"#, "$1"),
            (#"^#{1,6}\s+"#, ""),
            (#"^[\-\*]\s+"#, ""),
            (#"^\d+\.\s+"#, ""),
            (#"`(.+?)`"#, "$1"),
        ]
        for (pattern, replacement) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: replacement
                )
            }
        }
        return result
    }
}

#else

public final class ComparisonChatService: Sendable {
    public init() {}

    public func ask(
        question: String,
        documentA: Document,
        documentB: Document,
        comparisonSummary: String,
        history: [ConversationMessage]
    ) async throws -> String {
        return "Comparison chat requires Apple Foundation Models on iOS 26+."
    }
}

#endif
