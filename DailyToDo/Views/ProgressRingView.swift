//
//  ProgressRingView.swift
//  DailyToDo
//
//  Small animated ring showing today's completed/total task count.
//
import SwiftUI

/// A small animated ring showing "N of M done" for the currently selected day.
struct ProgressRingView: View {
    /// Number of tasks/habits completed on the selected day.
    let completed: Int
    /// Total number of tasks/habits visible on the selected day.
    let total: Int
    /// The ring's diameter in points, so it can shrink to fit compact spots like the top bar.
    var diameter: CGFloat = 52

    /// The completion fraction (0...1) the ring should be trimmed to. Zero when there's nothing to show.
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    /// The stroke width and text sizes scale down together with `diameter` so smaller
    /// rings (e.g. in the top bar) stay legible instead of just shrinking proportionally.
    private var scale: CGFloat { diameter / 52 }

    var body: some View {
        ZStack {
            // The full, dim background track the progress arc sits on top of.
            Circle()
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 6 * scale)

            // The colored arc, trimmed to the current progress fraction and animated on change.
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6 * scale, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)

            // The "completed/total" text centered inside the ring.
            VStack(spacing: 0) {
                Text("\(completed)")
                    .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.warmPrimaryText)
                Text("/\(total)")
                    .font(.system(size: 11 * scale, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.warmSecondaryText)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(completed) of \(total) tasks completed today")
    }
}

#Preview {
    VStack(spacing: 16) {
        ProgressRingView(completed: 3, total: 8)
        ProgressRingView(completed: 3, total: 8, diameter: 34)
    }
}
