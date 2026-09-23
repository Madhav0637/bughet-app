import Foundation
import SwiftData

@Model
final class Expense {
    #Index<Expense>([\.date])

    var id: UUID
    var merchant: String
    /// Whole rupees.
    var amount: Int
    var date: Date
    /// Optional only because SwiftData handles optional relationships more reliably;
    /// ExpenseService guarantees every saved expense has a category.
    var category: Category?

    init(id: UUID = UUID(), merchant: String, amount: Int, date: Date = .now, category: Category) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.date = date
        self.category = category
    }
}
