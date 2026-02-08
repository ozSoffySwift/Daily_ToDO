//
//  TaskSectionView.swift
//  DailyToDo
//
//  Task row and input components.
//
import SwiftUI

struct TaskRowView: View {
    let task: TodoTask
    let onToggleComplete: () -> Void
    let onToggleSticky: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(task.isCompleted ? .black.opacity(0.4) : .black)
                    .strikethrough(task.isCompleted, color: .black.opacity(0.35))

                if task.isSticky {
                    Text("STICKY")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.black.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? .black : .black.opacity(0.4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark not done" : "Mark done")
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(task.isCompleted ? "Mark Not Done" : "Mark Done") {
                onToggleComplete()
            }
            Button(task.isSticky ? "Unstick" : "Make Sticky") {
                onToggleSticky()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(task.isCompleted ? "Mark Not Done" : "Mark Done") {
                onToggleComplete()
            }
            .tint(.black)

            Button(task.isSticky ? "Unstick" : "Make Sticky") {
                onToggleSticky()
            }
            .tint(.gray)
        }
    }
}

struct TaskInputView: View {
    @Binding var title: String
    let onAddOneTime: () -> Void
    let onAddSticky: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("New task", text: $title)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(.black)

            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                HStack(spacing: 12) {
                    Button(action: onAddOneTime) {
                        Text("One-time task")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.08))
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }

                    Button(action: onAddSticky) {
                        Text("Sticky task (until marked done)")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.08))
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

