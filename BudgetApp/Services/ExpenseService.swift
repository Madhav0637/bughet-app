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

/// Everything needed to put a deleted expense back, kept after the expense itself is gone.
struct ExpenseSnapshot: Equatable {
    let id: UUID
    let merchant: String
    let amount: Int
    let date: Date
    let categoryID: UUID?
    let note: String?

    init(_ expense: Expense) {
        id = expense.id
        merchant = expense.merchant
        amount = expense.amount
        date = expense.date
        categoryID = expense.category?.id
        note = expense.note
    }
}

struct ExpenseService {
    let context: ModelContext

    @discardableResult
    func add(merchant: String, amount: Int, category: Category, date: Date = .now, note: String? = nil) throws -> Expense {
        let merchant = try validated(merchant: merchant, amount: amount)
        let expense = Expense(merchant: merchant, amount: amount, date: date, category: category, note: Self.cleaned(note))
        context.insert(expense)
        try context.save()
        return expense
    }

    /// Validates everything first, so an invalid edit leaves the expense untouched. A nil or blank note removes it.
    func update(_ expense: Expense, merchant: String, amount: Int, category: Category, date: Date, note: String?) throws {
        let merchant = try validated(merchant: merchant, amount: amount)
        expense.merchant = merchant
        expense.amount = amount
        expense.category = category
        expense.date = date
        expense.note = Self.cleaned(note)
        try context.save()
    }

    func delete(_ expense: Expense) throws {
        context.delete(expense)
        try context.save()
    }

    /// Puts a deleted expense back exactly as it was, including its id. Fails if its category has since been deleted.
    @discardableResult
    func restore(_ snapshot: ExpenseSnapshot) throws -> Expense {
        guard let categoryID = snapshot.categoryID,
              let category = try CategoryService(context: context).category(withID: categoryID) else {
            throw ExpenseError.categoryNotFound
        }
        let expense = Expense(id: snapshot.id, merchant: snapshot.merchant, amount: snapshot.amount,
                              date: snapshot.date, category: category, note: snapshot.note)
        context.insert(expense)
        try context.save()
        return expense
    }

    /// Returns the trimmed merchant, or throws if the merchant or amount isn't allowed.
    private func validated(merchant: String, amount: Int) throws -> String {
        let merchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !merchant.isEmpty else { throw ExpenseError.emptyMerchant }
        guard amount > 0 else { throw ExpenseError.nonPositiveAmount }
        return merchant
    }

    /// Trims a note, turning a blank one into nil.
    static func cleaned(_ note: String?) -> String? {
        guard let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty else { return nil }
        return note
    }
}
