//
//  TaskRepository.swift
//  DailyToDo
//
//  Data access layer for one-time/sticky tasks and recurring habits.
//
import Foundation
import SwiftData

/// A recurring task paired with whether it's already been completed on the day it's being shown for.
struct RecurringTaskStatus: Identifiable {
    /// The recurring task this status describes.
    let task: RecurringTask
    /// Whether `task` has been checked off for the day currently being viewed.
    let isCompleted: Bool
    /// Identifies this status by its underlying task's id, for use in SwiftUI lists.
    var id: UUID { task.id }
}

/// Abstracts all reads/writes for tasks and recurring habits, so view models don't
/// talk to SwiftData directly. `SwiftDataTaskRepository` is the only implementation today.
protocol TaskRepository {
    /// Returns the one-time and sticky tasks that should be visible on the given date.
    func fetchTasks(for date: Date) throws -> [TodoTask]
    /// Returns every completed task, most recently completed first.
    func fetchArchive() throws -> [TodoTask]
    /// Creates a new one-time or sticky task, optionally with a reminder.
    func addTask(title: String, for date: Date, isSticky: Bool, reminderHour: Int?, reminderMinute: Int?) throws
    /// Flips a task's completed state.
    func toggleCompleted(_ task: TodoTask) throws
    /// Flips whether a task carries over day to day until completed.
    func toggleSticky(_ task: TodoTask) throws
    /// Permanently removes a task.
    func deleteTask(_ task: TodoTask) throws

    /// Returns the recurring habits due on the given date, with their completion state for that date.
    func fetchRecurringStatuses(for date: Date) throws -> [RecurringTaskStatus]
    /// Creates a new recurring habit, optionally with a reminder.
    func addRecurringTask(title: String, rule: RecurrenceRule, startDate: Date, reminderHour: Int?, reminderMinute: Int?) throws
    /// Flips whether a recurring habit is completed on the given date.
    func toggleRecurringCompletion(_ task: RecurringTask, for date: Date) throws
    /// Permanently removes a recurring habit and all of its completion history.
    func deleteRecurringTask(_ task: RecurringTask) throws
}

/// The SwiftData-backed implementation of `TaskRepository`, used throughout the app.
final class SwiftDataTaskRepository: TaskRepository {
    /// The SwiftData context this repository reads from and writes to.
    private let context: ModelContext
    /// The calendar used for all day-boundary math (start-of-day, weekday, etc.).
    private let calendar: Calendar

    /// Creates a repository backed by the given SwiftData context.
    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    // MARK: - One-time / sticky tasks

    /// Returns the tasks visible on `date`: one-time tasks scheduled for that exact
    /// day, plus any still-incomplete sticky tasks created on or before it.
    func fetchTasks(for date: Date) throws -> [TodoTask] {
        let selectedDay = calendar.startOfDay(for: date)

        // One-time tasks only ever appear on the exact day they were scheduled for.
        let oneTimeDescriptor = FetchDescriptor<TodoTask>(
            predicate: #Predicate { task in
                task.isSticky == false && task.scheduledDay == selectedDay
            }
        )

        // Sticky tasks are fetched in full, then filtered in Swift below since their
        // visibility depends on creation/completion dates relative to the selected day.
        let stickyDescriptor = FetchDescriptor<TodoTask>(
            predicate: #Predicate { task in
                task.isSticky == true
            }
        )

        let oneTimeTasks = try context.fetch(oneTimeDescriptor)
        let stickyTasks = try context.fetch(stickyDescriptor)

        // A sticky task is visible from its creation day onward, and stops being visible
        // the day after it was completed (so completing it "in the past" doesn't hide it retroactively).
        let visibleStickyTasks = stickyTasks.filter { task in
            let createdDay = calendar.startOfDay(for: task.createdAt)
            guard createdDay <= selectedDay else { return false }

            if let completedAt = task.completedAt {
                let completedDay = calendar.startOfDay(for: completedAt)
                return completedDay >= selectedDay
            }

            return true
        }

        // Incomplete tasks first, then sticky tasks, then oldest-first within each group.
        return (oneTimeTasks + visibleStickyTasks).sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            if lhs.isSticky != rhs.isSticky {
                return lhs.isSticky
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    /// Returns every completed task across all days, most recently completed first.
    func fetchArchive() throws -> [TodoTask] {
        var descriptor = FetchDescriptor<TodoTask>(
            predicate: #Predicate { task in
                task.isCompleted == true
            }
        )
        descriptor.sortBy = [SortDescriptor(\.completedAt, order: .reverse)]
        return try context.fetch(descriptor)
    }

    /// Inserts a new one-time or sticky task and, if a reminder time was given, schedules it.
    func addTask(title: String, for date: Date, isSticky: Bool, reminderHour: Int?, reminderMinute: Int?) throws {
        let now = Date()
        let scheduledDay = calendar.startOfDay(for: date)
        let task = TodoTask(
            title: title,
            createdAt: now,
            scheduledDay: scheduledDay,
            isSticky: isSticky,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute
        )
        context.insert(task)
        try context.save()

        if let hour = reminderHour, let minute = reminderMinute {
            NotificationScheduler.scheduleTaskReminder(taskID: task.id, title: title, day: scheduledDay, hour: hour, minute: minute, calendar: calendar)
        }
    }

    /// Toggles a task's completed flag and keeps its reminder notification in sync
    /// (cancelled when completed, re-scheduled if un-completed).
    func toggleCompleted(_ task: TodoTask) throws {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        try context.save()

        if task.isCompleted {
            NotificationScheduler.cancelTaskReminder(taskID: task.id)
        } else if let hour = task.reminderHour, let minute = task.reminderMinute {
            NotificationScheduler.scheduleTaskReminder(taskID: task.id, title: task.title, day: task.scheduledDay, hour: hour, minute: minute, calendar: calendar)
        }
    }

    /// Toggles whether a task carries over day to day until completed.
    func toggleSticky(_ task: TodoTask) throws {
        task.isSticky.toggle()
        try context.save()
    }

    /// Cancels any pending reminder and permanently removes the task.
    func deleteTask(_ task: TodoTask) throws {
        NotificationScheduler.cancelTaskReminder(taskID: task.id)
        context.delete(task)
        try context.save()
    }

    // MARK: - Recurring tasks

    /// Returns the active recurring habits whose rule makes them due on `date`,
    /// each paired with whether it was already completed that day.
    func fetchRecurringStatuses(for date: Date) throws -> [RecurringTaskStatus] {
        let selectedDay = calendar.startOfDay(for: date)

        // Only non-archived habits are ever candidates.
        let descriptor = FetchDescriptor<RecurringTask>(
            predicate: #Predicate { task in
                task.isArchived == false
            }
        )
        let allTasks = try context.fetch(descriptor)
        // The due/not-due decision depends on custom Swift logic (RecurrenceRule.isDue),
        // which SwiftData predicates can't express, so it's filtered here instead.
        let dueTasks = allTasks.filter { $0.rule.isDue(on: selectedDay, since: $0.startDate, calendar: calendar) }
        guard dueTasks.isEmpty == false else { return [] }

        // Look up which of today's due tasks already have a completion record for this day.
        let taskIDs = Set(dueTasks.map(\.id))
        let completionDescriptor = FetchDescriptor<RecurringCompletion>(
            predicate: #Predicate { completion in
                completion.day == selectedDay
            }
        )
        let completions = try context.fetch(completionDescriptor)
        let completedIDs = Set(completions.filter { taskIDs.contains($0.recurringTaskID) }.map(\.recurringTaskID))

        let statuses = dueTasks.map { RecurringTaskStatus(task: $0, isCompleted: completedIDs.contains($0.id)) }
        // Incomplete habits first, then completed ones (so checking one off sends it to the
        // bottom of the section), oldest-first within each group.
        return statuses.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            return lhs.task.createdAt < rhs.task.createdAt
        }
    }

    /// Inserts a new recurring habit and, if a reminder time was given, schedules its upcoming reminders.
    func addRecurringTask(title: String, rule: RecurrenceRule, startDate: Date, reminderHour: Int?, reminderMinute: Int?) throws {
        let task = RecurringTask(
            title: title,
            rule: rule,
            startDate: calendar.startOfDay(for: startDate),
            reminderHour: reminderHour,
            reminderMinute: reminderMinute
        )
        context.insert(task)
        try context.save()

        if let hour = reminderHour, let minute = reminderMinute {
            // No completions exist yet for a brand-new task, so the full window is scheduled.
            NotificationScheduler.rescheduleRecurringReminders(
                taskID: task.id, title: title, rule: rule, startDate: task.startDate,
                hour: hour, minute: minute, completedDays: [], calendar: calendar
            )
        }
    }

    /// Toggles a recurring habit's completion for the given day, inserting or removing
    /// its `RecurringCompletion` record, and refreshes its upcoming reminders to match.
    func toggleRecurringCompletion(_ task: RecurringTask, for date: Date) throws {
        let day = calendar.startOfDay(for: date)
        let taskID = task.id
        let descriptor = FetchDescriptor<RecurringCompletion>(
            predicate: #Predicate { completion in
                completion.recurringTaskID == taskID && completion.day == day
            }
        )
        let existing = try context.fetch(descriptor)

        if let completion = existing.first {
            // Already completed for this day — un-complete it.
            context.delete(completion)
        } else {
            // Not yet completed for this day — mark it done now.
            context.insert(RecurringCompletion(recurringTaskID: taskID, day: day))
        }
        try context.save()

        if let hour = task.reminderHour, let minute = task.reminderMinute {
            // Completed days should stop reminding, so recompute the reminder window.
            let completedDays = try completedDays(for: taskID)
            NotificationScheduler.rescheduleRecurringReminders(
                taskID: taskID, title: task.title, rule: task.rule, startDate: task.startDate,
                hour: hour, minute: minute, completedDays: completedDays, calendar: calendar
            )
        }
    }

    /// Permanently removes a recurring habit, its completion history, and any pending reminders.
    func deleteRecurringTask(_ task: RecurringTask) throws {
        let taskID = task.id
        let descriptor = FetchDescriptor<RecurringCompletion>(
            predicate: #Predicate { completion in
                completion.recurringTaskID == taskID
            }
        )
        for completion in try context.fetch(descriptor) {
            context.delete(completion)
        }
        NotificationScheduler.cancelRecurringReminders(taskID: taskID)
        context.delete(task)
        try context.save()
    }

    /// Returns every day (start-of-day) on which the given recurring task has been completed.
    private func completedDays(for taskID: UUID) throws -> Set<Date> {
        let descriptor = FetchDescriptor<RecurringCompletion>(
            predicate: #Predicate { completion in
                completion.recurringTaskID == taskID
            }
        )
        return Set(try context.fetch(descriptor).map(\.day))
    }
}
