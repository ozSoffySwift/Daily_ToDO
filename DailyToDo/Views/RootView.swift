//
//  RootView.swift
//  DailyToDo
//
//  Composes the animated splash screen over the daily list on launch.
//
import SwiftUI

/// The app's actual root view: shows `DailyView` underneath from the very first
/// frame (so its data starts loading immediately) with `SplashView` covering it
/// until the splash animation has had time to play, then fades the splash away.
struct RootView: View {
    /// Whether the splash screen is still covering the daily list.
    @State private var showSplash = true

    var body: some View {
        ZStack {
            DailyView()

            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Give the ring-draw + name-fade animation time to finish before dismissing.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: TodoTask.self, inMemory: true)
}
