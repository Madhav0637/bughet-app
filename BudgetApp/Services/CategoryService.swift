import Foundation
import SwiftData

struct CategoryService {
    let context: ModelContext

    static let defaults: [(emoji: String, name: String)] = [
        ("🍔", "Food"),
        ("🚕", "Transport"),
        ("🛍️", "Shopping"),
        ("🧾", "Bills"),
        ("🎬", "Entertainment"),
        ("💊", "Health"),
        ("📦", "Other"),
    ]

    func seedDefaultsIfNeeded() throws {
        guard try context.fetchCount(FetchDescriptor<Category>()) == 0 else { return }
        for item in Self.defaults {
            context.insert(Category(name: item.name, emoji: item.emoji))
        }
        try context.save()
    }

    /// Most-used first; ties sorted alphabetically.
    func categoriesByUsage() throws -> [Category] {
        try context.fetch(FetchDescriptor<Category>()).sorted { lhs, rhs in
            if lhs.expenses.count != rhs.expenses.count {
                return lhs.expenses.count > rhs.expenses.count
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func category(withID id: UUID) throws -> Category? {
        var descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
