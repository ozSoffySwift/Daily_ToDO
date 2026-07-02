//
//  DailyToDoApp.swift
//  DailyToDo
//
//  Created by Oz Soffy on 03/07/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

/// The app's entry point: builds the shared SwiftData store and root scene.
@main
struct DailyToDoApp: App {
    /// The single shared SwiftData container used by every view in the app,
    /// covering one-time/sticky tasks and recurring habits + their completions.
    var sharedModelContainer: ModelContainer = {
        // All the model types SwiftData needs to know about for this store.
        let schema = Schema([
            TodoTask.self,
            RecurringTask.self,
            RecurringCompletion.self,
        ])
        // A single on-disk (non in-memory) store configuration for the schema above.
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // The store failed to initialize; there's no reasonable way to continue.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// Registers the notification delegate and seeds default habits before any view appears.
    init() {
        // Route notification taps/foreground presentation through our delegate.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        // Populate the starter recurring habits the very first time the app runs.
        DefaultTaskSeeder.seedIfNeeded(context: ModelContext(sharedModelContainer))
    }

    /// The app's single window: the splash-then-daily-list root view, with the model container injected.
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
