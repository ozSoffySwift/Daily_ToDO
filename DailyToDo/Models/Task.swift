//
//  Task.swift
//  DailyToDo
//
//  Core SwiftData model for daily tasks.
//
import Foundation
import SwiftData

@Model
final class TodoTask: Identifiable {
    var id: UUID
    var title: String
    var createdAt: Date
    var scheduledDay: Date
    var isCompleted: Bool
    var completedAt: Date?
    var isSticky: Bool

    init(
        title: String,
        createdAt: Date,
        scheduledDay: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isSticky: Bool
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
        self.scheduledDay = scheduledDay
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isSticky = isSticky
    }
}
