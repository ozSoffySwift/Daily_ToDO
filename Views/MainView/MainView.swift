import SwiftUI

struct MainView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var selectedDate = Date()
    @State private var showSideMenu = false
    @State private var showingEditor = false
    @State private var editingItem: TaskItem?

    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    private var weekdaySelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var taskItemsForSelectedDate: [TaskItem] {
        taskManager.taskItems(for: selectedDate)
    }

    var body: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedSelectedDate)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        Text(isToday ? "Today • \(weekdaySelectedDate)" : weekdaySelectedDate)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    List {
                        ForEach(taskItemsForSelectedDate) { item in
                            HStack(spacing: 12) {
                                Button {
                                    taskManager.toggleTask(item, for: selectedDate)
                                } label: {
                                    Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isDone ? .green : .secondary)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(item.isDone ? .secondary : .primary)
                                        .strikethrough(item.isDone, color: .secondary)

                                    if let recurrenceLabel = item.recurrenceLabel {
                                        Text(recurrenceLabel.uppercased())
                                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.orange.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    taskManager.deleteTask(item: item, for: selectedDate)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    editingItem = item
                                    showingEditor = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    HStack {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        Button {
                            showingEditor = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Task")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.yellow.opacity(0.18))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                        }

                        Spacer()

                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                .background(Color(.systemGroupedBackground))
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
            .sheet(isPresented: $showingEditor, onDismiss: { editingItem = nil }) {
                TaskEditorView(
                    taskManager: taskManager,
                    date: selectedDate,
                    existingItem: editingItem
                )
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
}
