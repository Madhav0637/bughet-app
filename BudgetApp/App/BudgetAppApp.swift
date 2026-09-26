import SwiftData
import SwiftUI

@main
struct BudgetAppApp: App {
    init() {
        WindowTheme.configureNavigationBars()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(AppDatabase.shared)
    }
}
