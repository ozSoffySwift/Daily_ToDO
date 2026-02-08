//
//  Task.swift
//  TodoDaily
//
//  Created by Oz Soffy on 28/04/2025.
//

import Foundation

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isDone: Bool = false
}

enum RecurrenceKind: String, Codable, CaseIterable {
    case none
    case daily
    case weekly
    case everyNDays
}

struct RecurrenceRule: Codable, Equatable {
    var kind: RecurrenceKind
    var intervalDays: Int

    static let none = RecurrenceRule(kind: .none, intervalDays: 0)
    static let daily = RecurrenceRule(kind: .daily, intervalDays: 1)
    static let weekly = RecurrenceRule(kind: .weekly, intervalDays: 7)

    var displayLabel: String {
        switch kind {
        case .none:
            return "None"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .everyNDays:
            return "Every \(intervalDays) days"
        }
    }

    var resolvedIntervalDays: Int? {
        switch kind {
        case .none:
            return nil
        case .daily:
            return 1
        case .weekly:
            return 7
        case .everyNDays:
            return max(intervalDays, 1)
        }
    }
}

struct RecurringTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var startDate: Date
    var rule: RecurrenceRule
}

struct TaskItem: Identifiable {
    enum Source {
        case single(dateKey: String)
        case recurring(id: UUID)
    }

    var id: UUID
    var title: String
    var isDone: Bool
    var recurrenceLabel: String?
    var source: Source
}
