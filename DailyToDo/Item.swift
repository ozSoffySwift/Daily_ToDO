//
//  Item.swift
//  DailyToDo
//
//  Shared date helpers for consistent day-based logic.
//

import Foundation

extension Calendar {
    func startOfDay(from date: Date) -> Date {
        startOfDay(for: date)
    }
}

extension Date {
    func startOfDay(using calendar: Calendar = .current) -> Date {
        calendar.startOfDay(from: self)
    }

    func formattedDay(using calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: self)
    }

    func formattedWeekday(using calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
}
