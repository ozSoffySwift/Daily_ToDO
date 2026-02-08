import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager
    let date: Date
    let existingItem: TaskItem?

    @State private var title: String = ""
    @State private var recurrence: RecurrenceRule = .none
    @State private var customInterval: Int = 2
    @State private var showRecurrencePicker = false

    private var isEditing: Bool {
        existingItem != nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(isEditing ? "Edit Task" : "New Task")) {
                    TextField("Task title", text: $title)
                }

                Section(header: Text("Recurrence")) {
                    Button {
                        showRecurrencePicker = true
                    } label: {
                        HStack {
                            Text("Repeat")
                            Spacer()
                            Text(recurrence.displayLabel)
                                .foregroundColor(.secondary)
                        }
                    }
                    .confirmationDialog("Choose recurrence", isPresented: $showRecurrencePicker, titleVisibility: .visible) {
                        Button("None") { recurrence = .none }
                        Button("Daily") { recurrence = .daily }
                        Button("Weekly") { recurrence = .weekly }
                        Button("Every N days") {
                            recurrence = RecurrenceRule(kind: .everyNDays, intervalDays: max(customInterval, 2))
                        }
                    }

                    if recurrence.kind == .everyNDays {
                        Stepper(value: $customInterval, in: 2...30) {
                            Text("Every \(customInterval) days")
                        }
                        .onChange(of: customInterval) { newValue in
                            recurrence = RecurrenceRule(kind: .everyNDays, intervalDays: newValue)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveTask()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let item = existingItem {
                    title = item.title
                    let rule = taskManager.recurrenceRule(for: item)
                    recurrence = rule
                    if rule.kind == .everyNDays {
                        customInterval = max(rule.intervalDays, 2)
                    }
                }
            }
        }
    }

    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if var updatedRule = adjustedRecurrenceRule() {
            if let existingItem = existingItem {
                taskManager.updateTask(item: existingItem, newTitle: trimmedTitle, recurrence: updatedRule, for: date)
            } else {
                taskManager.addTask(title: trimmedTitle, for: date, recurrence: updatedRule)
            }
        }
    }

    private func adjustedRecurrenceRule() -> RecurrenceRule? {
        if recurrence.kind == .everyNDays {
            return RecurrenceRule(kind: .everyNDays, intervalDays: max(customInterval, 2))
        }
        return recurrence
    }
}
