//
//  DailyView.swift
//  DailyToDo
//
//  Created by Oz Soffy on 03/07/2025.
//
import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var context // Access to SwiftData context
    @Query private var tasks: [Task] // Automatically fetches Task objects
    @Query private var reflections: [DailyReflection] // Fetch reflections
    
    @State private var selectedDate: Date = .now // Date currently being viewed
    @State private var newNoteText: String = "" // Text for daily reflection
    
    @State private var newTaskTitle: String = ""    // Holds the new task input
    @State private var isRecurring: Bool = false    // Tracks whether task repeats


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Date Display
                    Text(formattedDate(selectedDate))
                        .font(.largeTitle)
                        .bold()

                    // MARK: One-Time Tasks
                    TaskSectionView(
                        title: "One-Time Tasks",
                        tasks: tasks.filter { !$0.isRecurring && isSameDay($0.date, selectedDate) }
                    )

                    // MARK: Recurring Tasks
                    TaskSectionView(
                        title: "Recurring Tasks",
                        tasks: tasks.filter { $0.isRecurring }
                    )

                    // MARK: Reflection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reflection")
                            .font(.headline)

                        TextEditor(text: $newNoteText)
                            .frame(height: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))

                        Button("Save Reflection") {
                            let reflection = DailyReflection(date: selectedDate, notes: newNoteText)
                            context.insert(reflection)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("Daily ToDo")
            .padding()
            .padding()
            
            // MARK: Add New Task Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Add New Task")
                    .font(.headline)

                // Task title input
                TextField("What do you want to do?", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)

                // Recurring toggle
                Toggle("Is this a recurring task?", isOn: $isRecurring)

                // Save button
                Button("Add Task") {
                    let newTask = Task(
                        title: newTaskTitle,
                        isRecurring: isRecurring,
                        date: selectedDate
                    )
                    context.insert(newTask)         // Save task to SwiftData
                    try? context.save()             // Commit changes
                    newTaskTitle = ""               // Reset input
                    isRecurring = false             // Reset toggle
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTaskTitle.isEmpty)     // Prevent empty task entry
            }
            .padding(.vertical)

        }
    }

    // Helper: Check if task date matches selected date
    private func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }

    // Helper: Format date nicely
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

#Preview {
    DailyView() // Replace with the appropriate view
}

// just adding a comment for fun

