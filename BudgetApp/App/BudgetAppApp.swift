import SwiftData
import SwiftUI

@main
struct BudgetAppApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(AppDatabase.shared)
    }
}
