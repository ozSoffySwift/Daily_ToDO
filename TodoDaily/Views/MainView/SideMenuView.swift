//
//  SideMenuView.swift
//  TodoDaily
//
//  Created by Oz Soffy on 13/05/2025.
//

import SwiftUI

struct SideMenuView: View {
    var onMenuItemTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Add some top padding to align with the navigation bar
            Spacer().frame(height: 60)

            Button(action: { onMenuItemTap("Today") }) {
                Label("Today", systemImage: "sun.max.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            Button(action: { onMenuItemTap("Calendar") }) {
                Label("Calendar", systemImage: "calendar")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            Button(action: { onMenuItemTap("Archive") }) {
                Label("Archive", systemImage: "archivebox.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}
