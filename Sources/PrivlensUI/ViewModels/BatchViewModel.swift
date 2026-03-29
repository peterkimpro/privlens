#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

@Observable
@MainActor
public final class BatchViewModel {

    public var batchJob: BatchJob?
    public var documents: [Document] = []
    public var selectedDocumentIds: Set<UUID> = []
    public var isAnalyzing = false
    public var isLoading = false
    public var errorMessage: String?
    public var currentProgress: Double = 0.0
    public var currentDocumentTitle: String = ""
    public var showResults = false

    private var analysisService: BatchAnalysisServiceProtocol?

    public init() {}

    public func configure(
        analysisService: BatchAnalysisServiceProtocol
    ) {
        self.analysisService = analysisService
    }

    public func loadDocuments() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let store = try DocumentStore()
            documents = try store.fetchAll()
        } catch {
            documents = []
        }
    }

    public func toggleDocumentSelection(_ documentId: UUID) {
        if selectedDocumentIds.contains(documentId) {
            selectedDocumentIds.remove(documentId)
        } else {
            selectedDocumentIds.insert(documentId)
        }
    }

    public var canStartBatch: Bool {
        !selectedDocumentIds.isEmpty && !isAnalyzing
    }

    public func startBatchAnalysis() async {
        guard let analysisService = analysisService else {
            errorMessage = "Analysis service not configured."
            return
        }

        guard !selectedDocumentIds.isEmpty else {
            errorMessage = "Please select at least one document."
            return
        }

        isAnalyzing = true
        errorMessage = nil
        currentProgress = 0.0
        defer { isAnalyzing = false }

        let selectedDocs = documents.filter { selectedDocumentIds.contains($0.id) }
        let entries = selectedDocs.map { doc in
            BatchDocumentEntry(documentId: doc.id, title: doc.title)
        }

        var job = BatchJob(
            title: "Batch Analysis - \(entries.count) documents",
            entries: entries
        )

        do {
            job = try await analysisService.analyzeBatch(
                job,
                documents: selectedDocs
            ) { _ in
                // Progress is tracked via batchJob state updates
            }

            batchJob = job
            showResults = true
        } catch {
            errorMessage = error.localizedDescription
            batchJob = job
        }
    }

    public func reset() {
        batchJob = nil
        selectedDocumentIds.removeAll()
        errorMessage = nil
        currentProgress = 0.0
        currentDocumentTitle = ""
        showResults = false
    }
}

#else

import Foundation
import PrivlensCore

@MainActor
public final class BatchViewModel {
    public var batchJob: BatchJob?
    public var documents: [Document] = []
    public var selectedDocumentIds: Set<UUID> = []
    public var isAnalyzing = false
    public var isLoading = false
    public var errorMessage: String?
    public var currentProgress: Double = 0.0
    public var currentDocumentTitle: String = ""
    public var showResults = false
    public var canStartBatch: Bool { false }

    public init() {}

    public func loadDocuments() async {}
    public func toggleDocumentSelection(_ documentId: UUID) {}
    public func startBatchAnalysis() async {}
    public func reset() {}
}

#endif
