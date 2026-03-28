import Foundation

#if canImport(SwiftData)
import SwiftData

/// Persistence layer for scanned documents using SwiftData.
public final class DocumentStore: Sendable {

    public let modelContainer: ModelContainer

    public init() throws {
        let schema = Schema([Document.self])
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
}

#else

// Stub for non-Apple platforms -- stores documents in memory only.
public final class DocumentStore: @unchecked Sendable {

    private var documents: [Document] = []
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
}
#endif
