import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var emoji: String

    @Relationship(deleteRule: .deny, inverse: \Expense.category)
    var expenses: [Expense] = []

    init(id: UUID = UUID(), name: String, emoji: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
    }
}
