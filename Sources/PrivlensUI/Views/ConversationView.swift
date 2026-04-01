#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct ConversationView: View {
    @State private var viewModel: ConversationViewModel
    @FocusState private var isInputFocused: Bool
    @State private var showClearConfirmation = false

    public init(document: Document) {
        self._viewModel = State(initialValue: ConversationViewModel(document: document))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.messages.isEmpty {
                            emptyState
                        }

                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            loadingIndicator
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Error banner
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            // Suggested questions
            if !viewModel.suggestedQuestions.isEmpty && viewModel.messages.count < 2 {
                suggestedQuestionsBar
            }

            Divider()

            // Input bar
            inputBar
        }
        .navigationTitle("Ask About Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showClearConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .disabled(viewModel.messages.isEmpty)
                .accessibilityLabel("Clear conversation")
            }
        }
        .alert("Clear Conversation?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                viewModel.clearConversation()
            }
        } message: {
            Text("This will delete your entire conversation history with this document. This cannot be undone.")
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Ask a Question")
                .font(.title2.bold())

            Text("Ask anything about this document. Answers are generated on-device using AI.")
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

    private var loadingIndicator: some View {
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

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.1))
    }

    private var suggestedQuestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.suggestedQuestions.prefix(4), id: \.self) { question in
                    Button {
                        Task {
                            await viewModel.sendSuggestedQuestion(question)
                        }
                    } label: {
                        Text(question)
                            .font(.caption)
                            .lineLimit(2)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.tint.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask a question...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .onSubmit {
                    if viewModel.canSend {
                        Task { await viewModel.sendMessage() }
                    }
                }
                .accessibilityLabel("Question input")

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.canSend ? .accentColor : .secondary)
            }
            .disabled(!viewModel.canSend)
            .accessibilityLabel("Send question")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
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

                // Source attributions for assistant messages
                if message.role == .assistant && !message.sourceAttributions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sources")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)

                        ForEach(
                            Array(message.sourceAttributions.prefix(3).enumerated()),
                            id: \.offset
                        ) { _, attribution in
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(attribution.matchedText.prefix(80) + (attribution.matchedText.count > 80 ? "..." : ""))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }
}
#endif
