//
//  TaskSectionView.swift
//  DailyToDo
//
//  Row components for one-time/sticky tasks and recurring habits, styled as
//  warm rounded "cards" per the soft pastel wellness theme.
//
import SwiftUI

/// A single row in the "Tasks" section, for a one-time or sticky `TodoTask`.
struct TaskRowView: View {
    /// The task this row displays.
    let task: TodoTask
    /// Called when the user taps the checkmark, or the "Mark Done"/"Mark Not Done" action.
    let onToggleComplete: () -> Void
    /// Called when the user taps "Make Sticky"/"Unstick".
    let onToggleSticky: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                // Completed tasks are grayed out (a true desaturated gray, not a warm palette
                // color) so it's immediately clear at a glance which items are done.
                Text(task.title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(task.isCompleted ? Color.completedText : Color.warmPrimaryText)
                    .strikethrough(task.isCompleted, color: Color.completedText)

                HStack(spacing: 6) {
                    // A small "STICKY" badge, shown only for tasks that carry over day to day.
                    if task.isSticky {
                        Label("STICKY", systemImage: "pin.fill")
                            .labelStyle(.titleOnly)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.warmSecondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    // A bell + time, shown only when this task has a reminder configured.
                    if task.hasReminder, let hour = task.reminderHour, let minute = task.reminderMinute {
                        Label(timeString(hour: hour, minute: minute), systemImage: "bell.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.warmSecondaryText)
                    }
                }
            }

            Spacer()

            // Tappable completion checkmark.
            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isCompleted ? Color.accentColor : Color.accentColor.opacity(0.4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark not done" : "Mark done")
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cardSurface))
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
            .tint(.accentColor)

            Button(task.isSticky ? "Unstick" : "Make Sticky") {
                onToggleSticky()
            }
            .tint(Color.warmSecondaryText)
        }
    }

    /// Formats an hour/minute pair as a locale-aware short time string, e.g. "5:30 PM".
    private func timeString(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

/// A single row in the "Habits" section, for a recurring task on the currently selected day.
struct RecurringTaskRowView: View {
    /// The recurring task and its completion state for the day being shown.
    let status: RecurringTaskStatus
    /// Called when the user taps the checkmark, or the "Mark Done"/"Mark Not Done" action.
    let onToggleComplete: () -> Void

    /// Convenience accessor for the underlying recurring task.
    private var task: RecurringTask { status.task }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                // Completed habits are grayed out (a true desaturated gray, not a warm palette
                // color) so it's immediately clear at a glance which items are done.
                Text(task.title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(status.isCompleted ? Color.completedText : Color.warmPrimaryText)
                    .strikethrough(status.isCompleted, color: Color.completedText)

                HStack(spacing: 6) {
                    // A short human-readable recurrence summary, e.g. "Every Mon, Wed, Fri".
                    Label(task.rule.summary, systemImage: "repeat")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.warmSecondaryText)

                    // A bell + time, shown only when this habit has a reminder configured.
                    if task.hasReminder, let hour = task.reminderHour, let minute = task.reminderMinute {
                        Label(timeString(hour: hour, minute: minute), systemImage: "bell.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.warmSecondaryText)
                    }
                }
            }

            Spacer()

            // Tappable completion checkmark, reflecting completion for the selected day only.
            Button(action: onToggleComplete) {
                Image(systemName: status.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(status.isCompleted ? Color.accentColor : Color.accentColor.opacity(0.4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(status.isCompleted ? "Mark not done" : "Mark done")
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cardSurface))
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(status.isCompleted ? "Mark Not Done" : "Mark Done") {
                onToggleComplete()
            }
            .tint(.accentColor)
        }
    }

    /// Formats an hour/minute pair as a locale-aware short time string, e.g. "5:30 PM".
    private func timeString(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
