import Foundation
import SwiftData
import Testing
@testable import BudgetApp

@Suite("HistoryFilter")
struct HistoryFilterTests {
    let db: TestDatabase
    let food: Category
    let transport: Category

    init() throws {
        db = try TestDatabase()
        food = try db.makeCategory("Food")
        transport = try db.makeCategory("Transport")
        try db.addExpense(250, to: food, merchant: "Swiggy", on: TestDate.make(2026, 9, 21, 13))
        try db.addExpense(180, to: transport, merchant: "Uber", on: TestDate.make(2026, 9, 21, 9))
        try db.addExpense(90, to: food, merchant: "Café Coffee Day", on: TestDate.make(2026, 9, 22, 17))
        try db.addExpense(400, to: transport, merchant: "Uber Intercity", on: TestDate.make(2026, 9, 23, 8))
    }

    private var expenses: [Expense] {
        get throws { try db.context.fetch(FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])) }
    }

    @Test func noFilterReturnsEverything() throws {
        let filter = HistoryFilter()
        #expect(try filter.apply(to: expenses).count == 4)
        #expect(!filter.isActive)
    }

    @Test func searchMatchesPartOfTheMerchantIgnoringCase() throws {
        let filter = HistoryFilter(searchText: "uBeR")
        #expect(try filter.apply(to: expenses).map(\.merchant) == ["Uber Intercity", "Uber"])
    }

    @Test func searchIgnoresAccentsAndSurroundingSpaces() throws {
        let filter = HistoryFilter(searchText: "  cafe ")
        #expect(try filter.apply(to: expenses).map(\.merchant) == ["Café Coffee Day"])
    }

    @Test func blankSearchCountsAsNoSearch() throws {
        let filter = HistoryFilter(searchText: "   ")
        #expect(try filter.apply(to: expenses).count == 4)
        #expect(!filter.isActive)
    }

    @Test func filtersByCategory() throws {
        let filter = HistoryFilter(categoryID: food.id)
        #expect(try filter.apply(to: expenses).map(\.merchant) == ["Café Coffee Day", "Swiggy"])
        #expect(filter.isActive)
    }

    @Test func searchAndCategoryCombine() throws {
        let filter = HistoryFilter(searchText: "intercity", categoryID: transport.id)
        #expect(try filter.apply(to: expenses).map(\.merchant) == ["Uber Intercity"])

        let noMatch = HistoryFilter(searchText: "swiggy", categoryID: transport.id)
        #expect(try noMatch.apply(to: expenses).isEmpty)
    }

    @Test func groupsByDayNewestFirst() throws {
        let groups = HistoryFilter.groupByDay(try expenses, calendar: TestDate.calendar)

        #expect(groups.map(\.day) == [
            TestDate.make(2026, 9, 23, 0),
            TestDate.make(2026, 9, 22, 0),
            TestDate.make(2026, 9, 21, 0),
        ])
        #expect(groups.last?.expenses.map(\.merchant) == ["Swiggy", "Uber"])
    }

    @Test func dayTitles() {
        let now = TestDate.make(2026, 9, 23, 20)
        let calendar = TestDate.calendar

        #expect(HistoryFilter.title(forDay: TestDate.make(2026, 9, 23, 0), now: now, calendar: calendar) == "Today")
        #expect(HistoryFilter.title(forDay: TestDate.make(2026, 9, 22, 0), now: now, calendar: calendar) == "Yesterday")

        let older = HistoryFilter.title(forDay: TestDate.make(2026, 9, 21, 0), now: now, calendar: calendar)
        #expect(older != "Today" && older != "Yesterday")
        #expect(older.contains("21"))
        #expect(!older.contains("2026"))

        let lastYear = HistoryFilter.title(forDay: TestDate.make(2025, 12, 31, 0), now: now, calendar: calendar)
        #expect(lastYear.contains("2025"))
    }
}
