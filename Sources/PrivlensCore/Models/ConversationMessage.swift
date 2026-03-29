import Foundation

// MARK: - ConversationRole

public enum ConversationRole: String, Codable, Sendable {
    case user
    case assistant
}

// MARK: - ConversationMessage

public struct ConversationMessage: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let role: ConversationRole
    public let content: String
    public let timestamp: Date
    public let sourceAttributions: [SourceAttribution]

    public init(
        id: UUID = UUID(),
        role: ConversationRole,
        content: String,
        timestamp: Date = Date(),
        sourceAttributions: [SourceAttribution] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.sourceAttributions = sourceAttributions
    }
}

// MARK: - ConversationContext

/// Holds the conversation history and document context for a Q&A session.
public struct ConversationContext: Sendable {
    public let documentId: UUID
    public let documentText: String
    public let documentType: DocumentType
    public private(set) var messages: [ConversationMessage]

    public init(
        documentId: UUID,
        documentText: String,
        documentType: DocumentType,
        messages: [ConversationMessage] = []
    ) {
        self.documentId = documentId
        self.documentText = documentText
        self.documentType = documentType
        self.messages = messages
    }

    public mutating func append(_ message: ConversationMessage) {
        messages.append(message)
    }

    /// Suggested starter questions based on the document type.
    public var suggestedQuestions: [String] {
        var questions: [String] = [
            "What are the key terms I should know about?",
            "Are there any red flags or concerning clauses?",
            "What deadlines or important dates should I be aware of?",
        ]

        switch documentType {
        case .medicalBill:
            questions.append(contentsOf: [
                "How much do I actually owe after insurance?",
                "Are there any billing errors I should dispute?",
            ])
        case .lease:
            questions.append(contentsOf: [
                "What are my rights as a tenant under this lease?",
                "What happens if I need to break this lease early?",
            ])
        case .insurance:
            questions.append(contentsOf: [
                "What is NOT covered by this policy?",
                "How do I file a claim?",
            ])
        case .taxForm:
            questions.append(contentsOf: [
                "What is my total tax liability?",
                "Are there any deductions I might be missing?",
            ])
        case .employmentContract:
            questions.append(contentsOf: [
                "What restrictive covenants am I agreeing to?",
                "What are the termination conditions?",
            ])
        case .nda:
            questions.append(contentsOf: [
                "How long does this NDA last?",
                "What information is excluded from confidentiality?",
            ])
        case .governmentForm:
            questions.append(contentsOf: [
                "What documentation do I need to complete this form?",
                "What are the deadlines for submission?",
            ])
        case .loanAgreement:
            questions.append(contentsOf: [
                "What is the total cost of this loan including interest?",
                "Are there prepayment penalties?",
            ])
        case .homePurchase:
            questions.append(contentsOf: [
                "What contingencies protect me in this agreement?",
                "What closing costs am I responsible for?",
            ])
        case .unknown:
            questions.append("What type of document is this?")
        }

        return questions
    }
}
