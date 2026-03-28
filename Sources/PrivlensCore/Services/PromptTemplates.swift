import Foundation

/// Prompt templates for on-device AI document analysis.
public enum PromptTemplates: Sendable {

    /// Builds a prompt for analyzing a single text chunk.
    ///
    /// The prompt instructs the model to identify:
    /// - PII (personally identifiable information)
    /// - Financial terms and amounts
    /// - Legal obligations and clauses
    /// - Key dates and deadlines
    /// - Risks and red flags
    /// - Actionable recommendations
    public static func chunkAnalysisPrompt(text: String, documentType: String?) -> String {
        let typeContext: String
        if let documentType, !documentType.isEmpty {
            typeContext = "Document Type: \(documentType)\n\n"
        } else {
            typeContext = ""
        }

        return """
        You are a document analysis assistant specializing in consumer protection. \
        Analyze the following text chunk and extract structured insights.

        \(typeContext)\
        For each insight you find, provide:
        1. A short title (under 10 words)
        2. A detailed description explaining why it matters
        3. A category: one of personalInfo, financialInfo, legalClause, expirationDate, obligation, risk, recommendation, keyTerm, other
        4. A severity from 0.0 (purely informational) to 1.0 (critical / requires immediate action)
        5. A short direct quote from the text that supports this insight

        Focus on identifying:
        - **Personal Information (PII):** Names, addresses, SSNs, phone numbers, email addresses, \
        account numbers, dates of birth, or any data that could identify an individual.
        - **Financial Terms:** Dollar amounts, fees, interest rates, penalties, payment schedules, \
        refund policies, price escalation clauses, hidden charges.
        - **Legal Obligations:** Binding commitments, warranties, indemnification clauses, \
        liability limitations, arbitration clauses, non-compete terms, confidentiality requirements.
        - **Key Dates:** Deadlines, expiration dates, renewal dates, notice periods, \
        statute of limitations, grace periods, effective dates.
        - **Risks & Red Flags:** Unusual clauses, one-sided terms, automatic renewals, \
        penalty clauses, waiver of rights, ambiguous language, missing protections.
        - **Recommendations:** Specific actions the user should take, items to negotiate, \
        questions to ask, things to verify independently.

        Be thorough but precise. Only report insights that are clearly supported by the text. \
        Include a direct quote for every insight.

        TEXT CHUNK:
        ---
        \(text)
        ---
        """
    }

    /// Builds a prompt for generating a meta-summary across all analyzed insights.
    ///
    /// - Parameters:
    ///   - insights: String descriptions of insights gathered from all chunks.
    ///   - documentType: Optional document type for additional context.
    /// - Returns: A prompt string for summary generation.
    public static func summaryPrompt(insights: [String], documentType: String?) -> String {
        let typeContext: String
        if let documentType, !documentType.isEmpty {
            typeContext = " for this \(documentType)"
        } else {
            typeContext = ""
        }

        let insightList = insights.enumerated().map { index, insight in
            "\(index + 1). \(insight)"
        }.joined(separator: "\n")

        return """
        You are a document analysis assistant. Based on the following insights extracted \
        from a document, write a clear and concise summary\(typeContext).

        The summary should:
        - Be 2-4 sentences long
        - Highlight the most important findings
        - Call out any critical risks or red flags
        - Mention key financial obligations or deadlines if present
        - Be written in plain language that a non-expert can understand
        - End with the single most important action the user should take

        EXTRACTED INSIGHTS:
        ---
        \(insightList)
        ---

        Write the summary now:
        """
    }
}
