//
//  MonthlyView.swift
//  DailyToDo
//
//  Calendar picker sheet for jumping to any date.
//

import SwiftUI

/// A sheet with a calendar grid for jumping the daily view to any date.
struct CalendarPickerSheet: View {
    /// The date to preselect when the calendar first appears.
    let selectedDate: Date
    /// Called with the chosen date when the user taps "Go to date".
    let onSelect: (Date) -> Void

    /// Dismisses this sheet.
    @Environment(\.dismiss) private var dismiss
    /// The date currently highlighted in the calendar grid, before it's confirmed.
    @State private var draftDate: Date

    /// Creates the sheet, seeding the draft selection from the caller's current date.
    init(selectedDate: Date, onSelect: @escaping (Date) -> Void) {
        self.selectedDate = selectedDate
        self.onSelect = onSelect
        _draftDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Select date",
                    selection: $draftDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.accentColor)
                .padding()

                Button("Go to date") {
                    onSelect(draftDate)
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.12))
                .foregroundStyle(Color.accentColor)
                .clipShape(Capsule())

                Spacer()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
