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
        let merchant = try validated(merchant: merchant, amount: amount)
        let expense = Expense(merchant: merchant, amount: amount, date: date, category: category)
        context.insert(expense)
        try context.save()
        return expense
    }

    /// Validates everything first, so an invalid edit leaves the expense untouched.
    func update(_ expense: Expense, merchant: String, amount: Int, category: Category, date: Date) throws {
        let merchant = try validated(merchant: merchant, amount: amount)
        expense.merchant = merchant
        expense.amount = amount
        expense.category = category
        expense.date = date
        try context.save()
    }

    func delete(_ expense: Expense) throws {
        context.delete(expense)
        try context.save()
    }

    /// Returns the trimmed merchant, or throws if the merchant or amount isn't allowed.
    private func validated(merchant: String, amount: Int) throws -> String {
        let merchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !merchant.isEmpty else { throw ExpenseError.emptyMerchant }
        guard amount > 0 else { throw ExpenseError.nonPositiveAmount }
        return merchant
    }
}
