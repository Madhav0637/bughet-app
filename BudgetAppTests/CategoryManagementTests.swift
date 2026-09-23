import Foundation
import SwiftData
import Testing
@testable import BudgetApp

@Suite("Category management")
struct CategoryManagementTests {
    let db: TestDatabase
    let service: CategoryService

    init() throws {
        db = try TestDatabase()
        service = CategoryService(context: db.context)
    }

    private var allNames: [String] {
        get throws { try db.context.fetch(FetchDescriptor<Category>()).map(\.name).sorted() }
    }

    // MARK: Adding

    @Test func addsACategoryWithTrimmedName() throws {
        let category = try service.add(name: "  Rent ", emoji: "🏠")
        #expect(category.name == "Rent")
        #expect(category.emoji == "🏠")
        #expect(try allNames == ["Rent"])
    }

    @Test(arguments: ["", "   "])
    func rejectsAnEmptyName(name: String) throws {
        #expect(throws: CategoryError.emptyName) { try service.add(name: name, emoji: "🏠") }
        #expect(try allNames.isEmpty)
    }

    @Test(arguments: ["Food", "food", " FOOD "])
    func rejectsADuplicateNameIgnoringCase(name: String) throws {
        _ = try db.makeCategory("Food")
        #expect(throws: CategoryError.duplicateName) { try service.add(name: name, emoji: "🍕") }
        #expect(try allNames == ["Food"])
    }

    @Test(arguments: ["", "a", "1", "#", "🍔🍕", "ab"])
    func rejectsAnythingButOneEmoji(emoji: String) throws {
        #expect(throws: CategoryError.invalidEmoji) { try service.add(name: "Rent", emoji: emoji) }
    }

    @Test(arguments: ["🍔", "🛍️", "❤️", "☕️", "🧑🏽‍🍳", "🇮🇳"])
    func acceptsSingleEmoji(emoji: String) {
        #expect(CategoryService.isValidEmoji(emoji))
    }

    // MARK: Editing

    @Test func renamesAndChangesEmoji() throws {
        let food = try db.makeCategory("Food", emoji: "🍔")
        try service.update(food, name: "Eating Out", emoji: "🍽️")
        #expect(food.name == "Eating Out")
        #expect(food.emoji == "🍽️")
    }

    @Test func canChangeOnlyTheCapitalisationOfItsOwnName() throws {
        let food = try db.makeCategory("food")
        try service.update(food, name: "Food", emoji: "🍔")
        #expect(food.name == "Food")
    }

    @Test func cannotRenameToAnotherCategorysName() throws {
        _ = try db.makeCategory("Food")
        let bills = try db.makeCategory("Bills", emoji: "🧾")
        #expect(throws: CategoryError.duplicateName) { try service.update(bills, name: "FOOD", emoji: "🧾") }
        #expect(bills.name == "Bills")
    }

    @Test func invalidEditChangesNothing() throws {
        let food = try db.makeCategory("Food", emoji: "🍔")
        #expect(throws: CategoryError.invalidEmoji) { try service.update(food, name: "Meals", emoji: "x") }
        #expect(food.name == "Food")
        #expect(food.emoji == "🍔")
    }

    @Test func renamingKeepsTheCategorysExpenses() throws {
        let food = try db.makeCategory("Food")
        try db.addExpense(100, to: food)
        try service.update(food, name: "Meals", emoji: "🍔")
        #expect(food.expenses.count == 1)
    }

    // MARK: Moving expenses

    @Test func movesEveryExpenseToAnotherCategory() throws {
        let food = try db.makeCategory("Food")
        let other = try db.makeCategory("Other")
        try db.addExpense(100, to: food)
        try db.addExpense(200, to: food)
        try db.addExpense(50, to: other)

        try service.moveAllExpenses(from: food, to: other)

        #expect(food.expenses.isEmpty)
        #expect(other.expenses.count == 3)
        #expect(try db.context.fetch(FetchDescriptor<Expense>()).allSatisfy { $0.category === other })
    }

    @Test func cannotMoveExpensesIntoTheSameCategory() throws {
        let food = try db.makeCategory("Food")
        try db.addExpense(100, to: food)
        #expect(throws: CategoryError.sameCategory) { try service.moveAllExpenses(from: food, to: food) }
        #expect(food.expenses.count == 1)
    }

    // MARK: Deleting

    @Test func deletesAnEmptyCategory() throws {
        _ = try db.makeCategory("Food")
        let rent = try db.makeCategory("Rent")
        try service.delete(rent)
        #expect(try allNames == ["Food"])
    }

    @Test func cannotDeleteACategoryInUse() throws {
        let food = try db.makeCategory("Food")
        _ = try db.makeCategory("Other")
        try db.addExpense(100, to: food)
        try db.addExpense(200, to: food)

        #expect(throws: CategoryError.inUse(expenseCount: 2)) { try service.delete(food) }
        #expect(try allNames == ["Food", "Other"])
    }

    @Test func moveThenDeleteWorks() throws {
        let food = try db.makeCategory("Food")
        let other = try db.makeCategory("Other")
        try db.addExpense(100, to: food)

        try service.moveAllExpenses(from: food, to: other)
        try service.delete(food)

        #expect(try allNames == ["Other"])
        #expect(other.expenses.count == 1)
    }

    @Test func cannotDeleteTheLastCategory() throws {
        let only = try db.makeCategory("Other")
        #expect(throws: CategoryError.lastCategory) { try service.delete(only) }
        #expect(try allNames == ["Other"])
    }

    @Test func inUseMessageUsesTheRightWord() {
        #expect(CategoryError.inUse(expenseCount: 1).errorDescription?.hasPrefix("Used by 1 expense.") == true)
        #expect(CategoryError.inUse(expenseCount: 3).errorDescription?.hasPrefix("Used by 3 expenses.") == true)
    }
}
