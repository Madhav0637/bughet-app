import Foundation
import SwiftData
import Testing
@testable import BudgetApp

@Suite("MerchantSuggestions")
struct MerchantSuggestionsTests {
    let db: TestDatabase
    let food: Category
    let transport: Category

    init() throws {
        db = try TestDatabase()
        food = try db.makeCategory("Food")
        transport = try db.makeCategory("Transport")
        try db.addExpense(300, to: food, merchant: "Zomato", on: TestDate.make(2026, 9, 20))
        try db.addExpense(180, to: transport, merchant: "Uber", on: TestDate.make(2026, 9, 21))
        try db.addExpense(90, to: food, merchant: "Café Coffee Day", on: TestDate.make(2026, 9, 22))
        try db.addExpense(400, to: transport, merchant: "zomato", on: TestDate.make(2026, 9, 23)) // same merchant, newer
    }

    private func suggestions() throws -> MerchantSuggestions {
        MerchantSuggestions(expenses: try db.context.fetch(FetchDescriptor<Expense>()))
    }

    @Test func uniqueMostRecentFirst() throws {
        #expect(try suggestions().all.map(\.name) == ["zomato", "Café Coffee Day", "Uber"])
    }

    @Test func emptyTextGivesTheMostRecent() throws {
        #expect(try suggestions().matching("", limit: 2).map(\.name) == ["zomato", "Café Coffee Day"])
    }

    @Test func matchesIgnoreCaseAndAccentsAndPreferPrefixes() throws {
        #expect(try suggestions().matching("cafe").map(\.name) == ["Café Coffee Day"])
        #expect(try suggestions().matching("o").map(\.name) == ["zomato", "Café Coffee Day"]) // no prefix match: recency
        #expect(try suggestions().matching("U").map(\.name) == ["Uber"])
    }

    @Test func exactMatchIsLeftOut() throws {
        #expect(try suggestions().matching(" UBER ").isEmpty)
    }

    @Test func categoryComesFromTheLatestUse() throws {
        let suggestions = try suggestions()
        #expect(suggestions.categoryID(for: "ZOMATO ") == transport.id)
        #expect(suggestions.categoryID(for: "uber") == transport.id)
        #expect(suggestions.categoryID(for: "Blinkit") == nil)
    }
}

@Suite("KeypadInput")
struct KeypadInputTests {
    private func type(_ keys: [KeypadInput.Key], from text: String = "") -> String {
        keys.reduce(text) { KeypadInput.apply($1, to: $0) }
    }

    @Test func digitsAppend() {
        #expect(type([.digit(4), .digit(2), .digit(0)]) == "420")
    }

    @Test func noLeadingZeros() {
        #expect(type([.digit(0), .doubleZero, .digit(5)]) == "5")
    }

    @Test func doubleZeroAddsTwoZeros() {
        #expect(type([.digit(5), .doubleZero]) == "500")
    }

    @Test func deleteRemovesTheLastDigit() {
        #expect(type([.delete], from: "420") == "42")
        #expect(type([.delete], from: "") == "")
    }

    @Test func stopsAtNineDigits() {
        #expect(type([.digit(1)], from: "123456789") == "123456789")
        #expect(type([.doubleZero], from: "12345678") == "123456780")
    }
}
