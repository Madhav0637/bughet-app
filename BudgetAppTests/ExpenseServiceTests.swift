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

    @Test func updatesEveryField() throws {
        let transport = try db.makeCategory("Transport")
        let expense = try db.addExpense(250, to: food, merchant: "Swiggy", on: TestDate.make(2026, 9, 23))
        let newDate = TestDate.make(2026, 9, 20, 9)

        try ExpenseService(context: db.context).update(
            expense, merchant: "  Uber ", amount: 180, category: transport, date: newDate
        )

        #expect(expense.merchant == "Uber")
        #expect(expense.amount == 180)
        #expect(expense.category === transport)
        #expect(expense.date == newDate)
        #expect(food.expenses.isEmpty)
        #expect(transport.expenses.count == 1)
    }

    @Test func invalidUpdateChangesNothing() throws {
        let transport = try db.makeCategory("Transport")
        let date = TestDate.make(2026, 9, 23)
        let expense = try db.addExpense(250, to: food, merchant: "Swiggy", on: date)
        let service = ExpenseService(context: db.context)

        #expect(throws: ExpenseError.nonPositiveAmount) {
            try service.update(expense, merchant: "Uber", amount: 0, category: transport, date: .now)
        }
        #expect(throws: ExpenseError.emptyMerchant) {
            try service.update(expense, merchant: " ", amount: 100, category: transport, date: .now)
        }
        #expect(expense.merchant == "Swiggy")
        #expect(expense.amount == 250)
        #expect(expense.category === food)
        #expect(expense.date == date)
    }

    @Test func deletesAnExpense() throws {
        let keep = try db.addExpense(100, to: food, merchant: "Keep")
        let remove = try db.addExpense(200, to: food, merchant: "Remove")

        try ExpenseService(context: db.context).delete(remove)

        let remaining = try db.context.fetch(FetchDescriptor<Expense>())
        #expect(remaining.map(\.merchant) == ["Keep"])
        #expect(food.expenses.map(\.merchant) == [keep.merchant])
    }

    @Test func errorMessagesAreReadable() {
        #expect(ExpenseError.emptyMerchant.errorDescription == "Please enter what you spent on.")
        #expect(ExpenseError.nonPositiveAmount.errorDescription == "Amount must be more than ₹0.")
    }
}
