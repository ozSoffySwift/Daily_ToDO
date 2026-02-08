//
//  ContentView.swift
//  DailyToDo
//
//  Root preview wrapper for the main DailyView.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DailyView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TodoTask.self, inMemory: true)
}
