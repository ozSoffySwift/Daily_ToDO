//
//  DailyView.swift
//  DailyToDo
//
//  Main daily task view.
//
import SwiftUI
import SwiftData
import UIKit //love is love

struct DailyView: View {
    enum Destination: Hashable {
        case archive
        case about
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = DailyTaskViewModel()
    @State private var navigationPath: [Destination] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 16) {
                headerView

                taskListView

                TaskInputView(
                    title: $viewModel.newTaskTitle,
                    onAddOneTime: { viewModel.addTask(isSticky: false) },
                    onAddSticky: { viewModel.addTask(isSticky: true) }
                )
                .padding(.horizontal)

                dayNavigationView
            }
            .padding(.top, 12)
            .background(Color.white.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Today") {
                            viewModel.goToToday()
                        }
                        Button("Today2") {
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
                            .foregroundColor(.black)
                    }
                }
            }
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
                viewModel.bindIfNeeded(context: modelContext)
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                viewModel.handleSignificantTimeChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                viewModel.handleSignificantTimeChange()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    viewModel.handleSignificantTimeChange()
                }
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.selectedDate.formattedDay())
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.black)

            Text(viewModel.selectedDate.formattedWeekday())
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var taskListView: some View {
        List {
            ForEach(viewModel.tasks) { task in
                TaskRowView(
                    task: task,
                    onToggleComplete: { viewModel.toggleCompleted(task) },
                    onToggleSticky: { viewModel.toggleSticky(task) }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.white)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var dayNavigationView: some View {
        HStack {
            Button(action: {
                viewModel.goToPreviousDay()
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.black)
            }

            Spacer()

            Button(action: {
                viewModel.goToNextDay()
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}

#Preview {
    DailyView()
        .modelContainer(for: TodoTask.self, inMemory: true)
}

// MARK: - Archive

struct ArchiveView: View {
    @ObservedObject var viewModel: DailyTaskViewModel

    var body: some View {
        List {
            if viewModel.archiveTasks.isEmpty {
                Text("No completed tasks yet.")
                    .foregroundColor(.black.opacity(0.6))
                    .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.archiveTasks) { task in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)

                        if let completedAt = task.completedAt {
                            Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.system(size: 12))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.white)
        .navigationTitle("Archive")
        .onAppear {
            viewModel.refreshArchive()
        }
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        VStack(spacing: 18) {
            Text(AppInfo.appName)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(.black)

            Text("Version \(AppInfo.versionString)")
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.6))

            Text("Developer: \(AppInfo.developerName)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)

            VStack(spacing: 10) {
                Link("LinkedIn", destination: AppLinks.linkedIn)
                Link("Facebook", destination: AppLinks.facebook)
                Link("Instagram", destination: AppLinks.instagram)
                Link("Twitter (X)", destination: AppLinks.twitter)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)

            Spacer()
        }
        .padding()
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("About")
    }
}
