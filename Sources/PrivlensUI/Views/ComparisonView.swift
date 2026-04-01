#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct ComparisonView: View {
    @State private var viewModel = ComparisonViewModel()
    @State private var showDocumentPickerA = false
    @State private var showDocumentPickerB = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Document Selection
                    documentSelectionSection

                    // Compare Button
                    if viewModel.canCompare {
                        Button {
                            Task { await viewModel.runComparison() }
                        } label: {
                            if viewModel.isComparing {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label("Compare Documents", systemImage: "arrow.left.arrow.right")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(viewModel.isComparing)
                        .accessibilityIdentifier(AccessibilityIdentifiers.comparisonRunButton)
                    }

                    // Results
                    if let result = viewModel.comparisonResult {
                        comparisonResultView(result)
                    }

                    // Error
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding()
            }
            .navigationTitle("Compare")
            .accessibilityIdentifier(AccessibilityIdentifiers.comparisonView)
            .task {
                await viewModel.loadDocuments()
            }
            .sheet(isPresented: $showDocumentPickerA) {
                DocumentPickerSheet(
                    documents: viewModel.documents,
                    title: "Select Document A"
                ) { doc in
                    viewModel.selectedDocumentA = doc
                    showDocumentPickerA = false
                }
            }
            .sheet(isPresented: $showDocumentPickerB) {
                DocumentPickerSheet(
                    documents: viewModel.availableDocumentsForB,
                    title: "Select Document B"
                ) { doc in
                    viewModel.selectedDocumentB = doc
                    showDocumentPickerB = false
                }
            }
        }
    }

    // MARK: - Document Selection

    private var documentSelectionSection: some View {
        VStack(spacing: 12) {
            documentSelectionCard(
                label: "Document A",
                document: viewModel.selectedDocumentA,
                identifier: AccessibilityIdentifiers.comparisonSelectDocA
            ) {
                showDocumentPickerA = true
            }

            Image(systemName: "arrow.left.arrow.right")
                .font(.title2)
                .foregroundStyle(.secondary)

            documentSelectionCard(
                label: "Document B",
                document: viewModel.selectedDocumentB,
                identifier: AccessibilityIdentifiers.comparisonSelectDocB
            ) {
                showDocumentPickerB = true
            }
        }
    }

    private func documentSelectionCard(
        label: String,
        document: Document?,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let doc = document {
                        Text(doc.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(doc.documentType.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Tap to select")
                            .font(.headline)
                            .foregroundStyle(.tint)
                    }
                }

                Spacer()

                Image(systemName: document?.documentType.systemIcon ?? "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(document != nil ? .accentColor : .secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    // MARK: - Comparison Result

    private func comparisonResultView(_ result: PrivlensCore.ComparisonResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Not related banner
            if !result.areRelated {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("These are different types of documents and may not be directly comparable.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Similarity Score
            similarityIndicator(result.similarityScore)

            // Document types
            if !result.documentAType.isEmpty || !result.documentBType.isEmpty {
                HStack(spacing: 12) {
                    documentTypeTag(
                        title: viewModel.selectedDocumentA?.title ?? "Document A",
                        type: result.documentAType,
                        color: .blue
                    )
                    documentTypeTag(
                        title: viewModel.selectedDocumentB?.title ?? "Document B",
                        type: result.documentBType,
                        color: .indigo
                    )
                }
            }

            // Summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.headline)
                Text(result.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier(AccessibilityIdentifiers.comparisonSummary)

            // Per-document highlights
            if !result.highlightsA.isEmpty {
                documentHighlights(
                    title: viewModel.selectedDocumentA?.title ?? "Document A",
                    highlights: result.highlightsA,
                    color: .blue
                )
            }
            if !result.highlightsB.isEmpty {
                documentHighlights(
                    title: viewModel.selectedDocumentB?.title ?? "Document B",
                    highlights: result.highlightsB,
                    color: .indigo
                )
            }

            // Direct differences (only when documents are comparable)
            if !result.differences.isEmpty {
                differencesSection(result.differences)
            }

            // Ask AI about differences
            if let docA = viewModel.selectedDocumentA,
               let docB = viewModel.selectedDocumentB {
                NavigationLink(destination: ComparisonChatView(documentA: docA, documentB: docB, comparisonSummary: result.summary)) {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ask About Differences")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Chat with AI about how these documents compare")
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
            }

            // Export Button
            ShareLink(
                item: generateShareText(result),
                subject: Text("Privlens Comparison Report"),
                message: Text("Document comparison from Privlens")
            ) {
                Label("Share Comparison", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityLabel(AccessibilityLabels.exportComparison)
        }
    }

    private func similarityIndicator(_ score: Double) -> some View {
        let percent = Int(score * 100)

        return VStack(spacing: 8) {
            Text("\(percent)%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
            Text("Similarity")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(AccessibilityLabels.comparisonSummary(similarityPercent: percent))
    }

    private func documentTypeTag(title: String, type: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(type.isEmpty ? "Document" : type)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func documentHighlights(title: String, highlights: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: "eye.fill")
                .font(.headline)
                .foregroundStyle(color)

            ForEach(highlights, id: \.self) { highlight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(color)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(highlight)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func differencesSection(_ differences: [ComparisonDifference]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Key Differences", systemImage: "eye.fill")
                .font(.headline)
                .foregroundStyle(.blue)
                .accessibilityLabel(AccessibilityLabels.differenceCount(differences.count))

            ForEach(differences) { diff in
                differenceCard(diff)
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.comparisonDifferences)
    }

    private func differenceCard(_ diff: ComparisonDifference) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // What's different
            Text(diff.label)
                .font(.subheadline.bold())

            // Document A's version
            if !diff.documentAValue.isEmpty && diff.documentAValue != "Not found" {
                HStack(alignment: .top, spacing: 8) {
                    Text(viewModel.selectedDocumentA?.title ?? "Document A")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 70, alignment: .leading)
                    Text(diff.documentAValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Document B's version
            if !diff.documentBValue.isEmpty && diff.documentBValue != "Not found" {
                HStack(alignment: .top, spacing: 8) {
                    Text(viewModel.selectedDocumentB?.title ?? "Document B")
                        .font(.caption.bold())
                        .foregroundStyle(.indigo)
                        .frame(width: 70, alignment: .leading)
                    Text(diff.documentBValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AccessibilityLabels.differenceItem(label: diff.label))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func generateShareText(_ result: PrivlensCore.ComparisonResult) -> String {
        let exportService = PDFExportService()
        return exportService.generateTextReport(
            document: Document(
                title: result.documentATitle,
                rawText: result.summary,
                documentType: .unknown
            ),
            result: AnalysisResult(
                summary: result.summary,
                keyInsights: result.differences.map { $0.label },
                redFlags: result.criticalDifferences().map { $0.label },
                actionItems: [],
                documentType: .unknown
            )
        )
    }
}

// MARK: - Document Picker Sheet

struct DocumentPickerSheet: View {
    let documents: [Document]
    let title: String
    let onSelect: (Document) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if documents.isEmpty {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Scan some documents first to compare them.")
                    )
                } else {
                    ForEach(documents) { document in
                        Button {
                            onSelect(document)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: document.documentType.systemIcon)
                                    .font(.title2)
                                    .foregroundStyle(.tint)
                                    .frame(width: 44, height: 44)
                                    .background(.tint.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Text(document.documentType.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(document.dateScanned, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }

                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#endif
