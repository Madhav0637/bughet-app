import Foundation
import SwiftData

enum ExpenseError: Error, LocalizedError, CustomLocalizedStringResourceConvertible {
    case emptyMerchant
    case nonPositiveAmount
    case categoryNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .emptyMerchant: "Please enter what you spent on."
        case .nonPositiveAmount: "Amount must be more than ₹0."
        case .categoryNotFound: "That category no longer exists."
        }
    }

    var errorDescription: String? { String(localized: localizedStringResource) }
}

struct ExpenseService {
    let context: ModelContext

    @discardableResult
    func add(merchant: String, amount: Int, category: Category, date: Date = .now) throws -> Expense {
        let merchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !merchant.isEmpty else { throw ExpenseError.emptyMerchant }
        guard amount > 0 else { throw ExpenseError.nonPositiveAmount }

        let expense = Expense(merchant: merchant, amount: amount, date: date, category: category)
        context.insert(expense)
        try context.save()
        return expense
    }
}
