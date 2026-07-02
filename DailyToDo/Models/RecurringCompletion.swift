//
//  RecurringCompletion.swift
//  DailyToDo
//
//  Tracks per-day completion of a RecurringTask without materializing a row per day.
//
import Foundation
import SwiftData

/// A record marking that a given `RecurringTask` was completed on a specific day.
/// One row exists per (task, day) the habit was checked off — nothing is stored
/// for days it wasn't, which keeps the store small regardless of how far back a habit goes.
@Model
final class RecurringCompletion: Identifiable {
    /// Stable unique identifier for this completion record.
    var id: UUID
    /// The `id` of the `RecurringTask` this completion belongs to.
    var recurringTaskID: UUID
    /// The calendar day (start-of-day) this completion applies to.
    var day: Date
    /// The exact moment the task was marked complete.
    var completedAt: Date

    /// Creates a completion record for the given recurring task and day.
    init(recurringTaskID: UUID, day: Date, completedAt: Date = .now) {
        self.id = UUID()
        self.recurringTaskID = recurringTaskID
        self.day = day
        self.completedAt = completedAt
    }
}
