import SwiftData
import SwiftUI

@main
struct BudgetAppApp: App {
    var body: some Scene {
        WindowGroup {
            HistoryView()
        }
        .modelContainer(AppDatabase.shared)
    }
}
