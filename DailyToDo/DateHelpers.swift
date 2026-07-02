//
//  DateHelpers.swift
//  DailyToDo
//
//  Shared date helpers for consistent day-based logic.
//

import Foundation

extension Calendar {
    /// Returns the start-of-day (midnight) for the given date, using this calendar.
    func startOfDay(from date: Date) -> Date {
        startOfDay(for: date)
    }
}

extension Date {
    /// Returns the start-of-day (midnight) for this date, using the given calendar (defaults to the current one).
    func startOfDay(using calendar: Calendar = .current) -> Date {
        calendar.startOfDay(from: self)
    }

    /// Formats this date as a long day string, e.g. "July 1, 2026".
    func formattedDay(using calendar: Calendar = .current) -> String {
        // A dedicated formatter so the calendar/format stay tied to this call only.
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: self)
    }

    /// Formats this date as a full weekday name, e.g. "Wednesday".
    func formattedWeekday(using calendar: Calendar = .current) -> String {
        // A dedicated formatter so the calendar/format stay tied to this call only.
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
}
