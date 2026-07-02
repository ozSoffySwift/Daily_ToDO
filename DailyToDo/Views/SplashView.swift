//
//  SplashView.swift
//  DailyToDo
//
//  Animated launch splash: the signature progress ring draws itself in,
//  then the app name fades in below it.
//
import SwiftUI

/// The brief animated screen shown while the app launches: the progress ring
/// traces itself, then "Daily 2do" fades in beneath it.
struct SplashView: View {
    /// How much of the ring is currently drawn, animated from 0 to 1 on appear.
    @State private var ringProgress: CGFloat = 0
    /// Whether the app name has faded in yet.
    @State private var showName = false

    /// The ring's diameter.
    private let ringDiameter: CGFloat = 64

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    // The full, dim background track the drawing arc sits on top of.
                    Circle()
                        .stroke(Color.accentColor.opacity(0.15), lineWidth: 6)

                    // The arc that traces itself in from 0 to fully drawn.
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: ringDiameter, height: ringDiameter)

                // The app name, fading and sliding in once the ring has mostly drawn.
                Text(AppInfo.appName)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.warmPrimaryText)
                    .opacity(showName ? 1 : 0)
                    .offset(y: showName ? 0 : 6)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) {
                ringProgress = 1
            }
            // The name starts fading in slightly before the ring finishes drawing,
            // so the two animations feel connected rather than strictly sequential.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showName = true
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
