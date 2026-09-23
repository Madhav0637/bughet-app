import Foundation
import SwiftData
@testable import BudgetApp

/// The Objective-C runtime also defines a `Category` type; inside the app our own type wins,
/// but in the test target both are imported, so point the name at ours.
typealias Category = BudgetApp.Category

/// A fresh in-memory database for each test, so tests never touch the real store or each other.
struct TestDatabase {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: Expense.self, Category.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func makeCategory(_ name: String, emoji: String = "🧪") throws -> Category {
        let category = Category(name: name, emoji: emoji)
        context.insert(category)
        try context.save()
        return category
    }

    @discardableResult
    func addExpense(_ amount: Int, to category: Category, merchant: String = "Shop", on date: Date = .now) throws -> Expense {
        try ExpenseService(context: context).add(merchant: merchant, amount: amount, category: category, date: date)
    }
}

/// Builds dates in India Standard Time, so tests give the same result on any machine.
enum TestDate {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return calendar
    }()

    static func make(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
