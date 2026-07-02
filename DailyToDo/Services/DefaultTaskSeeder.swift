//
//  DefaultTaskSeeder.swift
//  DailyToDo
//
//  Seeds a starter set of recurring daily habits the first time the app ever launches.
//
import Foundation
import SwiftData

/// Inserts a starter set of recurring daily habits on the very first app launch.
enum DefaultTaskSeeder {
    /// Titles for the default recurring habits, created once on first launch.
    static let defaultTitles: [String] = [
        "Drink Water",
        "Read for 15 minutes",
        "Write one thing you're grateful for",
        "Stop eating after 20:00",
        "Learn one new word",
        "Review your goals",
    ]

    /// UserDefaults key used to remember whether seeding has already happened.
    private static let hasSeededKey = "DailyToDo.hasSeededDefaultTasks"

    /// Creates the default recurring tasks once, guarded by a UserDefaults flag so
    /// re-launching the app (or deleting all habits later) never reseeds them.
    static func seedIfNeeded(context: ModelContext, calendar: Calendar = .current) {
        guard UserDefaults.standard.bool(forKey: hasSeededKey) == false else { return }

        let today = calendar.startOfDay(for: .now)
        for title in defaultTitles {
            let task = RecurringTask(title: title, rule: .daily, startDate: today)
            context.insert(task)
        }
        try? context.save()

        UserDefaults.standard.set(true, forKey: hasSeededKey)
    }
}
