#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct RemindersView: View {
    @State private var viewModel = ReminderViewModel()
    @State private var showCreateReminder = false
    @State private var editingReminder: DocumentReminder?

    private let reminderService: ReminderServiceProtocol

    public init(reminderService: ReminderServiceProtocol) {
        self.reminderService = reminderService
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading reminders...")
                } else if viewModel.reminders.isEmpty {
                    ContentUnavailableView(
                        "No Reminders",
                        systemImage: "bell.slash",
                        description: Text("Reminders will appear here after you analyze documents with key dates.")
                    )
                } else {
                    remindersList
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateReminder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                viewModel.configure(reminderService: reminderService)
                await viewModel.requestPermission()
                await viewModel.loadReminders()
            }
            .sheet(isPresented: $showCreateReminder) {
                ReminderEditView(reminderService: reminderService) { reminder in
                    Task {
                        await viewModel.loadReminders()
                    }
                    showCreateReminder = false
                }
            }
            .sheet(item: $editingReminder) { reminder in
                ReminderEditView(
                    reminderService: reminderService,
                    existingReminder: reminder
                ) { _ in
                    Task {
                        await viewModel.loadReminders()
                    }
                    editingReminder = nil
                }
            }
            .sheet(isPresented: $viewModel.showSuggestions) {
                suggestedRemindersSheet
            }
        }
    }

    // MARK: - Reminders List

    private var remindersList: some View {
        List {
            // Upcoming, grouped by date
            ForEach(viewModel.groupedReminders, id: \.date) { group in
                Section {
                    ForEach(group.reminders) { reminder in
                        reminderRow(reminder)
                    }
                } header: {
                    Text(group.date, style: .date)
                }
            }

            // Completed
            if !viewModel.completedReminders.isEmpty {
                Section("Completed") {
                    ForEach(viewModel.completedReminders) { reminder in
                        reminderRow(reminder)
                    }
                }
            }
        }
    }

    private func reminderRow(_ reminder: DocumentReminder) -> some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.toggleCompleted(reminder) }
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(reminder.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .strikethrough(reminder.isCompleted)
                    .foregroundStyle(reminder.isCompleted ? .secondary : .primary)

                Text(reminder.reminderDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(reminder.date, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tint)

                    if reminder.source == .autoExtracted {
                        Label("Auto", systemImage: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task { await viewModel.deleteReminder(reminder) }
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                editingReminder = reminder
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    // MARK: - Suggested Reminders Sheet

    private var suggestedRemindersSheet: some View {
        NavigationStack {
            List {
                Section {
                    Text("We found dates in your document analysis. Would you like to create reminders?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(viewModel.suggestedDates) { date in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(date.label)
                                    .font(.headline)
                                Text(date.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.tint)
                                Text(date.context)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Button {
                                Task { await viewModel.acceptSuggestion(date) }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Suggested Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        viewModel.dismissSuggestions()
                    }
                }
            }
        }
    }
}

#endif
