import SwiftUI

/// The Settings tab. CSV export and the Back Tap guide join in Milestone 6.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    CategoriesView()
                } label: {
                    Label("Categories", systemImage: "square.grid.2x2")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
