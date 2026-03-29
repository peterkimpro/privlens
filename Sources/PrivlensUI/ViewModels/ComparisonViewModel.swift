#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

@Observable
@MainActor
public final class ComparisonViewModel {

    public var documents: [Document] = []
    public var selectedDocumentA: Document?
    public var selectedDocumentB: Document?
    public var comparisonResult: PrivlensCore.ComparisonResult?
    public var isComparing = false
    public var isLoading = false
    public var errorMessage: String?

    private let comparisonService = DocumentComparisonService()
    private let errorRecovery = ErrorRecoveryService()

    public init() {}

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

    public var canCompare: Bool {
        selectedDocumentA != nil && selectedDocumentB != nil &&
        selectedDocumentA?.id != selectedDocumentB?.id
    }

    public func runComparison() async {
        guard let selectedA = selectedDocumentA, let selectedB = selectedDocumentB else {
            errorMessage = "Please select two documents to compare."
            return
        }

        isComparing = true
        errorMessage = nil
        defer { isComparing = false }

        nonisolated(unsafe) let docA = selectedA
        nonisolated(unsafe) let docB = selectedB

        do {
            comparisonResult = try await comparisonService.compare(documentA: docA, documentB: docB)
        } catch {
            let info = errorRecovery.recoveryInfo(for: error)
            errorMessage = info.message
        }
    }

    public func reset() {
        selectedDocumentA = nil
        selectedDocumentB = nil
        comparisonResult = nil
        errorMessage = nil
    }

    /// Available documents for selecting as Document B (excludes the selected Document A).
    public var availableDocumentsForB: [Document] {
        guard let docA = selectedDocumentA else { return documents }
        return documents.filter { $0.id != docA.id }
    }
}

#else

import Foundation
import PrivlensCore

@MainActor
public final class ComparisonViewModel {
    public var documents: [Document] = []
    public var selectedDocumentA: Document?
    public var selectedDocumentB: Document?
    public var isComparing = false
    public var isLoading = false
    public var errorMessage: String?
    public var canCompare: Bool { false }
    public var availableDocumentsForB: [Document] { [] }

    public init() {}

    public func loadDocuments() async {}
    public func runComparison() async {}
    public func reset() {}
}
#endif
