//
//  Task.swift
//  DailyToDo
//
//  Created by Oz Soffy on 03/07/2025.
//
import Foundation
import SwiftData

@Model
class Task {
    var id: UUID
    var title: String
    var isRecurring: Bool
    var recurrenceRule: RecurrenceRule?
    var isCompleted: Bool
    var date: Date

    init(title: String, isRecurring: Bool = false, recurrenceRule: RecurrenceRule? = nil, isCompleted: Bool = false, date: Date = .now) {
        self.id = UUID()
        self.title = title
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
        self.isCompleted = isCompleted
        self.date = date
    }
}

