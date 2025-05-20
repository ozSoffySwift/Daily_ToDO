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

    private let tasksByDateKey = "tasksByDate"

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

    func addTask(title: String, for date: Date) {
        let key = dateString(for: date)
        var tasks = tasksByDate[key] ?? []
        tasks.append(Task(title: title))
        tasksByDate[key] = tasks
        saveTasks()
    }

    func toggleTask(_ task: Task, for date: Date) {
        let key = dateString(for: date)
        guard var tasks = tasksByDate[key] else { return }
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isDone.toggle()
            tasksByDate[key] = tasks
            saveTasks()
        }
    }

    func deleteTask(at offsets: IndexSet, for date: Date) {
        let key = dateString(for: date)
        guard var tasks = tasksByDate[key] else { return }
        tasks.remove(atOffsets: offsets)
        tasksByDate[key]?.remove(atOffsets: offsets)
        saveTasks()
    }

    // MARK: - Persistence

    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasksByDate) {
            UserDefaults.standard.set(encoded, forKey: tasksByDateKey)
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
    }
}

