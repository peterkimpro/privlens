#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

@Observable
@MainActor
public final class LibraryViewModel {

    public enum SortOrder: String, CaseIterable, Sendable {
        case newestFirst = "Newest First"
        case oldestFirst = "Oldest First"
        case byType = "By Type"
    }

    public var documents: [Document] = []
    public var searchQuery = ""
    public var sortOrder: SortOrder = .newestFirst
    public var isLoading = false

    public var filteredDocuments: [Document] {
        var result = documents

        // Filter by search
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.rawText.lowercased().contains(query)
            }
        }

        // Sort
        switch sortOrder {
        case .newestFirst:
            result.sort { $0.dateScanned > $1.dateScanned }
        case .oldestFirst:
            result.sort { $0.dateScanned < $1.dateScanned }
        case .byType:
            result.sort { $0.documentTypeRaw < $1.documentTypeRaw }
        }

        return result
    }

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

    public func deleteDocuments(at offsets: IndexSet) async {
        let docsToDelete = offsets.map { filteredDocuments[$0] }
        do {
            let store = try DocumentStore()
            for doc in docsToDelete {
                try store.delete(doc)
            }
            await loadDocuments()
        } catch {
            // Silently fail — document remains in list
        }
    }
}

#else

import Foundation
import PrivlensCore

@MainActor
public final class LibraryViewModel {
    public enum SortOrder: String, CaseIterable, Sendable {
        case newestFirst, oldestFirst, byType
    }

    public var documents: [Document] = []
    public var searchQuery = ""
    public var sortOrder: SortOrder = .newestFirst
    public var isLoading = false
    public var filteredDocuments: [Document] { documents }

    public init() {}

    public func loadDocuments() async {}
    public func deleteDocuments(at offsets: IndexSet) async {}
}
#endif
