import Foundation
import Testing
@testable import PrivlensCore

// MARK: - ReminderService Tests

@Suite("ReminderService Tests")
struct ReminderServiceTests {

    /// Returns a unique temp directory for test isolation.
    private static func tempStorageDir() -> String {
        let dir = NSTemporaryDirectory()
        return dir + "PrivlensReminderTest/\(UUID().uuidString)"
    }

    // MARK: - Storage Tests

    @Test("Save and load reminder round-trip")
    func saveAndLoadReminder() async throws {
        let dir = Self.tempStorageDir()
        let service = ReminderService(storageDirectory: dir)

        let reminder = DocumentReminder(
            date: Date().addingTimeInterval(86400),
            title: "Test Reminder",
            reminderDescription: "This is a test",
            documentId: UUID()
        )

        try await service.saveReminder(reminder)
        let loaded = try await service.loadReminders()

        #expect(loaded.count == 1)
        #expect(loaded[0].id == reminder.id)
        #expect(loaded[0].title == "Test Reminder")
        #expect(loaded[0].reminderDescription == "This is a test")
    }

    @Test("Delete reminder removes from storage")
    func deleteReminder() async throws {
        let dir = Self.tempStorageDir()
        let service = ReminderService(storageDirectory: dir)

        let reminder = DocumentReminder(
            date: Date().addingTimeInterval(86400),
            title: "To Delete",
            reminderDescription: "Will be deleted",
            documentId: UUID()
        )

        try await service.saveReminder(reminder)
        let beforeDelete = try await service.loadReminders()
        #expect(beforeDelete.count == 1)

        try await service.deleteReminder(reminder)
        let afterDelete = try await service.loadReminders()
        #expect(afterDelete.count == 0)
    }

    @Test("Load from empty directory returns empty array")
    func loadEmptyDirectory() async throws {
        let dir = Self.tempStorageDir()
        let service = ReminderService(storageDirectory: dir)

        let reminders = try await service.loadReminders()
        #expect(reminders.isEmpty)
    }

    @Test("Multiple reminders can be saved and loaded")
    func multipleReminders() async throws {
        let dir = Self.tempStorageDir()
        let service = ReminderService(storageDirectory: dir)

        let docId = UUID()
        for i in 0..<5 {
            let reminder = DocumentReminder(
                date: Date().addingTimeInterval(Double(i) * 86400),
                title: "Reminder \(i)",
                reminderDescription: "Description \(i)",
                documentId: docId
            )
            try await service.saveReminder(reminder)
        }

        let loaded = try await service.loadReminders()
        #expect(loaded.count == 5)
    }

    @Test("Schedule reminder returns updated reminder with notification ID")
    func scheduleReminder() async throws {
        let dir = Self.tempStorageDir()
        let service = ReminderService(storageDirectory: dir)

        let reminder = DocumentReminder(
            date: Date().addingTimeInterval(86400),
            title: "Scheduled",
            reminderDescription: "To be scheduled",
            documentId: UUID()
        )

        let scheduled = try await service.scheduleReminder(reminder)
        #expect(scheduled.notificationId != nil)

        let loaded = try await service.loadReminders()
        #expect(loaded.count == 1)
        #expect(loaded[0].notificationId != nil)
    }

    @Test("Delete non-existent reminder is no-op")
    func deleteNonExistent() async throws {
        let dir = Self.tempStorageDir()
        let service = ReminderService(storageDirectory: dir)

        let reminder = DocumentReminder(
            date: Date(),
            title: "Ghost",
            reminderDescription: "Does not exist",
            documentId: UUID()
        )

        // Should not throw
        try await service.deleteReminder(reminder)
    }

    @Test("Reminder conforms to protocol")
    func protocolConformance() {
        let dir = Self.tempStorageDir()
        let service = ReminderService(storageDirectory: dir)
        let _: any ReminderServiceProtocol = service
    }
}

// MARK: - DocumentReminder Model Tests

@Suite("DocumentReminder Model Tests")
struct DocumentReminderModelTests {

    @Test("DocumentReminder initializes with correct defaults")
    func defaults() {
        let reminder = DocumentReminder(
            date: Date(),
            title: "Test",
            reminderDescription: "Desc",
            documentId: UUID()
        )

        #expect(reminder.source == .manual)
        #expect(reminder.isCompleted == false)
        #expect(reminder.notificationId == nil)
    }

    @Test("DocumentReminder is Codable")
    func codable() throws {
        let reminder = DocumentReminder(
            date: Date(),
            title: "Codable Test",
            reminderDescription: "Test description",
            documentId: UUID(),
            source: .autoExtracted,
            isCompleted: true
        )

        let data = try JSONEncoder().encode(reminder)
        let decoded = try JSONDecoder().decode(DocumentReminder.self, from: data)

        #expect(decoded.id == reminder.id)
        #expect(decoded.title == "Codable Test")
        #expect(decoded.source == .autoExtracted)
        #expect(decoded.isCompleted == true)
    }

    @Test("DocumentReminder Hashable uses id")
    func hashable() {
        let id = UUID()
        let r1 = DocumentReminder(
            id: id,
            date: Date(),
            title: "A",
            reminderDescription: "Desc A",
            documentId: UUID()
        )
        let r2 = DocumentReminder(
            id: id,
            date: Date().addingTimeInterval(1000),
            title: "B",
            reminderDescription: "Desc B",
            documentId: UUID()
        )

        #expect(r1 == r2)
    }
}

// MARK: - DateExtractor Tests

@Suite("DateExtractor Tests")
struct DateExtractorTests {

    @Test("Extracts due date from analysis text")
    func extractDueDate() {
        let result = AnalysisResult(
            summary: "Payment due date: 12/15/2026",
            keyInsights: [],
            redFlags: [],
            actionItems: [],
            documentType: .medicalBill
        )

        let dates = DateExtractor.extractDates(
            from: result,
            documentId: UUID(),
            documentTitle: "Test Doc"
        )

        #expect(!dates.isEmpty)
        if let first = dates.first {
            #expect(first.label == "Payment Due Date")
            #expect(first.documentTitle == "Test Doc")
        }
    }

    @Test("Extracts expiration date")
    func extractExpirationDate() {
        let result = AnalysisResult(
            summary: "The policy expires: 06/30/2026",
            keyInsights: [],
            redFlags: [],
            actionItems: [],
            documentType: .insurance
        )

        let dates = DateExtractor.extractDates(
            from: result,
            documentId: UUID(),
            documentTitle: "Insurance Policy"
        )

        #expect(!dates.isEmpty)
        if let first = dates.first {
            #expect(first.label == "Expiration Date")
        }
    }

    @Test("Extracts renewal date")
    func extractRenewalDate() {
        let result = AnalysisResult(
            summary: "Lease renewal date: January 1, 2027",
            keyInsights: [],
            redFlags: [],
            actionItems: [],
            documentType: .lease
        )

        let dates = DateExtractor.extractDates(
            from: result,
            documentId: UUID(),
            documentTitle: "Lease"
        )

        #expect(!dates.isEmpty)
        if let first = dates.first {
            #expect(first.label == "Renewal Date")
        }
    }

    @Test("Returns empty for text without dates")
    func noDates() {
        let result = AnalysisResult(
            summary: "This document has no date references at all.",
            keyInsights: ["Simple insight"],
            redFlags: [],
            actionItems: [],
            documentType: .unknown
        )

        let dates = DateExtractor.extractDates(
            from: result,
            documentId: UUID(),
            documentTitle: "No Dates"
        )

        #expect(dates.isEmpty)
    }

    @Test("Extracts dates from multiple text sections")
    func multipleSections() {
        let result = AnalysisResult(
            summary: "The deadline: 03/01/2027",
            keyInsights: ["Payment due: 04/15/2027"],
            redFlags: ["Contract expiration: 12/31/2026"],
            actionItems: [],
            documentType: .employmentContract
        )

        let dates = DateExtractor.extractDates(
            from: result,
            documentId: UUID(),
            documentTitle: "Contract"
        )

        #expect(dates.count >= 2)
    }

    @Test("Deduplicates identical date-label pairs")
    func deduplication() {
        let result = AnalysisResult(
            summary: "Payment due date: 12/15/2026",
            keyInsights: ["Payment due date: 12/15/2026"],
            redFlags: [],
            actionItems: [],
            documentType: .medicalBill
        )

        let dates = DateExtractor.extractDates(
            from: result,
            documentId: UUID(),
            documentTitle: "Test"
        )

        // Should deduplicate same date+label
        let dueDateCount = dates.filter { $0.label == "Payment Due Date" }.count
        #expect(dueDateCount == 1)
    }
}

// MARK: - ExtractedDate Model Tests

@Suite("ExtractedDate Model Tests")
struct ExtractedDateModelTests {

    @Test("ExtractedDate is Codable")
    func codable() throws {
        let date = ExtractedDate(
            date: Date(),
            label: "Due Date",
            context: "Payment due: 12/15/2026",
            documentId: UUID(),
            documentTitle: "Bill"
        )

        let data = try JSONEncoder().encode(date)
        let decoded = try JSONDecoder().decode(ExtractedDate.self, from: data)

        #expect(decoded.label == "Due Date")
        #expect(decoded.documentTitle == "Bill")
    }
}
