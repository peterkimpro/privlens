import Foundation

// MARK: - ReminderSource

/// Indicates how a reminder was created.
public enum ReminderSource: String, Codable, Sendable {
    /// Manually created by the user.
    case manual
    /// Auto-extracted from document analysis.
    case autoExtracted
}

// MARK: - ExtractedDate

/// A date extracted from a document analysis with contextual information.
public struct ExtractedDate: Codable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let label: String
    public let context: String
    public let documentId: UUID
    public let documentTitle: String

    public init(
        id: UUID = UUID(),
        date: Date,
        label: String,
        context: String,
        documentId: UUID,
        documentTitle: String
    ) {
        self.id = id
        self.date = date
        self.label = label
        self.context = context
        self.documentId = documentId
        self.documentTitle = documentTitle
    }
}

// MARK: - DocumentReminder

/// A reminder linked to a document, with date, title, and optional notification.
public struct DocumentReminder: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public var date: Date
    public var title: String
    public var reminderDescription: String
    public var documentId: UUID
    public var notificationId: String?
    public var source: ReminderSource
    public var isCompleted: Bool

    public init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        reminderDescription: String,
        documentId: UUID,
        notificationId: String? = nil,
        source: ReminderSource = .manual,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.reminderDescription = reminderDescription
        self.documentId = documentId
        self.notificationId = notificationId
        self.source = source
        self.isCompleted = isCompleted
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: DocumentReminder, rhs: DocumentReminder) -> Bool {
        lhs.id == rhs.id
    }
}
