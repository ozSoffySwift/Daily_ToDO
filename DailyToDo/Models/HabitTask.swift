//
//  HabitTask.swift
//  DailyToDo
//
//  Data access + view model for daily tasks.
//

import Foundation
import SwiftData

// MARK: - Repository

protocol TaskRepository {
    func fetchTasks(for date: Date) throws -> [TodoTask]
    func fetchArchive() throws -> [TodoTask]
    func addTask(title: String, for date: Date, isSticky: Bool) throws
    func toggleCompleted(_ task: TodoTask) throws
    func toggleSticky(_ task: TodoTask) throws
}

final class SwiftDataTaskRepository: TaskRepository {
    private let context: ModelContext
    private let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func fetchTasks(for date: Date) throws -> [TodoTask] {
        let selectedDay = calendar.startOfDay(for: date)

        let oneTimeDescriptor = FetchDescriptor<TodoTask>(
            predicate: #Predicate { task in
                task.isSticky == false && task.scheduledDay == selectedDay
            }
        )

        let stickyDescriptor = FetchDescriptor<TodoTask>(
            predicate: #Predicate { task in
                task.isSticky == true
            }
        )

        let oneTimeTasks = try context.fetch(oneTimeDescriptor)
        let stickyTasks = try context.fetch(stickyDescriptor)

        let visibleStickyTasks = stickyTasks.filter { task in
            let createdDay = calendar.startOfDay(for: task.createdAt)
            guard createdDay <= selectedDay else { return false }

            if let completedAt = task.completedAt {
                let completedDay = calendar.startOfDay(for: completedAt)
                return completedDay >= selectedDay
            }

            return true
        }

        return (oneTimeTasks + visibleStickyTasks).sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted {
                return !lhs.isCompleted
            }
            if lhs.isSticky != rhs.isSticky {
                return lhs.isSticky
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    func fetchArchive() throws -> [TodoTask] {
        var descriptor = FetchDescriptor<TodoTask>(
            predicate: #Predicate { task in
                task.isCompleted == true
            }
        )
        descriptor.sortBy = [SortDescriptor(\.completedAt, order: .reverse)]
        return try context.fetch(descriptor)
    }

    func addTask(title: String, for date: Date, isSticky: Bool) throws {
        let now = Date()
        let scheduledDay = calendar.startOfDay(for: date)
        let task = TodoTask(
            title: title,
            createdAt: now,
            scheduledDay: scheduledDay,
            isSticky: isSticky
        )
        context.insert(task)
        try context.save()
    }

    func toggleCompleted(_ task: TodoTask) throws {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        try context.save()
    }

    func toggleSticky(_ task: TodoTask) throws {
        task.isSticky.toggle()
        try context.save()
    }
}

// MARK: - View Model

@MainActor
final class DailyTaskViewModel: ObservableObject {
    @Published var selectedDate: Date = Date().startOfDay()
    @Published private(set) var tasks: [TodoTask] = []
    @Published private(set) var archiveTasks: [TodoTask] = []
    @Published var newTaskTitle: String = ""
    @Published var showCalendarPicker = false

    private let calendar: Calendar
    private var repository: TaskRepository?
    private var midnightTimer: Timer?
    private var hasBound = false
    private var followsToday = true

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func bindIfNeeded(context: ModelContext) {
        guard hasBound == false else { return }
        repository = SwiftDataTaskRepository(context: context, calendar: calendar)
        hasBound = true
        setSelectedDate(Date(), followsToday: true)
        scheduleMidnightRefresh()
    }

    func setSelectedDate(_ date: Date, followsToday: Bool? = nil) {
        let normalized = calendar.startOfDay(for: date)
        selectedDate = normalized
        if let followsToday {
            self.followsToday = followsToday
        } else {
            self.followsToday = calendar.isDateInToday(normalized)
        }
        refreshTasks()
    }

    func goToPreviousDay() {
        guard let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        setSelectedDate(newDate, followsToday: calendar.isDateInToday(newDate))
    }

    func goToNextDay() {
        guard let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        setSelectedDate(newDate, followsToday: calendar.isDateInToday(newDate))
    }

    func goToToday() {
        setSelectedDate(Date(), followsToday: true)
    }

    func refreshTasks() {
        guard let repository else { return }
        do {
            tasks = try repository.fetchTasks(for: selectedDate)
        } catch {
            tasks = []
        }
    }

    func refreshArchive() {
        guard let repository else { return }
        do {
            archiveTasks = try repository.fetchArchive()
        } catch {
            archiveTasks = []
        }
    }

    func addTask(isSticky: Bool) {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, let repository else { return }
        do {
            try repository.addTask(title: trimmed, for: selectedDate, isSticky: isSticky)
            newTaskTitle = ""
            refreshTasks()
        } catch {
            return
        }
    }

    func toggleCompleted(_ task: TodoTask) {
        guard let repository else { return }
        do {
            try repository.toggleCompleted(task)
            refreshTasks()
        } catch {
            return
        }
    }

    func toggleSticky(_ task: TodoTask) {
        guard let repository else { return }
        do {
            try repository.toggleSticky(task)
            refreshTasks()
        } catch {
            return
        }
    }

    func handleSignificantTimeChange() {
        if followsToday {
            setSelectedDate(Date(), followsToday: true)
        } else {
            refreshTasks()
        }
        scheduleMidnightRefresh()
    }

    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()
        let now = Date()
        let nextMidnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime,
            direction: .forward
        ) ?? now.addingTimeInterval(60 * 60 * 24)

        let interval = max(1, nextMidnight.timeIntervalSince(now))
        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleSignificantTimeChange()
            }
        }
    }
}
