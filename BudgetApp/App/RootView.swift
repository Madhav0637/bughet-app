import SwiftUI

/// The app's tabs, plus the theme and the shared toast banner.
struct RootView: View {
    enum AppTab: String { case home, activity, insights, settings }

    @State private var selection = RootView.initialTab
    @State private var toasts = ToastCenter()
    @AppStorage(SettingsKey.appearance) private var appearance = Appearance.system
    @AppStorage(SettingsKey.highlight) private var highlight = Highlight.mint

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView { selection = $0 }
            }
            Tab("Activity", systemImage: "list.bullet.rectangle.portrait", value: .activity) {
                ActivityView()
            }
            Tab("Insights", systemImage: "chart.bar.xaxis", value: .insights) {
                InsightsView()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(toasts)
        .kokuTheme()
        .onAppear { WindowTheme.apply(appearance, highlight: highlight, animated: false) }
        .onChange(of: appearance) { WindowTheme.apply(appearance, highlight: highlight, animated: true) }
        .onChange(of: highlight) { WindowTheme.apply(appearance, highlight: highlight, animated: false) }
    }

    private static var initialTab: AppTab {
        #if DEBUG
        // For screenshots: launch with `-startTab insights`.
        if let name = UserDefaults.standard.string(forKey: "startTab"), let tab = AppTab(rawValue: name) { return tab }
        #endif
        return .home
    }
}
