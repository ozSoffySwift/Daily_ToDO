//
//  RecurrenceRule.swift
//  DailyToDo
//
//  Defines how a recurring task repeats and whether it is due on a given day.
//

import Foundation

/// How often a `RecurringTask` repeats, and the logic for whether it's due on a given day.
enum RecurrenceRule: Codable, Equatable {
    /// Repeats every single day.
    case daily
    /// Repeats Monday through Friday only.
    case weekdays
    /// Repeats on specific weekdays. Values use Calendar weekday numbers: 1 = Sunday ... 7 = Saturday.
    case weekly(days: [Int])
    /// Repeats every N days, counted from the task's start date.
    case everyNDays(Int)

    /// Returns whether this rule makes the task due on the given `day`, relative to `startDate`.
    func isDue(on day: Date, since startDate: Date, calendar: Calendar = .current) -> Bool {
        // Normalize both dates to midnight so only the calendar day matters, not time-of-day.
        let day = calendar.startOfDay(for: day)
        let startDate = calendar.startOfDay(for: startDate)
        // A recurring task never appears before its own start date.
        guard day >= startDate else { return false }

        switch self {
        case .daily:
            // Always due once the start date has passed.
            return true
        case .weekdays:
            // Calendar weekday numbers 2...6 are Monday...Friday.
            let weekday = calendar.component(.weekday, from: day)
            return (2...6).contains(weekday)
        case .weekly(let days):
            // Due only on the specific weekday numbers the user picked.
            let weekday = calendar.component(.weekday, from: day)
            return days.contains(weekday)
        case .everyNDays(let interval):
            // Guard against a non-positive interval, which would be meaningless/divide-by-zero prone.
            guard interval > 0 else { return false }
            // Due when the number of whole days since the start date is an exact multiple of the interval.
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: day).day ?? 0
            return daysSinceStart % interval == 0
        }
    }

    /// A short human-readable description of the rule, shown in habit rows (e.g. "Every Mon, Wed, Fri").
    var summary: String {
        switch self {
        case .daily:
            return "Every day"
        case .weekdays:
            return "Weekdays"
        case .weekly(let days):
            // Map weekday numbers back to short names (e.g. "Mon") in the user's locale, in day order.
            let symbols = Calendar.current.shortWeekdaySymbols
            let ordered = days.sorted().compactMap { symbols.indices.contains($0 - 1) ? symbols[$0 - 1] : nil }
            return "Every \(ordered.joined(separator: ", "))"
        case .everyNDays(let interval):
            return interval == 1 ? "Every day" : "Every \(interval) days"
        }
    }
}
