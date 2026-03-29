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

    /// Builds a document-type-specific analysis prompt with tailored extraction guidance.
    public static func typeSpecificPrompt(text: String, documentType: DocumentType) -> String {
        switch documentType {
        case .taxForm:
            return taxFormPrompt(text: text)
        case .employmentContract:
            return employmentContractPrompt(text: text)
        case .nda:
            return ndaPrompt(text: text)
        default:
            return chunkAnalysisPrompt(text: text, documentType: documentType.displayName)
        }
    }

    private static func taxFormPrompt(text: String) -> String {
        """
        You are a tax document analysis assistant. Analyze the following tax form and extract \
        structured insights.

        Focus specifically on:
        - **Income figures:** Gross income, wages, tips, other compensation, interest, dividends
        - **Tax withholding:** Federal, state, local taxes withheld, Social Security, Medicare
        - **Employer/payer information:** Employer name, EIN, address
        - **Filing status indicators:** W-2 vs 1099, employee vs contractor classification
        - **Deductions and credits:** Any referenced deductions, credits, or adjustments
        - **Key dates:** Tax year, filing deadlines, extension dates
        - **Red flags:** Discrepancies between reported amounts, missing information, \
        unusual entries, misclassification risks

        For each insight, provide a short title, detailed description, category, \
        severity (0.0-1.0), and a supporting quote from the text.

        TAX FORM TEXT:
        ---
        \(text)
        ---
        """
    }

    private static func employmentContractPrompt(text: String) -> String {
        """
        You are an employment contract analysis assistant. Analyze the following employment \
        agreement and extract structured insights.

        Focus specifically on:
        - **Compensation:** Base salary, bonus structure, equity/stock options, commission
        - **Benefits:** Health insurance, retirement (401k match), PTO/vacation, sick leave
        - **Employment terms:** At-will vs fixed term, probation period, start date
        - **Restrictive covenants:** Non-compete clauses (scope, duration, geography), \
        non-solicitation, non-disclosure obligations
        - **Termination:** Conditions for termination, notice periods, severance terms
        - **Intellectual property:** Work product ownership, invention assignment clauses
        - **Dispute resolution:** Arbitration clauses, governing law, venue
        - **Red flags:** One-sided terms, unusually broad non-competes, IP assignment \
        beyond work scope, waiver of class action rights

        For each insight, provide a short title, detailed description, category, \
        severity (0.0-1.0), and a supporting quote from the text.

        EMPLOYMENT CONTRACT TEXT:
        ---
        \(text)
        ---
        """
    }

    private static func ndaPrompt(text: String) -> String {
        """
        You are a non-disclosure agreement analysis assistant. Analyze the following NDA \
        and extract structured insights.

        Focus specifically on:
        - **Parties:** Disclosing party, receiving party, mutual vs unilateral
        - **Scope of confidentiality:** What information is covered, definitions of \
        confidential information
        - **Exclusions:** Publicly available info, independently developed, prior knowledge
        - **Duration:** Term of the agreement, survival period after termination
        - **Permitted disclosures:** Employees, agents, legal requirements, court orders
        - **Return/destruction:** Requirements to return or destroy confidential materials
        - **Remedies:** Injunctive relief, damages, indemnification
        - **Red flags:** Overly broad definitions, perpetual terms, one-sided obligations, \
        no carve-outs for legal compliance, residual knowledge restrictions

        For each insight, provide a short title, detailed description, category, \
        severity (0.0-1.0), and a supporting quote from the text.

        NDA TEXT:
        ---
        \(text)
        ---
        """
    }
}
