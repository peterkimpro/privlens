#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import PrivlensCore

public struct DocumentDetailView: View {
    let document: Document
    @State private var selectedTab: DetailTab = .analysis
    @State private var copiedToast = false

    private enum DetailTab: String, CaseIterable {
        case analysis = "Analysis"
        case pages = "Pages"
        case rawText = "Raw Text"
    }

    public init(document: Document) {
        self.document = document
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("View", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            switch selectedTab {
            case .analysis:
                analysisTab
            case .pages:
                pagesTab
            case .rawText:
                rawTextTab
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: ConversationView(document: document)) {
                    Image(systemName: "bubble.left.and.bubble.right")
                }
                .accessibilityLabel("Ask questions about this document")
            }
        }
    }

    // MARK: - Analysis Tab

    private var analysisTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Chat with Document — prominent CTA
                NavigationLink(destination: ConversationView(document: document)) {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ask About This Document")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Chat with on-device AI to understand your document")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Document Info
                HStack {
                    Image(systemName: document.documentType.systemIcon)
                        .foregroundStyle(.tint)
                    Text(document.documentType.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(document.dateScanned, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Analysis Result
                if let analysisText = document.analysisResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                        Text(analysisText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Red Flags
                if !document.redFlags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Watch Out For", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)

                        ForEach(document.redFlags, id: \.self) { flag in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(flag)
                                    .font(.subheadline)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Key Insights
                if !document.keyInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Insights")
                            .font(.headline)

                        ForEach(document.keyInsights, id: \.self) { insight in
                            InsightCard(text: insight, icon: "lightbulb.fill", tint: .yellow)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Pages Tab

    private var pagesTab: some View {
        Group {
            if document.pageImageData.isEmpty {
                ContentUnavailableView(
                    "No Scanned Pages",
                    systemImage: "doc.richtext",
                    description: Text("Page images are not available for this document.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(document.pageImageData.enumerated()), id: \.offset) { index, data in
                            VStack(spacing: 8) {
                                Text("Page \(index + 1) of \(document.pageCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                #if canImport(UIKit)
                                if let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                                }
                                #endif
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Raw Text Tab

    private var rawTextTab: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    UIPasteboard.general.string = document.rawText
                    copiedToast = true
                } label: {
                    Label("Copy All", systemImage: "doc.on.doc")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            TextEditor(text: .constant(document.rawText))
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(.horizontal)
        }
        .overlay {
            if copiedToast {
                VStack {
                    Spacer()
                    Text("Copied to clipboard")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.75))
                        .clipShape(Capsule())
                        .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { copiedToast = false }
                    }
                }
            }
        }
        .animation(.easeInOut, value: copiedToast)
    }
}
#endif
