import SwiftUI

struct MainView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    @State private var isAddingTask = false
    @State private var newTaskTitle = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var selectedDate = Date()
    @State private var showSideMenu = false

    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: selectedDate)
    }

    var tasksForSelectedDate: [Task] {
        taskManager.tasksByDate[formattedSelectedDate] ?? []
    }

    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    List {
                        ForEach(tasksForSelectedDate) { task in
                            Toggle(isOn: Binding(
                                get: { task.isDone },
                                set: { newValue in
                                    taskManager.toggleTask(task, for: selectedDate)
                                }
                            )) {
                                Text(task.title)
                            }
                        }
                        .onDelete { offsets in
                            taskManager.deleteTask(at: offsets, for: selectedDate)
                        }

                        Section {
                            if isAddingTask {
                                HStack {
                                    TextField("New task", text: $newTaskTitle, onCommit: addNewTask)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .focused($isTextFieldFocused)

                                    Button(action: addNewTask) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .onAppear {
                                    isTextFieldFocused = true
                                }
                            } else {
                                Button {
                                    withAnimation {
                                        isAddingTask = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Add Task")
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    // 🠔🠖 Arrow Buttons Below List
                    HStack {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.largeTitle)
                        }

                        Spacer()

                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.largeTitle)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                .navigationTitle("Today: \(formattedSelectedDate)")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation {
                                showSideMenu = true
                            }
                        } label: {
                            Image(systemName: "line.horizontal.3")
                        }
                    }
                }
            }

            // Side Menu & Dim Background
            if showSideMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showSideMenu = false
                        }
                    }

                SideMenuView(onMenuItemTap: { item in
                    print("Tapped on: \(item)")
                    withAnimation {
                        showSideMenu = false
                    }
                })
                .frame(width: UIScreen.main.bounds.width * 0.75)
                .background(Color(.systemBackground))
                .transition(.move(edge: .leading))
                .zIndex(1)
            }
        }
    }

    private func addNewTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        taskManager.addTask(title: trimmedTitle, for: selectedDate)
        newTaskTitle = ""
        isAddingTask = false
    }
}
