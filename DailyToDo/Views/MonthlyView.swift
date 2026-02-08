//
//  MonthlyView.swift
//  DailyToDo
//
//  Calendar picker sheet for jumping to any date.
//

import SwiftUI

struct CalendarPickerSheet: View {
    let selectedDate: Date
    let onSelect: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftDate: Date

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
                .tint(.black)
                .padding()

                Button("Go to date") {
                    onSelect(draftDate)
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.08))
                .foregroundColor(.black)
                .clipShape(Capsule())

                Spacer()
            }
            .background(Color.white)
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
