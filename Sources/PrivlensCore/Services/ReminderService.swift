import Foundation

// MARK: - ReminderError

public enum ReminderError: Error, LocalizedError, Sendable {
    case notificationPermissionDenied
    case reminderNotFound
    case storageFailed(String)
    case schedulingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notificationPermissionDenied:
            return "Notification permission was denied. Please enable notifications in Settings."
        case .reminderNotFound:
            return "The requested reminder was not found."
        case .storageFailed(let reason):
            return "Failed to save reminder: \(reason)"
        case .schedulingFailed(let reason):
            return "Failed to schedule notification: \(reason)"
        }
    }
}

// MARK: - ReminderServiceProtocol

/// Protocol for managing document reminders.
public protocol ReminderServiceProtocol: Sendable {
    /// Request notification permission.
    func requestNotificationPermission() async throws -> Bool

    /// Schedule a reminder and return it with a notification ID.
    func scheduleReminder(_ reminder: DocumentReminder) async throws -> DocumentReminder

    /// Cancel a previously scheduled reminder notification.
    func cancelReminder(_ reminder: DocumentReminder) async throws

    /// Load all saved reminders.
    func loadReminders() async throws -> [DocumentReminder]

    /// Save a reminder to persistent storage.
    func saveReminder(_ reminder: DocumentReminder) async throws

    /// Delete a reminder from storage and cancel its notification.
    func deleteReminder(_ reminder: DocumentReminder) async throws

    /// Update an existing reminder.
    func updateReminder(_ reminder: DocumentReminder) async throws -> DocumentReminder

    /// Extract key dates from an analysis result for a given document.
    func extractDates(from result: AnalysisResult, documentId: UUID, documentTitle: String) -> [ExtractedDate]
}

// MARK: - ReminderService (Platform-Specific)

#if canImport(UserNotifications)
import UserNotifications

public final class ReminderService: ReminderServiceProtocol, @unchecked Sendable {

    private let storageDirectory: String
    private let lock = NSLock()

    public init() {
        #if canImport(UIKit)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first ?? NSTemporaryDirectory()
        self.storageDirectory = documentsPath + "/PrivlensReminders"
        #elseif canImport(AppKit)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first ?? NSTemporaryDirectory()
        self.storageDirectory = documentsPath + "/PrivlensReminders"
        #else
        self.storageDirectory = "/tmp/PrivlensReminders"
        #endif
    }

    /// Initialize with a custom storage directory (useful for testing).
    public init(storageDirectory: String) {
        self.storageDirectory = storageDirectory
    }

    public func requestNotificationPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        return granted
    }

    public func scheduleReminder(_ reminder: DocumentReminder) async throws -> DocumentReminder {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.reminderDescription
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let notificationId = reminder.notificationId ?? UUID().uuidString
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )

        try await center.add(request)

        var updatedReminder = reminder
        updatedReminder.notificationId = notificationId
        try await saveReminder(updatedReminder)
        return updatedReminder
    }

    public func cancelReminder(_ reminder: DocumentReminder) async throws {
        if let notificationId = reminder.notificationId {
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
    }

    public func loadReminders() async throws -> [DocumentReminder] {
        return loadRemindersSync()
    }

    public func saveReminder(_ reminder: DocumentReminder) async throws {
        try saveReminderSync(reminder)
    }

    public func deleteReminder(_ reminder: DocumentReminder) async throws {
        try await cancelReminder(reminder)
        try deleteReminderSync(reminder.id)
    }

    public func updateReminder(_ reminder: DocumentReminder) async throws -> DocumentReminder {
        // Cancel old notification if present
        try await cancelReminder(reminder)
        // Schedule new notification
        return try await scheduleReminder(reminder)
    }

    public func extractDates(from result: AnalysisResult, documentId: UUID, documentTitle: String) -> [ExtractedDate] {
        return DateExtractor.extractDates(from: result, documentId: documentId, documentTitle: documentTitle)
    }

    // MARK: - Synchronous Lock-Protected Helpers

    private func loadRemindersSync() -> [DocumentReminder] {
        lock.lock()
        defer { lock.unlock() }

        guard FileManager.default.fileExists(atPath: storageDirectory) else {
            return []
        }

        let url = URL(fileURLWithPath: storageDirectory)
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
            return []
        }

        let decoder = JSONDecoder()
        return contents.compactMap { filename -> DocumentReminder? in
            guard filename.hasSuffix(".json") else { return nil }
            let filePath = storageDirectory + "/\(filename)"
            let fileUrl = URL(fileURLWithPath: filePath)
            guard let data = try? Data(contentsOf: fileUrl),
                  let reminder = try? decoder.decode(DocumentReminder.self, from: data) else {
                return nil
            }
            return reminder
        }
    }

    private func saveReminderSync(_ reminder: DocumentReminder) throws {
        lock.lock()
        defer { lock.unlock() }

        try ensureDirectoryExists()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(reminder) else {
            throw ReminderError.storageFailed("Encoding failed")
        }

        let path = filePath(for: reminder.id)
        let url = URL(fileURLWithPath: path)

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ReminderError.storageFailed(path)
        }
    }

    private func deleteReminderSync(_ id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }

        let path = filePath(for: id)
        guard FileManager.default.fileExists(atPath: path) else { return }

        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            throw ReminderError.storageFailed("Delete failed at \(path)")
        }
    }

    private func filePath(for reminderId: UUID) -> String {
        return storageDirectory + "/\(reminderId.uuidString).json"
    }

    private func ensureDirectoryExists() throws {
        if !FileManager.default.fileExists(atPath: storageDirectory) {
            try FileManager.default.createDirectory(
                atPath: storageDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}

#else

// MARK: - Linux Stub

public final class ReminderService: ReminderServiceProtocol, @unchecked Sendable {

    private let storageDirectory: String
    private let lock = NSLock()

    public init() {
        self.storageDirectory = "/tmp/PrivlensReminders"
    }

    public init(storageDirectory: String) {
        self.storageDirectory = storageDirectory
    }

    public func requestNotificationPermission() async throws -> Bool {
        return false
    }

    public func scheduleReminder(_ reminder: DocumentReminder) async throws -> DocumentReminder {
        var updatedReminder = reminder
        updatedReminder.notificationId = UUID().uuidString
        try await saveReminder(updatedReminder)
        return updatedReminder
    }

    public func cancelReminder(_ reminder: DocumentReminder) async throws {
        // No-op on Linux
    }

    public func loadReminders() async throws -> [DocumentReminder] {
        return loadRemindersSync()
    }

    public func saveReminder(_ reminder: DocumentReminder) async throws {
        try saveReminderSync(reminder)
    }

    public func deleteReminder(_ reminder: DocumentReminder) async throws {
        try deleteReminderSync(reminder.id)
    }

    public func updateReminder(_ reminder: DocumentReminder) async throws -> DocumentReminder {
        return try await scheduleReminder(reminder)
    }

    public func extractDates(from result: AnalysisResult, documentId: UUID, documentTitle: String) -> [ExtractedDate] {
        return DateExtractor.extractDates(from: result, documentId: documentId, documentTitle: documentTitle)
    }

    // MARK: - Synchronous Lock-Protected Helpers

    private func loadRemindersSync() -> [DocumentReminder] {
        lock.lock()
        defer { lock.unlock() }

        guard FileManager.default.fileExists(atPath: storageDirectory) else {
            return []
        }

        let url = URL(fileURLWithPath: storageDirectory)
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
            return []
        }

        let decoder = JSONDecoder()
        return contents.compactMap { filename -> DocumentReminder? in
            guard filename.hasSuffix(".json") else { return nil }
            let filePath = storageDirectory + "/\(filename)"
            let fileUrl = URL(fileURLWithPath: filePath)
            guard let data = try? Data(contentsOf: fileUrl),
                  let reminder = try? decoder.decode(DocumentReminder.self, from: data) else {
                return nil
            }
            return reminder
        }
    }

    private func saveReminderSync(_ reminder: DocumentReminder) throws {
        lock.lock()
        defer { lock.unlock() }

        try ensureDirectoryExists()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(reminder) else {
            throw ReminderError.storageFailed("Encoding failed")
        }

        let path = filePath(for: reminder.id)
        let url = URL(fileURLWithPath: path)

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ReminderError.storageFailed(path)
        }
    }

    private func deleteReminderSync(_ id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }

        let path = filePath(for: id)
        guard FileManager.default.fileExists(atPath: path) else { return }

        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            throw ReminderError.storageFailed("Delete failed at \(path)")
        }
    }

    private func filePath(for reminderId: UUID) -> String {
        return storageDirectory + "/\(reminderId.uuidString).json"
    }

    private func ensureDirectoryExists() throws {
        if !FileManager.default.fileExists(atPath: storageDirectory) {
            try FileManager.default.createDirectory(
                atPath: storageDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}

#endif
