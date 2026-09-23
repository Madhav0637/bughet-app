import AppIntents
import Foundation
import SwiftData

/// A lightweight copy of a Category that the Shortcuts system can list and pass around.
struct CategoryEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static let defaultQuery = CategoryQuery()

    let id: UUID
    let name: String
    let emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }

    init(_ category: Category) {
        id = category.id
        name = category.name
        emoji = category.emoji
    }
}

struct CategoryQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [CategoryEntity] {
        try CategoryService(context: AppDatabase.shared.mainContext)
            .categoriesByUsage()
            .filter { identifiers.contains($0.id) }
            .map(CategoryEntity.init)
    }

    /// The list shown when the Shortcut asks for a category.
    @MainActor
    func suggestedEntities() async throws -> [CategoryEntity] {
        try CategoryService(context: AppDatabase.shared.mainContext)
            .categoriesByUsage()
            .map(CategoryEntity.init)
    }
}
