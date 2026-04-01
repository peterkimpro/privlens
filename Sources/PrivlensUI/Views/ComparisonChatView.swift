#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct ComparisonChatView: View {
    let documentA: Document
    let documentB: Document
    let comparisonSummary: String

    @State private var messages: [ConversationMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isInputFocused: Bool

    public init(documentA: Document, documentB: Document, comparisonSummary: String) {
        self.documentA = documentA
        self.documentB = documentB
        self.comparisonSummary = comparisonSummary
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            emptyState
                        }

                        ForEach(messages) { message in
                            ComparisonMessageBubble(message: message)
                                .id(message.id)
                        }

                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            if let error = errorMessage {
                HStack {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button { errorMessage = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.1))
            }

            // Suggested questions
            if messages.isEmpty {
                suggestedQuestions
            }

            Divider()

            // Input bar
            HStack(spacing: 12) {
                TextField("Ask about the differences...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .onSubmit { if canSend { Task { await sendMessage() } } }

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSend ? .accentColor : .secondary)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .navigationTitle("Compare Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Ask About Differences")
                .font(.title2.bold())

            Text("Ask questions about how \(documentA.title) and \(documentB.title) compare. Answers are generated on-device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text("Private & on-device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 40)
    }

    private var suggestedQuestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { question in
                    Button {
                        inputText = question
                        Task { await sendMessage() }
                    } label: {
                        Text(question)
                            .font(.caption)
                            .lineLimit(2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.tint.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var suggestions: [String] {
        [
            "Which document is the better deal?",
            "What are the biggest differences?",
            "Is there anything concerning in either document?",
            "What should I pay attention to?",
        ]
    }

    private func sendMessage() async {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        inputText = ""
        messages.append(ConversationMessage(role: .user, content: question))
        isLoading = true
        defer { isLoading = false }

        do {
            let answer = try await askAboutComparison(question: question)
            messages.append(ConversationMessage(role: .assistant, content: answer))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func askAboutComparison(question: String) async throws -> String {
        #if ENABLE_FOUNDATION_MODELS
        let service = ComparisonChatService()
        return try await service.ask(
            question: question,
            documentA: documentA,
            documentB: documentB,
            comparisonSummary: comparisonSummary,
            history: messages
        )
        #else
        return "Comparison chat requires Apple Foundation Models on iOS 26+."
        #endif
    }
}

struct ComparisonMessageBubble: View {
    let message: ConversationMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(message.role == .user ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }
}

#endif
