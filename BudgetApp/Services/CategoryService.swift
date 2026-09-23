import Foundation
import SwiftData

enum CategoryError: Error, Equatable, LocalizedError {
    case emptyName
    case duplicateName
    case invalidEmoji
    case inUse(expenseCount: Int)
    case lastCategory
    case sameCategory

    var errorDescription: String? {
        switch self {
        case .emptyName: "Please enter a name."
        case .duplicateName: "A category with that name already exists."
        case .invalidEmoji: "Please choose one emoji."
        case .inUse(let count):
            "Used by \(count) \(count == 1 ? "expense" : "expenses"). Move them to another category first."
        case .lastCategory: "You need at least one category."
        case .sameCategory: "Choose a different category to move the expenses to."
        }
    }
}

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
        Self.sortedByUsage(try context.fetch(FetchDescriptor<Category>()))
    }

    /// Most-used first; ties sorted alphabetically. Shared with screens that get categories from a query.
    static func sortedByUsage(_ categories: [Category]) -> [Category] {
        categories.sorted { lhs, rhs in
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

    @discardableResult
    func add(name: String, emoji: String) throws -> Category {
        let name = try validated(name: name, emoji: emoji, excluding: nil)
        let category = Category(name: name, emoji: emoji)
        context.insert(category)
        try context.save()
        return category
    }

    func update(_ category: Category, name: String, emoji: String) throws {
        let name = try validated(name: name, emoji: emoji, excluding: category)
        category.name = name
        category.emoji = emoji
        try context.save()
    }

    func moveAllExpenses(from source: Category, to destination: Category) throws {
        guard source.id != destination.id else { throw CategoryError.sameCategory }
        for expense in source.expenses {
            expense.category = destination
        }
        try context.save()
    }

    /// Only empty categories can be deleted, and never the last one.
    func delete(_ category: Category) throws {
        guard category.expenses.isEmpty else {
            throw CategoryError.inUse(expenseCount: category.expenses.count)
        }
        guard try context.fetchCount(FetchDescriptor<Category>()) > 1 else {
            throw CategoryError.lastCategory
        }
        context.delete(category)
        try context.save()
    }

    /// True for exactly one emoji, including ones built from several characters like 🧑🏽‍🍳 or ❤️.
    static func isValidEmoji(_ text: String) -> Bool {
        guard text.count == 1, let character = text.first else { return false }
        let scalars = character.unicodeScalars
        // Digits and # also count as "emoji" in Unicode, so require emoji-style presentation.
        return scalars.contains { $0.properties.isEmojiPresentation }
            || (scalars.first?.properties.isEmoji == true && scalars.contains { $0.value == 0xFE0F })
    }

    /// Returns the trimmed name, or throws if the name or emoji isn't allowed.
    private func validated(name: String, emoji: String, excluding current: Category?) throws -> String {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw CategoryError.emptyName }
        guard Self.isValidEmoji(emoji) else { throw CategoryError.invalidEmoji }
        let others = try context.fetch(FetchDescriptor<Category>()).filter { $0.id != current?.id }
        guard !others.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            throw CategoryError.duplicateName
        }
        return name
    }
}
