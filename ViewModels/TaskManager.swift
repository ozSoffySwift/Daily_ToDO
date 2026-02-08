//
//  TaskManager.swift
//  TodoDaily
//
//  Created by Oz Soffy on 29/04/2025.
//

import Foundation
import Combine

class TaskManager: ObservableObject {
    @Published var tasksByDate: [String: [Task]] = [:]
    @Published var recurringTasks: [RecurringTask] = []
    @Published var recurringCompletionByDate: [String: [UUID]] = [:]

    private let tasksByDateKey = "tasksByDate"
    private let recurringTasksKey = "recurringTasks"
    private let recurringCompletionKey = "recurringCompletionByDate"

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    init() {
        loadTasks()
    }

    // MARK: - Date Helpers

    func dateString(for date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    // MARK: - Public Actions

    func tasks(for date: Date) -> [Task] {
        let key = dateString(for: date)
        return tasksByDate[key] ?? []
    }

    func taskItems(for date: Date) -> [TaskItem] {
        let key = dateString(for: date)
        let oneTimeTasks = (tasksByDate[key] ?? []).map { task in
            TaskItem(
                id: task.id,
                title: task.title,
                isDone: task.isDone,
                recurrenceLabel: nil,
                source: .single(dateKey: key)
            )
        }

        let recurringItems = recurringTasks
            .filter { isRecurringTask($0, on: date) }
            .map { task in
                TaskItem(
                    id: task.id,
                    title: task.title,
                    isDone: isRecurringTaskDone(task, on: date),
                    recurrenceLabel: task.rule.displayLabel,
                    source: .recurring(id: task.id)
                )
            }

        return oneTimeTasks + recurringItems
    }

    func addTask(title: String, for date: Date, recurrence: RecurrenceRule) {
        if recurrence.kind == .none {
            addOneTimeTask(title: title, for: date)
        } else {
            let recurringTask = RecurringTask(title: title, startDate: date, rule: recurrence)
            recurringTasks.append(recurringTask)
            saveRecurringTasks()
        }
    }

    func updateTask(item: TaskItem, newTitle: String, recurrence: RecurrenceRule, for date: Date) {
        switch item.source {
        case .single(let dateKey):
            if recurrence.kind == .none {
                updateOneTimeTask(id: item.id, title: newTitle, dateKey: dateKey)
            } else {
                deleteOneTimeTask(id: item.id, dateKey: dateKey)
                let recurringTask = RecurringTask(title: newTitle, startDate: date, rule: recurrence)
                recurringTasks.append(recurringTask)
                saveRecurringTasks()
                saveTasks()
            }
        case .recurring(let taskId):
            if recurrence.kind == .none {
                deleteRecurringTask(taskId: taskId)
                addOneTimeTask(title: newTitle, for: date)
            } else {
                updateRecurringTask(taskId: taskId, title: newTitle, recurrence: recurrence)
            }
        }
    }

    func toggleTask(_ item: TaskItem, for date: Date) {
        switch item.source {
        case .single(let dateKey):
            toggleOneTimeTask(id: item.id, dateKey: dateKey)
        case .recurring(let taskId):
            toggleRecurringTaskDone(taskId: taskId, for: date)
        }
    }

    func deleteTask(item: TaskItem, for date: Date) {
        switch item.source {
        case .single(let dateKey):
            deleteOneTimeTask(id: item.id, dateKey: dateKey)
        case .recurring(let taskId):
            deleteRecurringTask(taskId: taskId)
        }
    }

    func recurrenceRule(for item: TaskItem) -> RecurrenceRule {
        switch item.source {
        case .single:
            return .none
        case .recurring(let taskId):
            return recurringTasks.first(where: { $0.id == taskId })?.rule ?? .none
        }
    }

    private func addOneTimeTask(title: String, for date: Date) {
        let key = dateString(for: date)
        var tasks = tasksByDate[key] ?? []
        tasks.append(Task(title: title))
        tasksByDate[key] = tasks
        saveTasks()
    }

    private func updateOneTimeTask(id: UUID, title: String, dateKey: String) {
        guard var tasks = tasksByDate[dateKey] else { return }
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].title = title
            tasksByDate[dateKey] = tasks
            saveTasks()
        }
    }

    private func deleteOneTimeTask(id: UUID, dateKey: String) {
        guard var tasks = tasksByDate[dateKey] else { return }
        tasks.removeAll { $0.id == id }
        tasksByDate[dateKey] = tasks
        saveTasks()
    }

    private func toggleOneTimeTask(id: UUID, dateKey: String) {
        guard var tasks = tasksByDate[dateKey] else { return }
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isDone.toggle()
            tasksByDate[dateKey] = tasks
            saveTasks()
        }
    }

    private func updateRecurringTask(taskId: UUID, title: String, recurrence: RecurrenceRule) {
        if let index = recurringTasks.firstIndex(where: { $0.id == taskId }) {
            recurringTasks[index].title = title
            recurringTasks[index].rule = recurrence
            saveRecurringTasks()
        }
    }

    private func deleteRecurringTask(taskId: UUID) {
        recurringTasks.removeAll { $0.id == taskId }
        for (key, ids) in recurringCompletionByDate {
            recurringCompletionByDate[key] = ids.filter { $0 != taskId }
        }
        saveRecurringTasks()
        saveRecurringCompletion()
    }

    private func toggleRecurringTaskDone(taskId: UUID, for date: Date) {
        let key = dateString(for: date)
        var completedIds = recurringCompletionByDate[key] ?? []
        if let index = completedIds.firstIndex(of: taskId) {
            completedIds.remove(at: index)
        } else {
            completedIds.append(taskId)
        }
        recurringCompletionByDate[key] = completedIds
        saveRecurringCompletion()
    }

    private func isRecurringTaskDone(_ task: RecurringTask, on date: Date) -> Bool {
        let key = dateString(for: date)
        return recurringCompletionByDate[key]?.contains(task.id) ?? false
    }

    private func isRecurringTask(_ task: RecurringTask, on date: Date) -> Bool {
        guard let interval = task.rule.resolvedIntervalDays else { return false }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: task.startDate)
        let targetDay = calendar.startOfDay(for: date)
        let daysBetween = calendar.dateComponents([.day], from: startDay, to: targetDay).day ?? 0
        guard daysBetween >= 0 else { return false }
        return daysBetween % interval == 0
    }

    // MARK: - Persistence

    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasksByDate) {
            UserDefaults.standard.set(encoded, forKey: tasksByDateKey)
        }
    }

    private func saveRecurringTasks() {
        if let encoded = try? JSONEncoder().encode(recurringTasks) {
            UserDefaults.standard.set(encoded, forKey: recurringTasksKey)
        }
    }

    private func saveRecurringCompletion() {
        if let encoded = try? JSONEncoder().encode(recurringCompletionByDate) {
            UserDefaults.standard.set(encoded, forKey: recurringCompletionKey)
        }
    }
    
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksByDateKey),
           let decoded = try? JSONDecoder().decode([String: [Task]].self, from: data) {
            tasksByDate = decoded
        } else {
            // First launch: pre-filled daily tasks for today
            let todayKey = dateString(for: Date())
            tasksByDate[todayKey] = [
                Task(title: "Drink a glass of water"),
                Task(title: "Stretch for 5 minutes"),
                Task(title: "Take a deep breath"),
                Task(title: "Check your schedule"),
                Task(title: "Write down one thought"),
                Task(title: "Walk for a few minutes"),
                Task(title: "Avoid doom-scrolling"),
                Task(title: "Smile at someone / Be kind"),
                Task(title: "Focus for 25 minutes on one task"),
                Task(title: "Go to bed on time"),
            ]
            saveTasks()
        }

        if let data = UserDefaults.standard.data(forKey: recurringTasksKey),
           let decoded = try? JSONDecoder().decode([RecurringTask].self, from: data) {
            recurringTasks = decoded
        }

        if let data = UserDefaults.standard.data(forKey: recurringCompletionKey),
           let decoded = try? JSONDecoder().decode([String: [UUID]].self, from: data) {
            recurringCompletionByDate = decoded
        }
    }
}
