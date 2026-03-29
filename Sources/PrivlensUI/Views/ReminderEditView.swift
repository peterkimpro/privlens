#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct ReminderEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var reminderDescription: String
    @State private var date: Date
    @State private var documentId: UUID
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let reminderService: ReminderServiceProtocol
    private let existingReminder: DocumentReminder?
    private let onSave: (DocumentReminder) -> Void

    public init(
        reminderService: ReminderServiceProtocol,
        existingReminder: DocumentReminder? = nil,
        documentId: UUID = UUID(),
        onSave: @escaping (DocumentReminder) -> Void
    ) {
        self.reminderService = reminderService
        self.existingReminder = existingReminder
        self.onSave = onSave

        _title = State(initialValue: existingReminder?.title ?? "")
        _reminderDescription = State(initialValue: existingReminder?.reminderDescription ?? "")
        _date = State(initialValue: existingReminder?.date ?? Date().addingTimeInterval(86400))
        _documentId = State(initialValue: existingReminder?.documentId ?? documentId)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $reminderDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Date & Time") {
                    DatePicker("Reminder Date", selection: $date, in: Date()...)
                }

                if let error = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(existingReminder != nil ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveReminder() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }

    private func saveReminder() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let reminder: DocumentReminder
            if let existing = existingReminder {
                var updated = existing
                updated.title = title
                updated.reminderDescription = reminderDescription
                updated.date = date
                reminder = try await reminderService.updateReminder(updated)
            } else {
                let newReminder = DocumentReminder(
                    date: date,
                    title: title,
                    reminderDescription: reminderDescription,
                    documentId: documentId
                )
                reminder = try await reminderService.scheduleReminder(newReminder)
            }
            onSave(reminder)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#endif
