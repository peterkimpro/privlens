#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

@Observable
@MainActor
public final class ReminderViewModel {

    public var reminders: [DocumentReminder] = []
    public var isLoading = false
    public var errorMessage: String?
    public var suggestedDates: [ExtractedDate] = []
    public var showSuggestions = false

    private var reminderService: ReminderServiceProtocol?

    public init() {}

    public func configure(reminderService: ReminderServiceProtocol) {
        self.reminderService = reminderService
    }

    public func loadReminders() async {
        guard let reminderService = reminderService else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            reminders = try await reminderService.loadReminders()
            reminders.sort { $0.date < $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func createReminder(
        date: Date,
        title: String,
        description: String,
        documentId: UUID,
        source: ReminderSource = .manual
    ) async {
        guard let reminderService = reminderService else { return }

        let reminder = DocumentReminder(
            date: date,
            title: title,
            reminderDescription: description,
            documentId: documentId,
            source: source
        )

        do {
            let scheduled = try await reminderService.scheduleReminder(reminder)
            reminders.append(scheduled)
            reminders.sort { $0.date < $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteReminder(_ reminder: DocumentReminder) async {
        guard let reminderService = reminderService else { return }

        do {
            try await reminderService.deleteReminder(reminder)
            reminders.removeAll { $0.id == reminder.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updateReminder(_ reminder: DocumentReminder) async {
        guard let reminderService = reminderService else { return }

        do {
            let updated = try await reminderService.updateReminder(reminder)
            if let index = reminders.firstIndex(where: { $0.id == updated.id }) {
                reminders[index] = updated
            }
            reminders.sort { $0.date < $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func toggleCompleted(_ reminder: DocumentReminder) async {
        var updated = reminder
        updated.isCompleted.toggle()
        await updateReminder(updated)
    }

    /// After analysis completes, suggest reminders for extracted dates.
    public func suggestReminders(from result: AnalysisResult, documentId: UUID, documentTitle: String) {
        guard let reminderService = reminderService else { return }

        let dates = reminderService.extractDates(from: result, documentId: documentId, documentTitle: documentTitle)
        suggestedDates = dates.filter { $0.date > Date() }
        if !suggestedDates.isEmpty {
            showSuggestions = true
        }
    }

    /// Accept a suggested date and create a reminder from it.
    public func acceptSuggestion(_ extractedDate: ExtractedDate) async {
        await createReminder(
            date: extractedDate.date,
            title: extractedDate.label,
            description: extractedDate.context,
            documentId: extractedDate.documentId,
            source: .autoExtracted
        )
        suggestedDates.removeAll { $0.id == extractedDate.id }
        if suggestedDates.isEmpty {
            showSuggestions = false
        }
    }

    public func dismissSuggestions() {
        suggestedDates.removeAll()
        showSuggestions = false
    }

    public func requestPermission() async {
        guard let reminderService = reminderService else { return }

        do {
            _ = try await reminderService.requestNotificationPermission()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Group reminders by date for display.
    public var groupedReminders: [(date: Date, reminders: [DocumentReminder])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: reminders.filter { !$0.isCompleted }) { reminder in
            calendar.startOfDay(for: reminder.date)
        }
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, reminders: $0.value) }
    }

    /// Completed reminders.
    public var completedReminders: [DocumentReminder] {
        reminders.filter { $0.isCompleted }
    }
}

#else

import Foundation
import PrivlensCore

@MainActor
public final class ReminderViewModel {
    public var reminders: [DocumentReminder] = []
    public var isLoading = false
    public var errorMessage: String?
    public var suggestedDates: [ExtractedDate] = []
    public var showSuggestions = false
    public var groupedReminders: [(date: Date, reminders: [DocumentReminder])] { [] }
    public var completedReminders: [DocumentReminder] { [] }

    public init() {}

    public func loadReminders() async {}
    public func createReminder(date: Date, title: String, description: String, documentId: UUID, source: ReminderSource = .manual) async {}
    public func deleteReminder(_ reminder: DocumentReminder) async {}
    public func updateReminder(_ reminder: DocumentReminder) async {}
    public func toggleCompleted(_ reminder: DocumentReminder) async {}
    public func suggestReminders(from result: AnalysisResult, documentId: UUID, documentTitle: String) {}
    public func acceptSuggestion(_ extractedDate: ExtractedDate) async {}
    public func dismissSuggestions() {}
    public func requestPermission() async {}
}

#endif
