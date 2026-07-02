//
//  RecurringTask.swift
//  DailyToDo
//
//  SwiftData model for repeating habits/tasks.
//
import Foundation
import SwiftData

/// A repeating habit/task, e.g. "Drink Water" every day. Its per-day completion
/// state is tracked separately by `RecurringCompletion`, not stored on this model.
@Model
final class RecurringTask: Identifiable {
    /// Stable unique identifier for this recurring task.
    var id: UUID
    /// The habit's display title, e.g. "Drink Water".
    var title: String
    /// The recurrence rule that determines which days this task is due.
    var rule: RecurrenceRule
    /// The day this task starts being due; it never appears before this date.
    var startDate: Date
    /// The hour-of-day (0-23) for the optional reminder notification, if one is set.
    var reminderHour: Int?
    /// The minute-of-hour (0-59) for the optional reminder notification, if one is set.
    var reminderMinute: Int?
    /// Whether this task has been archived (soft-deleted / hidden from the day list).
    var isArchived: Bool
    /// When this recurring task was first created.
    var createdAt: Date

    /// Creates a new recurring task with the given title, rule, and optional reminder time.
    init(
        title: String,
        rule: RecurrenceRule,
        startDate: Date,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil,
        isArchived: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.rule = rule
        self.startDate = startDate
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isArchived = isArchived
        self.createdAt = createdAt
    }

    /// Whether this task has a reminder time configured (both hour and minute are set).
    var hasReminder: Bool {
        reminderHour != nil && reminderMinute != nil
    }
}
