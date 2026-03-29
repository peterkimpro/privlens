#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct BatchAnalysisView: View {
    @State private var viewModel = BatchViewModel()

    private let analysisService: BatchAnalysisServiceProtocol

    public init(analysisService: BatchAnalysisServiceProtocol) {
        self.analysisService = analysisService
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading documents...")
                } else if viewModel.documents.isEmpty {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Scan some documents first to run batch analysis.")
                    )
                } else {
                    documentListView
                }
            }
            .navigationTitle("Batch Analysis")
            .task {
                viewModel.configure(analysisService: analysisService)
                await viewModel.loadDocuments()
            }
            .sheet(isPresented: $viewModel.showResults) {
                if let job = viewModel.batchJob {
                    BatchResultsView(batchJob: job)
                }
            }
        }
    }

    // MARK: - Document List

    private var documentListView: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(viewModel.documents) { document in
                        documentRow(document)
                    }
                } header: {
                    Text("Select documents to analyze")
                } footer: {
                    Text("\(viewModel.selectedDocumentIds.count) of \(viewModel.documents.count) selected")
                }
            }

            // Bottom bar
            bottomBar
        }
    }

    private func documentRow(_ document: Document) -> some View {
        Button {
            viewModel.toggleDocumentSelection(document.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: viewModel.selectedDocumentIds.contains(document.id)
                    ? "checkmark.circle.fill"
                    : "circle"
                )
                .font(.title2)
                .foregroundStyle(viewModel.selectedDocumentIds.contains(document.id) ? .tint : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(document.documentType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let entry = viewModel.batchJob?.entries.first(where: { $0.documentId == document.id }) {
                    statusBadge(entry.status)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func statusBadge(_ status: BatchDocumentStatus) -> some View {
        Group {
            switch status {
            case .pending:
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
            case .analyzing:
                ProgressView()
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case .skippedPaywall:
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if viewModel.isAnalyzing {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.currentProgress)
                        .progressViewStyle(.linear)

                    Text("Analyzing: \(viewModel.currentDocumentTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Button {
                Task { await viewModel.startBatchAnalysis() }
            } label: {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label(
                        "Analyze \(viewModel.selectedDocumentIds.count) Document\(viewModel.selectedDocumentIds.count == 1 ? "" : "s")",
                        systemImage: "sparkles"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canStartBatch)
        }
        .padding()
        .background(.regularMaterial)
    }
}

#endif
