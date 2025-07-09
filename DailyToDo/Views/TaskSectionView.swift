//
//  TaskSectionView.swift
//  DailyToDo
//
//  Created by Oz Soffy on 03/07/2025.
//
import SwiftUI

// View that displays a titled section of tasks with checkboxes
struct TaskSectionView: View {
    var title: String               // Section title (e.g., "One-Time Tasks")
    var tasks: [Task]              // List of tasks to display

    @Environment(\.modelContext) private var context // SwiftData context for saving edits

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            ForEach(tasks) { task in
                HStack {
                    // Toggle for marking task as completed
                    Button(action: {
                        task.isCompleted.toggle()
                        try? context.save() // Save change
                    }) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                    }

                    Text(task.title)
                        .strikethrough(task.isCompleted) // Visually mark completed tasks
                        .foregroundColor(task.isCompleted ? .secondary : .primary)

                    Spacer()
                }
                .padding(.vertical, 4)
            }

            if tasks.isEmpty {
                Text("No tasks here yet.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}


