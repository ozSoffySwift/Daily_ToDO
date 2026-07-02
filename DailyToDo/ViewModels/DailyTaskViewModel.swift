//
//  DailyTaskViewModel.swift
//  DailyToDo
//
//  Drives the daily task list: date navigation, tasks, and recurring habits.
//
import Foundation
import SwiftData
import SwiftUI

/// Backs `DailyView`: owns the selected date, the tasks/habits visible on it,
/// and every user action (add, toggle, delete) that can change them.
@MainActor
final class DailyTaskViewModel: ObservableObject {
    /// The day currently being viewed (always normalized to start-of-day).
    @Published var selectedDate: Date = Date().startOfDay()
    /// The one-time and sticky tasks visible on `selectedDate`.
    @Published private(set) var tasks: [TodoTask] = []
    /// The recurring habits due on `selectedDate`, with their completion state.
    @Published private(set) var recurringStatuses: [RecurringTaskStatus] = []
    /// Every completed task, most recently completed first, for the Archive screen.
    @Published private(set) var archiveTasks: [TodoTask] = []
    /// Whether the calendar jump-to-date sheet is currently presented.
    @Published var showCalendarPicker = false

    /// The calendar used for all day-boundary math.
    private let calendar: Calendar
    /// The data layer this view model reads from and writes to, set once by `bindIfNeeded`.
    private var repository: TaskRepository?
    /// A one-shot timer that fires at the next midnight to refresh the view.
    private var midnightTimer: Timer?
    /// Whether `bindIfNeeded` has already run, so it only binds once.
    private var hasBound = false
    /// Whether the selected date should automatically track "today" as days pass.
    private var followsToday = true

    /// How many of today's tasks and habits are completed.
    var completedCount: Int {
        tasks.filter(\.isCompleted).count + recurringStatuses.filter(\.isCompleted).count
    }

    /// The total number of tasks and habits visible on the selected date.
    var totalCount: Int {
        tasks.count + recurringStatuses.count
    }

    /// Creates the view model. Nothing loads until `bindIfNeeded` is called with a live context.
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Wires up the SwiftData-backed repository and loads today's data. Safe to call
    /// repeatedly (e.g. from `onAppear`) — only the first call has any effect.
    func bindIfNeeded(context: ModelContext) {
        guard hasBound == false else { return }
        repository = SwiftDataTaskRepository(context: context, calendar: calendar)
        hasBound = true
        setSelectedDate(Date(), followsToday: true)
        scheduleMidnightRefresh()
    }

    /// Changes the selected date and reloads its tasks/habits.
    /// - Parameter followsToday: Whether the view should keep following "today" going forward.
    ///   Defaults to auto-detecting based on whether `date` is today.
    func setSelectedDate(_ date: Date, followsToday: Bool? = nil) {
        let normalized = calendar.startOfDay(for: date)
        selectedDate = normalized
        if let followsToday {
            self.followsToday = followsToday
        } else {
            self.followsToday = calendar.isDateInToday(normalized)
        }
        refreshTasks()
    }

    /// Moves the selected date back by one day.
    func goToPreviousDay() {
        guard let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        setSelectedDate(newDate, followsToday: calendar.isDateInToday(newDate))
    }

    /// Moves the selected date forward by one day.
    func goToNextDay() {
        guard let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        setSelectedDate(newDate, followsToday: calendar.isDateInToday(newDate))
    }

    /// Jumps the selected date back to today.
    func goToToday() {
        setSelectedDate(Date(), followsToday: true)
    }

    /// Reloads `tasks` and `recurringStatuses` for the currently selected date.
    func refreshTasks() {
        guard let repository else { return }
        do {
            tasks = try repository.fetchTasks(for: selectedDate)
            recurringStatuses = try repository.fetchRecurringStatuses(for: selectedDate)
        } catch {
            tasks = []
            recurringStatuses = []
        }
    }

    /// Reloads `archiveTasks` from the repository.
    func refreshArchive() {
        guard let repository else { return }
        do {
            archiveTasks = try repository.fetchArchive()
        } catch {
            archiveTasks = []
        }
    }

    /// Creates a new one-time or sticky task on the selected date, ignoring blank titles.
    func addTask(title: String, isSticky: Bool, reminderHour: Int? = nil, reminderMinute: Int? = nil) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, let repository else { return }
        do {
            try repository.addTask(title: trimmed, for: selectedDate, isSticky: isSticky, reminderHour: reminderHour, reminderMinute: reminderMinute)
            refreshTasks()
        } catch {
            return
        }
    }

    /// Creates a new recurring habit starting on the selected date, ignoring blank titles.
    func addRecurringTask(title: String, rule: RecurrenceRule, reminderHour: Int?, reminderMinute: Int?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, let repository else { return }
        do {
            try repository.addRecurringTask(title: trimmed, rule: rule, startDate: selectedDate, reminderHour: reminderHour, reminderMinute: reminderMinute)
            refreshTasks()
        } catch {
            return
        }
    }

    /// Flips a one-time/sticky task's completed state and reloads the list, animating
    /// its move to (or from) the bottom of the section since completed items sort last.
    func toggleCompleted(_ task: TodoTask) {
        guard let repository else { return }
        do {
            try repository.toggleCompleted(task)
            withAnimation(.easeInOut(duration: 0.35)) {
                refreshTasks()
            }
        } catch {
            return
        }
    }

    /// Flips whether a task carries over day to day, and reloads the list.
    func toggleSticky(_ task: TodoTask) {
        guard let repository else { return }
        do {
            try repository.toggleSticky(task)
            refreshTasks()
        } catch {
            return
        }
    }

    /// Permanently deletes a one-time/sticky task and reloads the list.
    func deleteTask(_ task: TodoTask) {
        guard let repository else { return }
        try? repository.deleteTask(task)
        refreshTasks()
    }

    /// Flips a recurring habit's completion for the selected date, reloads the list, and
    /// animates its move to (or from) the bottom of the section since completed items sort last.
    func toggleRecurringCompletion(_ task: RecurringTask) {
        guard let repository else { return }
        do {
            try repository.toggleRecurringCompletion(task, for: selectedDate)
            // Animate the move to (or from) the bottom of the section, since completed habits sort last.
            withAnimation(.easeInOut(duration: 0.35)) {
                refreshTasks()
            }
        } catch {
            return
        }
    }

    /// Permanently deletes a recurring habit and reloads the list.
    func deleteRecurringTask(_ task: RecurringTask) {
        guard let repository else { return }
        try? repository.deleteRecurringTask(task)
        refreshTasks()
    }

    /// Called when the system reports a significant time change (day rollover, clock change,
    /// or the app returning to the foreground). Jumps to today if the view was following it,
    /// otherwise just reloads the current date's data, then re-arms the midnight timer.
    func handleSignificantTimeChange() {
        if followsToday {
            setSelectedDate(Date(), followsToday: true)
        } else {
            refreshTasks()
        }
        scheduleMidnightRefresh()
    }

    /// (Re)schedules a one-shot timer that fires at the next midnight to refresh the day.
    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()
        let now = Date()
        // Find the next occurrence of 00:00:00, falling back to "24 hours from now" if that fails.
        let nextMidnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime,
            direction: .forward
        ) ?? now.addingTimeInterval(60 * 60 * 24)

        let interval = max(1, nextMidnight.timeIntervalSince(now))
        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleSignificantTimeChange()
            }
        }
    }
}
