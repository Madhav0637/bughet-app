import Foundation
import SwiftData
import Testing
@testable import BudgetApp

@Suite("CategoryService")
struct CategoryServiceTests {
    let db: TestDatabase
    let service: CategoryService

    init() throws {
        db = try TestDatabase()
        service = CategoryService(context: db.context)
    }

    @Test func seedsTheSevenDefaultCategories() throws {
        try service.seedDefaultsIfNeeded()

        let names = try db.context.fetch(FetchDescriptor<Category>()).map(\.name).sorted()
        #expect(names == ["Bills", "Entertainment", "Food", "Health", "Other", "Shopping", "Transport"])
    }

    @Test func seedingTwiceDoesNotDuplicate() throws {
        try service.seedDefaultsIfNeeded()
        try service.seedDefaultsIfNeeded()
        #expect(try db.context.fetchCount(FetchDescriptor<Category>()) == 7)
    }

    @Test func doesNotSeedWhenCategoriesAlreadyExist() throws {
        _ = try db.makeCategory("Rent")
        try service.seedDefaultsIfNeeded()
        #expect(try db.context.fetch(FetchDescriptor<Category>()).map(\.name) == ["Rent"])
    }

    @Test func ordersMostUsedFirst() throws {
        let food = try db.makeCategory("Food")
        let bills = try db.makeCategory("Bills")
        let travel = try db.makeCategory("Travel")
        try db.addExpense(10, to: bills)
        for _ in 1...3 { try db.addExpense(10, to: food) }
        for _ in 1...2 { try db.addExpense(10, to: travel) }

        #expect(try service.categoriesByUsage().map(\.name) == ["Food", "Travel", "Bills"])
    }

    @Test func breaksTiesAlphabeticallyIgnoringCase() throws {
        _ = try db.makeCategory("shopping")
        _ = try db.makeCategory("Bills")
        _ = try db.makeCategory("food")

        #expect(try service.categoriesByUsage().map(\.name) == ["Bills", "food", "shopping"])
    }

    @Test func unusedCategoriesGoLast() throws {
        let zeta = try db.makeCategory("Zeta")
        _ = try db.makeCategory("Alpha")
        try db.addExpense(10, to: zeta)

        #expect(try service.categoriesByUsage().map(\.name) == ["Zeta", "Alpha"])
    }

    @Test func findsACategoryByID() throws {
        let food = try db.makeCategory("Food")
        #expect(try service.category(withID: food.id) === food)
        #expect(try service.category(withID: UUID()) == nil)
    }
}
