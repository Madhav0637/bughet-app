import SwiftData

/// The single on-device store, shared by the app's screens and the Log Expense intent.
enum AppDatabase {
    static let shared: ModelContainer = {
        do {
            let container = try ModelContainer(for: Expense.self, Category.self)
            // Seeding here (not in the UI) means the Shortcut works even if the app was never opened.
            try CategoryService(context: container.mainContext).seedDefaultsIfNeeded()
            return container
        } catch {
            fatalError("Could not open the database: \(error)")
        }
    }()
}
