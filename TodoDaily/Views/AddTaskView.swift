//
//  AddTaskView.swift
//  TodoDaily
//
//  Created by Oz Soffy on 29/04/2025.
//

import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var taskManager: TaskManager
    @State private var taskTitle = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Task")) {
                    TextField("Enter task...", text: $taskTitle)
                }

                Section {
                    Button("Add Task") {
                        taskManager.addTask(title: taskTitle, for: Date())
                        dismiss()
                    }
                    .disabled(taskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
