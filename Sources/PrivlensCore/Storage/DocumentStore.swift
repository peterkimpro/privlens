import Foundation

#if canImport(SwiftData)
import SwiftData

/// Persistence layer for scanned documents using SwiftData.
public final class DocumentStore: Sendable {

    public let modelContainer: ModelContainer

    public init() throws {
        let schema = Schema([Document.self, Folder.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    /// Creates a store with a custom container (useful for testing with in-memory stores).
    public init(container: ModelContainer) {
        self.modelContainer = container
    }

    /// Saves a document to the persistent store.
    @MainActor
    public func save(_ document: Document) throws {
        let context = modelContainer.mainContext
        context.insert(document)
        try context.save()
    }

    /// Fetches all documents, sorted by scan date (newest first).
    @MainActor
    public func fetchAll() throws -> [Document] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Document>(
            sortBy: [SortDescriptor(\.dateScanned, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Fetches documents matching a search query against title and raw text.
    @MainActor
    public func search(query: String) throws -> [Document] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate<Document> { document in
                document.title.localizedStandardContains(query) ||
                document.rawText.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.dateScanned, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Fetches documents filtered by document type.
    @MainActor
    public func fetch(byType type: DocumentType) throws -> [Document] {
        let typeRaw = type.rawValue
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate<Document> { document in
                document.documentTypeRaw == typeRaw
            },
            sortBy: [SortDescriptor(\.dateScanned, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Deletes a document from the persistent store.
    @MainActor
    public func delete(_ document: Document) throws {
        let context = modelContainer.mainContext
        context.delete(document)
        try context.save()
    }

    /// Updates and saves changes to an existing document.
    @MainActor
    public func update(_ document: Document) throws {
        let context = modelContainer.mainContext
        try context.save()
    }

    /// Returns the total count of stored documents.
    @MainActor
    public func count() throws -> Int {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Document>()
        return try context.fetchCount(descriptor)
    }

    // MARK: - Folder Operations

    @MainActor
    public func createFolder(_ folder: Folder) throws {
        let context = modelContainer.mainContext
        context.insert(folder)
        try context.save()
    }

    @MainActor
    public func fetchAllFolders() throws -> [Folder] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Folder>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    @MainActor
    public func deleteFolder(_ folder: Folder) throws {
        let context = modelContainer.mainContext
        context.delete(folder)
        try context.save()
    }

    @MainActor
    public func updateFolder(_ folder: Folder) throws {
        let context = modelContainer.mainContext
        try context.save()
    }

    @MainActor
    public func moveDocument(_ document: Document, to folder: Folder?) throws {
        document.folder = folder
        let context = modelContainer.mainContext
        try context.save()
    }

    @MainActor
    public func fetchDocuments(in folder: Folder) throws -> [Document] {
        let context = modelContainer.mainContext
        let folderID = folder.id
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.folder?.id == folderID },
            sortBy: [SortDescriptor(\.dateScanned, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    @MainActor
    public func fetchUnfiledDocuments() throws -> [Document] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.folder == nil },
            sortBy: [SortDescriptor(\.dateScanned, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Full-Text Search

    @MainActor
    public func fullTextSearch(query: String) throws -> [Document] {
        let context = modelContainer.mainContext
        let lowered = query.lowercased()
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate {
                $0.title.localizedStandardContains(lowered) ||
                $0.rawText.localizedStandardContains(lowered) ||
                $0.analysisResult?.localizedStandardContains(lowered) == true
            },
            sortBy: [SortDescriptor(\.dateScanned, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}

#else

// Stub for non-Apple platforms -- stores documents in memory only.
public final class DocumentStore: @unchecked Sendable {

    private var documents: [Document] = []
    private var folders: [Folder] = []
    private let lock = NSLock()

    public init() throws {}

    public func save(_ document: Document) throws {
        lock.lock()
        defer { lock.unlock() }
        documents.append(document)
    }

    public func fetchAll() throws -> [Document] {
        lock.lock()
        defer { lock.unlock() }
        return documents.sorted { $0.dateScanned > $1.dateScanned }
    }

    public func search(query: String) throws -> [Document] {
        lock.lock()
        defer { lock.unlock() }
        let lowered = query.lowercased()
        return documents.filter {
            $0.title.lowercased().contains(lowered) ||
            $0.rawText.lowercased().contains(lowered)
        }
    }

    public func fetch(byType type: DocumentType) throws -> [Document] {
        lock.lock()
        defer { lock.unlock() }
        return documents.filter { $0.documentType == type }
    }

    public func delete(_ document: Document) throws {
        lock.lock()
        defer { lock.unlock() }
        documents.removeAll { $0.id == document.id }
    }

    public func update(_ document: Document) throws {
        // In-memory store: the object reference is already updated.
    }

    public func count() throws -> Int {
        lock.lock()
        defer { lock.unlock() }
        return documents.count
    }

    // MARK: - Folder Operations

    public func createFolder(_ folder: Folder) throws {
        lock.lock()
        defer { lock.unlock() }
        folders.append(folder)
    }

    public func fetchAllFolders() throws -> [Folder] {
        lock.lock()
        defer { lock.unlock() }
        return folders.sorted {
            if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
            return $0.name < $1.name
        }
    }

    public func deleteFolder(_ folder: Folder) throws {
        lock.lock()
        defer { lock.unlock() }
        folders.removeAll { $0.id == folder.id }
    }

    public func updateFolder(_ folder: Folder) throws {
        // In-memory store: the object reference is already updated.
    }

    public func moveDocument(_ document: Document, to folder: Folder?) throws {
        // In-memory stub: folder association is stored as a string on the Linux Document.
    }

    public func fetchDocuments(in folder: Folder) throws -> [Document] {
        lock.lock()
        defer { lock.unlock() }
        return documents
            .filter { $0.folder == folder.name }
            .sorted { $0.dateScanned > $1.dateScanned }
    }

    public func fetchUnfiledDocuments() throws -> [Document] {
        lock.lock()
        defer { lock.unlock() }
        return documents
            .filter { $0.folder == nil }
            .sorted { $0.dateScanned > $1.dateScanned }
    }

    // MARK: - Full-Text Search

    public func fullTextSearch(query: String) throws -> [Document] {
        lock.lock()
        defer { lock.unlock() }
        let lowered = query.lowercased()
        return documents.filter {
            $0.title.lowercased().contains(lowered) ||
            $0.rawText.lowercased().contains(lowered) ||
            ($0.analysisResult?.lowercased().contains(lowered) ?? false)
        }.sorted { $0.dateScanned > $1.dateScanned }
    }
}
#endif
