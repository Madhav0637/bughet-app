import Foundation
import SwiftData
import Testing
@testable import BudgetApp

@Suite("ExpenseService")
struct ExpenseServiceTests {
    let db: TestDatabase
    let food: Category

    init() throws {
        db = try TestDatabase()
        food = try db.makeCategory("Food")
    }

    @Test func savesAValidExpense() throws {
        let date = TestDate.make(2026, 9, 23)
        try db.addExpense(250, to: food, merchant: "Swiggy", on: date)

        let saved = try db.context.fetch(FetchDescriptor<Expense>())
        #expect(saved.count == 1)
        #expect(saved.first?.merchant == "Swiggy")
        #expect(saved.first?.amount == 250)
        #expect(saved.first?.date == date)
        #expect(saved.first?.category === food)
        #expect(food.expenses.count == 1)
    }

    @Test func trimsSpacesAroundTheMerchant() throws {
        let expense = try db.addExpense(99, to: food, merchant: "  Chai Point \n")
        #expect(expense.merchant == "Chai Point")
    }

    @Test func dateDefaultsToNow() throws {
        let before = Date.now
        let expense = try ExpenseService(context: db.context).add(merchant: "Uber", amount: 180, category: food)
        #expect(expense.date >= before && expense.date <= .now)
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func rejectsAnEmptyMerchant(merchant: String) throws {
        #expect(throws: ExpenseError.emptyMerchant) {
            try db.addExpense(100, to: food, merchant: merchant)
        }
        #expect(try db.context.fetchCount(FetchDescriptor<Expense>()) == 0)
    }

    @Test(arguments: [0, -1, -500])
    func rejectsAmountsOfZeroOrLess(amount: Int) throws {
        #expect(throws: ExpenseError.nonPositiveAmount) {
            try db.addExpense(amount, to: food)
        }
        #expect(try db.context.fetchCount(FetchDescriptor<Expense>()) == 0)
    }

    @Test func errorMessagesAreReadable() {
        #expect(ExpenseError.emptyMerchant.errorDescription == "Please enter what you spent on.")
        #expect(ExpenseError.nonPositiveAmount.errorDescription == "Amount must be more than ₹0.")
    }
}
