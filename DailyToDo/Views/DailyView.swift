//
//  DailyView.swift
//  DailyToDo
//
//  Main daily task view.
//
import SwiftUI
import SwiftData
import UIKit //love is love
import UserNotifications

/// The app's main screen: the selected day's habits and tasks, day navigation,
/// and the hamburger menu leading to Calendar/Archive/About.
struct DailyView: View {
    /// The screens reachable from the hamburger menu via `navigationPath`.
    enum Destination: Hashable {
        /// The list of all completed tasks.
        case archive
        /// The app info / credits screen.
        case about
    }

    /// The SwiftData context used to bind the view model to persistent storage.
    @Environment(\.modelContext) private var modelContext
    /// The app's current foreground/background/inactive state, used to refresh on return to foreground.
    @Environment(\.scenePhase) private var scenePhase
    /// Owns all the data and actions this view displays and triggers.
    @StateObject private var viewModel = DailyTaskViewModel()
    /// The current navigation stack, driving pushes to Archive/About.
    @State private var navigationPath: [Destination] = []
    /// Whether the inline "add task" card is expanded below the header.
    @State private var showInlineAddTask = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 16) {
                topBar

                // The inline add-task card only exists in the hierarchy while expanded, so its
                // fields reset automatically each time it's reopened. Its own internal
                // "Options" expansion pushes everything below it further down.
                if showInlineAddTask {
                    InlineAddTaskView(viewModel: viewModel)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                taskListView

                dayNavigationView
            }
            .padding(.top, 12)
            .background(Color.appBackground.ignoresSafeArea())
            // The top bar replaces the system navigation bar entirely, so hide it to reclaim space.
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.showCalendarPicker) {
                CalendarPickerSheet(
                    selectedDate: viewModel.selectedDate,
                    onSelect: { date in
                        viewModel.setSelectedDate(date)
                        viewModel.showCalendarPicker = false
                    }
                )
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .archive:
                    ArchiveView(viewModel: viewModel)
                case .about:
                    AboutView()
                }
            }
            .onAppear {
                // Binds the view model to live storage exactly once, however many times this fires.
                viewModel.bindIfNeeded(context: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                // The calendar day rolled over (e.g. past midnight) while the app was running.
                viewModel.handleSignificantTimeChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                // The system clock changed significantly (e.g. time zone travel, manual clock change).
                viewModel.handleSignificantTimeChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: .dailyToDoOpenDate)) { notification in
                // The user tapped a reminder notification; jump straight to that task's day.
                if let date = notification.userInfo?["date"] as? Date {
                    navigationPath.removeAll()
                    viewModel.setSelectedDate(date)
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Returning to the foreground is a good moment to catch up on any day change.
                if newPhase == .active {
                    viewModel.handleSignificantTimeChange()
                }
            }
        }
        .tint(Color.accentColor)
    }

    /// The single top row: add-task toggle on the leading edge, the selected date and
    /// weekday truly centered behind it, and the progress ring + hamburger menu grouped
    /// on the trailing edge — everything on one line to save vertical space.
    private var topBar: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(viewModel.selectedDate.formattedDay())
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.warmPrimaryText)

                Text(viewModel.selectedDate.formattedWeekday())
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.warmSecondaryText)
            }
            .lineLimit(1)

            HStack {
                addTaskToggleButton

                Spacer()

                // Hide the ring entirely on empty days rather than showing a meaningless 0/0.
                if viewModel.totalCount > 0 {
                    ProgressRingView(completed: viewModel.completedCount, total: viewModel.totalCount, diameter: 38)
                }

                hamburgerMenuButton
            }
        }
        .padding(.horizontal)
    }

    /// Toggles the inline add-task card open/closed.
    private var addTaskToggleButton: some View {
        Button {
            withAnimation(.easeInOut) { showInlineAddTask.toggle() }
        } label: {
            Image(systemName: showInlineAddTask ? "xmark.circle.fill" : "plus.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.accentColor)
        }
        .accessibilityLabel(showInlineAddTask ? "Close add task" : "Add task")
    }

    /// Jumps to today, opens the calendar picker, or pushes Archive/About.
    private var hamburgerMenuButton: some View {
        Menu {
            Button("Today") {
                viewModel.goToToday()
            }

            Button("Calendar") {
                viewModel.showCalendarPicker = true
            }

            Button("Archive") {
                navigationPath.append(.archive)
            }

            Button("About") {
                navigationPath.append(.about)
            }
        } label: {
            Image(systemName: "line.horizontal.3")
                .font(.system(size: 18))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.leading, 10)
    }

    /// The scrollable list of the selected day's habits (if any) and one-time/sticky tasks,
    /// rendered as individually spaced rounded cards rather than a plain system list.
    private var taskListView: some View {
        List {
            // The "Habits" section only appears when at least one recurring task is due today.
            if viewModel.recurringStatuses.isEmpty == false {
                Section {
                    ForEach(viewModel.recurringStatuses) { status in
                        RecurringTaskRowView(
                            status: status,
                            onToggleComplete: { viewModel.toggleRecurringCompletion(status.task) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    }
                } header: {
                    Text("Habits")
                        .foregroundStyle(Color.warmSecondaryText)
                }
            }

            // The section header is only shown once habits are also present, to avoid a redundant label.
            Section {
                if viewModel.tasks.isEmpty {
                    Text("No tasks for this day yet.")
                        .foregroundStyle(Color.warmSecondaryText)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.tasks) { task in
                        TaskRowView(
                            task: task,
                            onToggleComplete: { viewModel.toggleCompleted(task) },
                            onToggleSticky: { viewModel.toggleSticky(task) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            viewModel.deleteTask(viewModel.tasks[index])
                        }
                    }
                }
            } header: {
                if viewModel.recurringStatuses.isEmpty == false {
                    Text("Tasks")
                        .foregroundStyle(Color.warmSecondaryText)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    /// The previous/next day chevrons pinned to the bottom of the screen.
    private var dayNavigationView: some View {
        HStack {
            Button(action: {
                viewModel.goToPreviousDay()
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 30))
            }

            Spacer()

            Button(action: {
                viewModel.goToNextDay()
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 30))
            }
        }
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}

#Preview {
    DailyView()
        .modelContainer(for: TodoTask.self, inMemory: true)
}

// MARK: - Archive

/// Lists every completed task, most recently completed first.
struct ArchiveView: View {
    /// Supplies `archiveTasks` and reloads them on appear.
    @ObservedObject var viewModel: DailyTaskViewModel

    var body: some View {
        List {
            if viewModel.archiveTasks.isEmpty {
                Text("No completed tasks yet.")
                    .foregroundStyle(Color.warmSecondaryText)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.archiveTasks) { task in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.warmPrimaryText)

                        if let completedAt = task.completedAt {
                            Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.warmSecondaryText)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.cardSurface))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Archive")
        .onAppear {
            viewModel.refreshArchive()
        }
    }
}

// MARK: - About

/// The app info screen: name, version, developer, notification status, and social links.
struct AboutView: View {
    /// The current notification authorization status, refreshed when this view appears.
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 18) {
            Text(AppInfo.appName)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.warmPrimaryText)

            Text("Version \(AppInfo.versionString)")
                .font(.system(size: 14))
                .foregroundStyle(Color.warmSecondaryText)

            Text("Developer: \(AppInfo.developerName)")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.warmPrimaryText)

            notificationsRow

            VStack(spacing: 10) {
                Link("LinkedIn", destination: AppLinks.linkedIn)
                Link("Facebook", destination: AppLinks.facebook)
                Link("Instagram", destination: AppLinks.instagram)
                Link("Twitter (X)", destination: AppLinks.twitter)
            }
            .font(.system(size: 16, weight: .semibold))
            .tint(Color.accentColor)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("About")
        .task {
            // Refresh the live authorization status every time this screen is shown.
            await NotificationScheduler.refreshAuthorizationStatus()
            notificationStatus = NotificationScheduler.authorizationStatus
        }
    }

    /// A status row reflecting the current notification permission: enabled, denied
    /// (with a shortcut to Settings), or not yet asked.
    @ViewBuilder
    private var notificationsRow: some View {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            Label("Notifications enabled", systemImage: "bell.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.warmSecondaryText)
        case .denied:
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Notifications disabled — open Settings", systemImage: "bell.slash.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
        case .notDetermined:
            Text("Notifications will be requested when you set a reminder.")
                .font(.system(size: 14))
                .foregroundStyle(Color.warmSecondaryText)
        @unknown default:
            EmptyView()
        }
    }
}
