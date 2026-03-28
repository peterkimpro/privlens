import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

// MARK: - Folder (SwiftData Model)

#if canImport(SwiftData)
@Model
public final class Folder {
    public var id: UUID
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var dateCreated: Date
    public var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Document.folder)
    public var documents: [Document]

    public init(
        name: String,
        iconName: String = "folder.fill",
        colorHex: String = "007AFF",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.dateCreated = Date()
        self.sortOrder = sortOrder
        self.documents = []
    }

    public var documentCount: Int { documents.count }
}
#else
public final class Folder: Codable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let iconName: String
    public let colorHex: String
    public let dateCreated: Date
    public let sortOrder: Int
    public let documents: [Document]

    public init(
        name: String,
        iconName: String = "folder.fill",
        colorHex: String = "007AFF",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.dateCreated = Date()
        self.sortOrder = sortOrder
        self.documents = []
    }

    public var documentCount: Int { documents.count }
}
#endif
