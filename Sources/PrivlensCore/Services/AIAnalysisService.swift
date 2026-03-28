import Foundation

#if canImport(FoundationModels)
import FoundationModels

public final class AIAnalysisService: Sendable {

    public init() {}

    /// Analyzes document text using Apple Foundation Models, returning structured insights.
    public func analyzeDocument(text: String, type: DocumentType) async throws -> AnalysisResult {
        let session = LanguageModelSession()

        let prompt = buildPrompt(for: type, text: text)

        let response = try await session.respond(
            to: prompt,
            generating: AnalysisResult.self
        )

        return response.content
    }

    // MARK: - Prompt Templates

    private func buildPrompt(for type: DocumentType, text: String) -> String {
        let typeSpecificInstructions = typeInstructions(for: type)

        return """
        You are a document analysis assistant specializing in consumer protection. \
        Analyze the following document text and provide a structured analysis.

        Document Type: \(type.displayName)

        \(typeSpecificInstructions)

        General instructions:
        - Provide a concise 2-3 sentence summary
        - Extract key insights that are actionable and specific
        - Identify any red flags, hidden fees, unusual clauses, or concerning items
        - Suggest concrete action items the user should take
        - Classify the document type based on its content

        DOCUMENT TEXT:
        ---
        \(text)
        ---
        """
    }

    private func typeInstructions(for type: DocumentType) -> String {
        switch type {
        case .medicalBill:
            return """
            Medical Bill Analysis Instructions:
            - Check if the billed amount matches typical costs for the procedures listed
            - Look for duplicate charges or unbundled services (billing separately for things usually billed together)
            - Verify insurance adjustments are applied correctly
            - Identify any balance billing issues
            - Flag charges that seem unusually high
            - Note if an Explanation of Benefits (EOB) reference is present
            - Check for timely filing issues or appeals deadlines
            """

        case .lease:
            return """
            Lease Agreement Analysis Instructions:
            - Identify the lease term, rent amount, and security deposit
            - Flag any unusual clauses (e.g., automatic renewal, excessive penalties)
            - Check for tenant rights regarding maintenance, repairs, and habitability
            - Look for hidden fees (application fees, amenity fees, trash fees)
            - Identify notice requirements for move-out
            - Flag any clauses that may be unenforceable or illegal in common jurisdictions
            - Note pet policies, subletting rules, and guest restrictions
            """

        case .insurance:
            return """
            Insurance Document Analysis Instructions:
            - Identify the type of insurance (health, auto, home, life, etc.)
            - Extract coverage limits, deductibles, and premiums
            - Flag any coverage exclusions or limitations
            - Look for waiting periods or pre-existing condition clauses
            - Identify the claims process and deadlines
            - Note any automatic premium increase clauses
            - Check for cancellation terms and penalties
            """

        case .unknown:
            return """
            General Document Analysis Instructions:
            - Determine what type of document this is
            - Extract the most important information
            - Identify any commitments, obligations, or deadlines
            - Flag anything that seems unusual or potentially unfavorable
            """
        }
    }
}

#else

// Stub for non-Apple platforms
public final class AIAnalysisService: Sendable {
    public init() {}

    public func analyzeDocument(text: String, type: DocumentType) async throws -> AnalysisResult {
        throw AIAnalysisError.unavailable
    }
}

public enum AIAnalysisError: Error, LocalizedError, Sendable {
    case unavailable

    public var errorDescription: String? {
        return "AI analysis is not available on this platform. Requires Apple Foundation Models on iOS 26+."
    }
}
#endif
