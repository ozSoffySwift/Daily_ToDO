//
//  DailyReflection.swift
//  DailyToDo
//
//  Created by Oz Soffy on 03/07/2025.
//
import Foundation
import SwiftData

@Model
class DailyReflection {
    var id: UUID
    var date: Date
    var notes: String
    var completedTasksCount: Int
    var moodTag: Mood?

    init(date: Date = .now, notes: String = "", completedTasksCount: Int = 0, moodTag: Mood? = nil) {
        self.id = UUID()
        self.date = date
        self.notes = notes
        self.completedTasksCount = completedTasksCount
        self.moodTag = moodTag
    }
}

