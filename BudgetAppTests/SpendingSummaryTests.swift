import Foundation
import SwiftData
import Testing
@testable import BudgetApp

@Suite("SpendingSummary")
struct SpendingSummaryTests {
    let db: TestDatabase
    let food: Category
    let bills: Category
    let transport: Category
    /// September 2026
    let september = PeriodCalculator(calendar: TestDate.calendar)
        .range(of: .month, containing: TestDate.make(2026, 9, 15))

    init() throws {
        db = try TestDatabase()
        food = try db.makeCategory("Food")
        bills = try db.makeCategory("Bills")
        transport = try db.makeCategory("Transport")
    }

    private func summary(recentLimit: Int = 5) throws -> SpendingSummary {
        SpendingSummary(expenses: try db.context.fetch(FetchDescriptor<Expense>()), in: september, recentLimit: recentLimit)
    }

    @Test func emptyPeriod() throws {
        let summary = try summary()
        #expect(summary.total == 0)
        #expect(summary.categoryTotals.isEmpty)
        #expect(summary.recent.isEmpty)
    }

    @Test func totalsOnlyExpensesInsideThePeriod() throws {
        try db.addExpense(100, to: food, on: TestDate.make(2026, 9, 10))
        try db.addExpense(250, to: bills, on: TestDate.make(2026, 9, 20))
        try db.addExpense(999, to: food, on: TestDate.make(2026, 8, 31, 23, 59)) // August
        try db.addExpense(999, to: food, on: TestDate.make(2026, 10, 1, 0, 0)) // October

        #expect(try summary().total == 350)
    }

    @Test func periodIncludesItsFirstInstantButNotItsEnd() throws {
        try db.addExpense(1, to: food, on: september.lowerBound)
        try db.addExpense(1000, to: food, on: september.upperBound)

        #expect(try summary().total == 1)
    }

    @Test func groupsByCategoryHighestFirst() throws {
        try db.addExpense(100, to: food, on: TestDate.make(2026, 9, 1))
        try db.addExpense(150, to: food, on: TestDate.make(2026, 9, 2))
        try db.addExpense(500, to: bills, on: TestDate.make(2026, 9, 3))
        try db.addExpense(80, to: transport, on: TestDate.make(2026, 9, 4))

        let totals = try summary().categoryTotals
        #expect(totals.map(\.category.name) == ["Bills", "Food", "Transport"])
        #expect(totals.map(\.amount) == [500, 250, 80])
    }

    @Test func categoryTotalsAddUpToTheTotal() throws {
        try db.addExpense(120, to: food, on: TestDate.make(2026, 9, 5))
        try db.addExpense(340, to: bills, on: TestDate.make(2026, 9, 6))
        try db.addExpense(60, to: transport, on: TestDate.make(2026, 9, 7))

        let summary = try summary()
        #expect(summary.categoryTotals.reduce(0) { $0 + $1.amount } == summary.total)
    }

    @Test func leavesOutCategoriesWithNoSpendingInThePeriod() throws {
        try db.addExpense(100, to: food, on: TestDate.make(2026, 9, 5))
        try db.addExpense(700, to: bills, on: TestDate.make(2026, 8, 5)) // August only

        #expect(try summary().categoryTotals.map(\.category.name) == ["Food"])
    }

    @Test func equalAmountsAreSortedByName() throws {
        try db.addExpense(200, to: transport, on: TestDate.make(2026, 9, 5))
        try db.addExpense(200, to: bills, on: TestDate.make(2026, 9, 6))

        #expect(try summary().categoryTotals.map(\.category.name) == ["Bills", "Transport"])
    }

    @Test func recentIsNewestFirstAndLimited() throws {
        for day in 1...7 {
            try db.addExpense(day * 10, to: food, merchant: "Day \(day)", on: TestDate.make(2026, 9, day))
        }

        let recent = try summary(recentLimit: 5).recent
        #expect(recent.map(\.merchant) == ["Day 7", "Day 6", "Day 5", "Day 4", "Day 3"])
    }
}
