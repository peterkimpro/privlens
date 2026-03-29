import Testing
import Foundation
@testable import PrivlensCore

@Suite("ConversationMessage Tests")
struct ConversationMessageTests {

    @Test("ConversationMessage initializes with correct defaults")
    func messageDefaults() {
        let message = ConversationMessage(role: .user, content: "Hello")
        #expect(message.role == .user)
        #expect(message.content == "Hello")
        #expect(message.sourceAttributions.isEmpty)
    }

    @Test("ConversationMessage preserves source attributions")
    func messageWithAttributions() {
        let attribution = SourceAttribution(
            chunkIndex: 0,
            startOffset: 10,
            endOffset: 20,
            matchedText: "test quote"
        )
        let message = ConversationMessage(
            role: .assistant,
            content: "Answer with quote",
            sourceAttributions: [attribution]
        )
        #expect(message.sourceAttributions.count == 1)
        #expect(message.sourceAttributions[0].matchedText == "test quote")
    }

    @Test("ConversationRole raw values are correct")
    func roleRawValues() {
        #expect(ConversationRole.user.rawValue == "user")
        #expect(ConversationRole.assistant.rawValue == "assistant")
    }

    @Test("ConversationMessage is Equatable")
    func messageEquatable() {
        let id = UUID()
        let date = Date()
        let msg1 = ConversationMessage(id: id, role: .user, content: "Hi", timestamp: date)
        let msg2 = ConversationMessage(id: id, role: .user, content: "Hi", timestamp: date)
        #expect(msg1 == msg2)
    }

    @Test("ConversationMessage is Codable")
    func messageCodable() throws {
        let original = ConversationMessage(role: .assistant, content: "Test response")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ConversationMessage.self, from: data)
        #expect(decoded.content == original.content)
        #expect(decoded.role == original.role)
        #expect(decoded.id == original.id)
    }
}

@Suite("ConversationContext Tests")
struct ConversationContextTests {

    @Test("ConversationContext tracks messages")
    func appendMessages() {
        var context = ConversationContext(
            documentId: UUID(),
            documentText: "Some document text here for testing.",
            documentType: .lease
        )
        #expect(context.messages.isEmpty)

        let msg = ConversationMessage(role: .user, content: "Question?")
        context.append(msg)
        #expect(context.messages.count == 1)
        #expect(context.messages[0].content == "Question?")
    }

    @Test("Suggested questions include type-specific questions for lease")
    func suggestedQuestionsLease() {
        let context = ConversationContext(
            documentId: UUID(),
            documentText: "Lease text",
            documentType: .lease
        )
        let questions = context.suggestedQuestions
        #expect(questions.count >= 3)
        #expect(questions.contains { $0.contains("tenant") || $0.contains("lease") })
    }

    @Test("Suggested questions include type-specific questions for medical bill")
    func suggestedQuestionsMedical() {
        let context = ConversationContext(
            documentId: UUID(),
            documentText: "Medical bill text",
            documentType: .medicalBill
        )
        let questions = context.suggestedQuestions
        #expect(questions.contains { $0.contains("insurance") || $0.contains("owe") })
    }

    @Test("Suggested questions include type-specific questions for new types")
    func suggestedQuestionsNewTypes() {
        let govContext = ConversationContext(
            documentId: UUID(),
            documentText: "Government form text",
            documentType: .governmentForm
        )
        #expect(govContext.suggestedQuestions.contains { $0.contains("documentation") || $0.contains("deadlines") })

        let loanContext = ConversationContext(
            documentId: UUID(),
            documentText: "Loan agreement text",
            documentType: .loanAgreement
        )
        #expect(loanContext.suggestedQuestions.contains { $0.contains("loan") || $0.contains("interest") || $0.contains("prepayment") })

        let homeContext = ConversationContext(
            documentId: UUID(),
            documentText: "Home purchase text",
            documentType: .homePurchase
        )
        #expect(homeContext.suggestedQuestions.contains { $0.contains("contingencies") || $0.contains("closing") })
    }
}

@Suite("ConversationService Tests")
struct ConversationServiceTests {

    let service = ConversationService()

    @Test("Throws error for empty question")
    func emptyQuestion() async {
        let context = ConversationContext(
            documentId: UUID(),
            documentText: "Some document text for testing purposes.",
            documentType: .unknown
        )
        await #expect(throws: ConversationError.emptyQuestion) {
            _ = try await service.ask(question: "   ", context: context)
        }
    }

    @Test("Throws error for whitespace-only question")
    func whitespaceQuestion() async {
        let context = ConversationContext(
            documentId: UUID(),
            documentText: "Some document text for testing purposes.",
            documentType: .unknown
        )
        await #expect(throws: ConversationError.emptyQuestion) {
            _ = try await service.ask(question: "\n\t  ", context: context)
        }
    }

    @Test("Throws error for document too short")
    func documentTooShort() async {
        let context = ConversationContext(
            documentId: UUID(),
            documentText: "short",
            documentType: .unknown
        )
        await #expect(throws: ConversationError.documentTooShort) {
            _ = try await service.ask(question: "What is this?", context: context)
        }
    }

    @Test("Returns assistant message on valid input (stub platform)")
    func validQuestion() async throws {
        let context = ConversationContext(
            documentId: UUID(),
            documentText: "This is a sample lease agreement between landlord and tenant for the property at 123 Main St. Monthly rent is $2000.",
            documentType: .lease
        )
        let response = try await service.ask(question: "What is the monthly rent?", context: context)
        #expect(response.role == .assistant)
        #expect(!response.content.isEmpty)
    }

    @Test("Suggest follow-ups returns non-empty list")
    func suggestFollowUps() async throws {
        let context = ConversationContext(
            documentId: UUID(),
            documentText: "This is a sample document with enough text to analyze properly for testing.",
            documentType: .insurance
        )
        let suggestions = try await service.suggestFollowUps(context: context)
        #expect(!suggestions.isEmpty)
    }
}

@Suite("ConversationError Tests")
struct ConversationErrorTests {

    @Test("Error descriptions are non-empty")
    func errorDescriptions() {
        #expect(ConversationError.unavailable.errorDescription != nil)
        #expect(ConversationError.emptyQuestion.errorDescription != nil)
        #expect(ConversationError.documentTooShort.errorDescription != nil)
    }
}
