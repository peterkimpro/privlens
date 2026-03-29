#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

@Observable
@MainActor
public final class ConversationViewModel {
    public var messages: [ConversationMessage] = []
    public var inputText: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var suggestedQuestions: [String] = []

    private var context: ConversationContext
    private let conversationService: ConversationServiceProtocol

    public init(
        document: Document,
        conversationService: ConversationServiceProtocol = ConversationService()
    ) {
        self.context = ConversationContext(
            documentId: document.id,
            documentText: document.rawText,
            documentType: document.documentType
        )
        self.conversationService = conversationService
        self.suggestedQuestions = context.suggestedQuestions
    }

    public var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    public func sendMessage() async {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        let userMessage = ConversationMessage(role: .user, content: question)
        messages.append(userMessage)
        context.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        do {
            let response = try await conversationService.ask(
                question: question,
                context: context
            )
            messages.append(response)
            context.append(response)

            // Refresh suggested follow-ups
            if let followUps = try? await conversationService.suggestFollowUps(context: context) {
                suggestedQuestions = followUps
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func sendSuggestedQuestion(_ question: String) async {
        inputText = question
        await sendMessage()
    }

    public func clearConversation() {
        messages.removeAll()
        context = ConversationContext(
            documentId: context.documentId,
            documentText: context.documentText,
            documentType: context.documentType
        )
        suggestedQuestions = context.suggestedQuestions
        errorMessage = nil
    }
}

#else

import Foundation
#if canImport(PrivlensCore)
import PrivlensCore
#endif

@MainActor
public final class ConversationViewModel {
    public var messages: [ConversationMessage] = []
    public var inputText: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var suggestedQuestions: [String] = []
    public var canSend: Bool { false }

    public init() {}

    public func sendMessage() async {}
    public func sendSuggestedQuestion(_ question: String) async {}
    public func clearConversation() {}
}
#endif
