//
//  Task.swift
//  DailyToDo
//
//  Core SwiftData model for daily tasks.
//
import Foundation
import SwiftData

/// A one-time task scheduled for a specific day, or a "sticky" task that carries
/// over every day until it's marked done. (Repeating habits use `RecurringTask` instead.)
@Model
final class TodoTask: Identifiable {
    /// Stable unique identifier for this task.
    var id: UUID
    /// The task's display title.
    var title: String
    /// When this task was created.
    var createdAt: Date
    /// The day this task is scheduled for (start-of-day). For sticky tasks, this
    /// is effectively "first appeared on" since it keeps reappearing until done.
    var scheduledDay: Date
    /// Whether the task has been marked done.
    var isCompleted: Bool
    /// The moment the task was marked done, or nil if it isn't completed.
    var completedAt: Date?
    /// Whether this task carries over to future days until it's completed.
    var isSticky: Bool
    /// The hour-of-day (0-23) for the optional reminder notification, if one is set.
    var reminderHour: Int?
    /// The minute-of-hour (0-59) for the optional reminder notification, if one is set.
    var reminderMinute: Int?

    /// Creates a new one-time or sticky task.
    init(
        title: String,
        createdAt: Date,
        scheduledDay: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isSticky: Bool,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
        self.scheduledDay = scheduledDay
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isSticky = isSticky
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    /// Whether this task has a reminder time configured (both hour and minute are set).
    var hasReminder: Bool {
        reminderHour != nil && reminderMinute != nil
    }
}
