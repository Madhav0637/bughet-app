import SwiftUI

/// The app's tabs. Settings joins in Milestone 5.
struct RootView: View {
    enum AppTab { case dashboard, history }

    @State private var selection = AppTab.dashboard

    var body: some View {
        TabView(selection: $selection) {
            Tab("Dashboard", systemImage: "indianrupeesign.circle", value: .dashboard) {
                DashboardView { selection = .history }
            }
            Tab("History", systemImage: "list.bullet", value: .history) {
                HistoryView()
            }
        }
    }
}
