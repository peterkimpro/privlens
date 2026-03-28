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
    public var folders: [Folder] = []
    public var selectedFolder: Folder? = nil  // nil = show all
    public var showUnfiledOnly = false
    public var searchQuery = ""
    public var sortOrder: SortOrder = .newestFirst
    public var isLoading = false

    public var filteredDocuments: [Document] {
        var result = documents

        // Filter by selected folder
        if let selectedFolder {
            result = result.filter { $0.folder?.id == selectedFolder.id }
        } else if showUnfiledOnly {
            result = result.filter { $0.folder == nil }
        }

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
            folders = try store.fetchAllFolders()
        } catch {
            documents = []
            folders = []
        }
    }

    public func loadFolders() async {
        do {
            let store = try DocumentStore()
            folders = try store.fetchAllFolders()
        } catch {
            folders = []
        }
    }

    public func createFolder(name: String, icon: String, color: String) async {
        do {
            let store = try DocumentStore()
            let folder = Folder(name: name, iconName: icon, colorHex: color, sortOrder: folders.count)
            try store.createFolder(folder)
            await loadFolders()
        } catch {
            // Silently fail
        }
    }

    public func deleteFolder(_ folder: Folder) async {
        do {
            let store = try DocumentStore()
            try store.deleteFolder(folder)
            if selectedFolder?.id == folder.id {
                selectedFolder = nil
                showUnfiledOnly = false
            }
            await loadDocuments()
        } catch {
            // Silently fail
        }
    }

    public func moveDocument(_ document: Document, to folder: Folder?) async {
        do {
            let store = try DocumentStore()
            try store.moveDocument(document, to: folder)
            await loadDocuments()
        } catch {
            // Silently fail
        }
    }

    public func selectFolder(_ folder: Folder?) {
        if let folder {
            selectedFolder = folder
            showUnfiledOnly = false
        } else {
            selectedFolder = nil
            showUnfiledOnly = false
        }
    }

    public func selectUnfiled() {
        selectedFolder = nil
        showUnfiledOnly = true
    }

    public func selectAll() {
        selectedFolder = nil
        showUnfiledOnly = false
    }

    public func searchDocuments(query: String) async {
        guard !query.isEmpty else {
            await loadDocuments()
            return
        }
        do {
            let store = try DocumentStore()
            documents = try store.fullTextSearch(query: query)
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

    public func updateFolder(_ folder: Folder, name: String, icon: String, color: String) async {
        do {
            let store = try DocumentStore()
            folder.name = name
            folder.iconName = icon
            folder.colorHex = color
            try store.updateFolder(folder)
            await loadFolders()
        } catch {
            // Silently fail
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
    public var folders: [Folder] = []
    public var selectedFolder: Folder? = nil
    public var showUnfiledOnly = false
    public var searchQuery = ""
    public var sortOrder: SortOrder = .newestFirst
    public var isLoading = false
    public var filteredDocuments: [Document] { documents }

    public init() {}

    public func loadDocuments() async {}
    public func loadFolders() async {}
    public func createFolder(name: String, icon: String, color: String) async {}
    public func deleteFolder(_ folder: Folder) async {}
    public func moveDocument(_ document: Document, to folder: Folder?) async {}
    public func selectFolder(_ folder: Folder?) {}
    public func selectUnfiled() {}
    public func selectAll() {}
    public func searchDocuments(query: String) async {}
    public func deleteDocuments(at offsets: IndexSet) async {}
    public func updateFolder(_ folder: Folder, name: String, icon: String, color: String) async {}
}
#endif
