//
//  InlineAddTaskView.swift
//  DailyToDo
//
//  Inline, always-in-flow task/habit creation card shown beneath the top bar,
//  replacing the old modal "New Task" sheet for a faster add flow.
//
import SwiftUI

/// An inline card for quickly adding a one-time, sticky, or recurring task without
/// leaving the daily list. The title field takes almost the full row, with a single
/// "Options" button that expands every other setting (type, recurrence, reminder)
/// below it, pushing the task list further down rather than covering it.
struct InlineAddTaskView: View {
    /// The view model this form creates tasks through.
    @ObservedObject var viewModel: DailyTaskViewModel
    /// Puts keyboard focus in the title field whenever this view appears or a task is added.
    @FocusState private var isTitleFocused: Bool

    /// The three kinds of task this form can create.
    enum TaskKind: String, CaseIterable, Identifiable {
        /// A task scheduled for a single specific day.
        case oneTime = "One-time"
        /// A task that carries over every day until it's completed.
        case sticky = "Sticky"
        /// A task that repeats on a schedule.
        case recurring = "Recurring"
        /// Uses the raw string as a stable identifier for `ForEach`.
        var id: String { rawValue }
    }

    /// The recurrence presets offered when `kind == .recurring`.
    enum RecurrenceOption: String, CaseIterable, Identifiable {
        /// Repeats every day.
        case daily = "Daily"
        /// Repeats Monday through Friday.
        case weekdays = "Weekdays"
        /// Repeats on whichever days the user picks in `weekdayToggles`.
        case custom = "Custom days"
        /// Uses the raw string as a stable identifier for `ForEach`.
        var id: String { rawValue }
    }

    /// The task title being entered.
    @State private var title = ""
    /// Whether the options panel (type, recurrence, reminder) is expanded.
    @State private var showOptions = false
    /// Which kind of task is being created.
    @State private var kind: TaskKind = .oneTime
    /// Which recurrence preset is selected when `kind == .recurring`.
    @State private var recurrenceOption: RecurrenceOption = .daily
    /// The specific weekday numbers selected for `.custom` recurrence (defaults to weekdays).
    @State private var customDays: Set<Int> = [2, 3, 4, 5, 6]
    /// Whether a reminder notification should be scheduled for this task.
    @State private var hasReminder = false
    /// The time-of-day picked for the reminder, when `hasReminder` is true.
    @State private var reminderTime = Date()

    /// The title with leading/trailing whitespace removed, used for validation and saving.
    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // The always-visible row: a large title field plus a single "Options" disclosure.
            HStack(spacing: 8) {
                TextField("What do you need to do?", text: $title)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit(addTask)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.appBackground))

                Button {
                    withAnimation(.easeInOut) { showOptions.toggle() }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.warmPrimaryText)
                        .frame(width: 48, height: 44)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.appBackground))
                }
                .accessibilityLabel("Options")
            }

            // Every other setting lives here, only shown once "Options" is expanded —
            // pushing the task list further down instead of covering it.
            if showOptions {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Type", selection: $kind.animation(.easeInOut)) {
                        ForEach(TaskKind.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if kind == .sticky {
                        Text("Sticky tasks carry over every day until you mark them done.")
                            .font(.footnote)
                            .foregroundStyle(Color.warmSecondaryText)
                    }

                    if kind == .recurring {
                        Picker("Repeats", selection: $recurrenceOption) {
                            ForEach(RecurrenceOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        if recurrenceOption == .custom {
                            weekdayToggles
                        }
                    }

                    Divider()

                    Toggle("Remind me", isOn: $hasReminder.animation(.easeInOut))
                        .tint(Color.accentColor)

                    if hasReminder {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .tint(Color.accentColor)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cardSurface))
        .onAppear { isTitleFocused = true }
    }

    /// A row of tappable weekday-initial circles for picking custom recurrence days.
    private var weekdayToggles: some View {
        let symbols = Calendar.current.shortWeekdaySymbols
        return HStack {
            ForEach(1...7, id: \.self) { weekday in
                let isOn = customDays.contains(weekday)
                Button {
                    if isOn {
                        customDays.remove(weekday)
                    } else {
                        customDays.insert(weekday)
                    }
                } label: {
                    Text(symbols[weekday - 1].prefix(1))
                        .font(.caption.bold())
                        .frame(width: 26, height: 26)
                        .background(isOn ? Color.accentColor : Color.accentColor.opacity(0.15))
                        .foregroundStyle(isOn ? Color.white : Color.warmPrimaryText)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Builds the appropriate task (one-time, sticky, or recurring) from the current form
    /// state, requests notification permission if a reminder was set, then clears the
    /// title and collapses the options panel so the row is ready for the next quick add.
    private func addTask() {
        guard trimmedTitle.isEmpty == false else { return }
        // Reminder hour/minute are only meaningful when a reminder was actually requested.
        let hour = hasReminder ? Calendar.current.component(.hour, from: reminderTime) : nil
        let minute = hasReminder ? Calendar.current.component(.minute, from: reminderTime) : nil

        switch kind {
        case .oneTime:
            viewModel.addTask(title: trimmedTitle, isSticky: false, reminderHour: hour, reminderMinute: minute)
        case .sticky:
            viewModel.addTask(title: trimmedTitle, isSticky: true, reminderHour: hour, reminderMinute: minute)
        case .recurring:
            let rule: RecurrenceRule
            switch recurrenceOption {
            case .daily: rule = .daily
            case .weekdays: rule = .weekdays
            case .custom: rule = .weekly(days: Array(customDays))
            }
            viewModel.addRecurringTask(title: trimmedTitle, rule: rule, reminderHour: hour, reminderMinute: minute)
        }

        if hasReminder {
            // Ask for notification permission lazily, only once the user actually wants one.
            Task { await NotificationScheduler.requestAuthorizationIfNeeded() }
        }

        // Reset for the next entry, but keep the row open and focused for fast, repeated adds.
        withAnimation(.easeInOut) {
            title = ""
            kind = .oneTime
            showOptions = false
            hasReminder = false
        }
        isTitleFocused = true
    }
}

#Preview {
    InlineAddTaskView(viewModel: DailyTaskViewModel())
        .padding()
}
