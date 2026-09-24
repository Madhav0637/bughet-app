import SwiftUI

/// The Settings tab: categories, the Back Tap guide, and exporting data.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        Label("Categories", systemImage: "square.grid.2x2")
                    }
                    NavigationLink {
                        BackTapGuideView()
                    } label: {
                        Label("Set Up Back Tap", systemImage: "iphone.gen3.radiowaves.left.and.right")
                    }
                }

                Section {
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                } footer: {
                    Text("Save your expenses as a CSV spreadsheet or a PDF report.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
