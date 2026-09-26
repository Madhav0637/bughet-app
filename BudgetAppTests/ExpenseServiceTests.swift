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
            expense, merchant: "  Uber ", amount: 180, category: transport, date: newDate, note: nil
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
            try service.update(expense, merchant: "Uber", amount: 0, category: transport, date: .now, note: nil)
        }
        #expect(throws: ExpenseError.emptyMerchant) {
            try service.update(expense, merchant: " ", amount: 100, category: transport, date: .now, note: nil)
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

    @Test func savesATrimmedNote() throws {
        let expense = try ExpenseService(context: db.context).add(merchant: "Zomato", amount: 420, category: food,
                                                                 note: "  team dinner \n")
        #expect(expense.note == "team dinner")
    }

    @Test(arguments: [nil, "", "   "])
    func blankNoteIsStoredAsNil(note: String?) throws {
        let expense = try ExpenseService(context: db.context).add(merchant: "Zomato", amount: 420, category: food, note: note)
        #expect(expense.note == nil)
    }

    @Test func updateCanChangeAndRemoveTheNote() throws {
        let service = ExpenseService(context: db.context)
        let expense = try service.add(merchant: "Zomato", amount: 420, category: food, note: "lunch")

        try service.update(expense, merchant: "Zomato", amount: 420, category: food, date: expense.date, note: "dinner")
        #expect(expense.note == "dinner")
        try service.update(expense, merchant: "Zomato", amount: 420, category: food, date: expense.date, note: " ")
        #expect(expense.note == nil)
    }

    @Test func restorePutsADeletedExpenseBackExactly() throws {
        let service = ExpenseService(context: db.context)
        let date = TestDate.make(2026, 9, 21, 20, 15)
        let expense = try service.add(merchant: "Swiggy", amount: 310, category: food, date: date, note: "late night")
        let snapshot = ExpenseSnapshot(expense)
        try service.delete(expense)

        let restored = try service.restore(snapshot)

        #expect(restored.id == snapshot.id)
        #expect(restored.merchant == "Swiggy")
        #expect(restored.amount == 310)
        #expect(restored.date == date)
        #expect(restored.note == "late night")
        #expect(restored.category === food)
        #expect(try db.context.fetchCount(FetchDescriptor<Expense>()) == 1)
    }

    @Test func restoreFailsWhenTheCategoryIsGone() throws {
        let service = ExpenseService(context: db.context)
        let spare = try db.makeCategory("Spare")
        let snapshot = ExpenseSnapshot(try service.add(merchant: "Shop", amount: 50, category: spare))
        try service.delete(try #require(spare.expenses.first))
        try CategoryService(context: db.context).delete(spare)

        #expect(throws: ExpenseError.categoryNotFound) { try service.restore(snapshot) }
    }

    @Test func errorMessagesAreReadable() {
        #expect(ExpenseError.emptyMerchant.errorDescription == "Please enter what you spent on.")
        #expect(ExpenseError.nonPositiveAmount.errorDescription == "Amount must be more than ₹0.")
    }
}
