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
            // Similarity Score
            similarityIndicator(result.similarityScore)

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

            // Differences
            if !result.differences.isEmpty {
                differencesSection(result.differences)
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
        let color: Color = score > 0.7 ? .green : score > 0.4 ? .orange : .red

        return VStack(spacing: 8) {
            Text("\(percent)%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(color)
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

    private func differencesSection(_ differences: [ComparisonDifference]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Differences")
                .font(.headline)
                .accessibilityLabel(AccessibilityLabels.differenceCount(differences.count))

            let critical = differences.filter { $0.severity >= 0.7 }
            let other = differences.filter { $0.severity < 0.7 }

            if !critical.isEmpty {
                Text("Critical")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)

                ForEach(critical) { diff in
                    differenceCard(diff, isCritical: true)
                }
            }

            if !other.isEmpty {
                Text("Other")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                ForEach(other) { diff in
                    differenceCard(diff, isCritical: false)
                }
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.comparisonDifferences)
    }

    private func differenceCard(_ diff: ComparisonDifference, isCritical: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: diff.category.systemIcon)
                    .foregroundStyle(isCritical ? .red : .secondary)
                Text(diff.label)
                    .font(.subheadline.bold())
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Doc A")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(diff.documentAValue)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Doc B")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Text(diff.documentBValue)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(isCritical ? Color.red.opacity(0.08) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
