import Foundation
import SwiftData
import Testing
@testable import BudgetApp

@Suite("CSVExporter")
struct CSVExporterTests {
    let db: TestDatabase
    let food: Category
    let ist = TestDate.calendar.timeZone

    init() throws {
        db = try TestDatabase()
        food = try db.makeCategory("Food")
    }

    private func export() throws -> [String] {
        let csv = CSVExporter.csv(for: try db.context.fetch(FetchDescriptor<Expense>()), timeZone: ist)
        #expect(csv.hasSuffix("\n"))
        return csv.split(separator: "\n", omittingEmptySubsequences: false).dropLast().map(String.init)
    }

    @Test func noExpensesGivesJustTheHeader() throws {
        #expect(try export() == ["Date,Merchant,Category,Amount"])
    }

    @Test func writesOneRowPerExpense() throws {
        try db.addExpense(1250, to: food, merchant: "Swiggy", on: TestDate.make(2026, 9, 23, 20, 5))
        #expect(try export() == [
            "Date,Merchant,Category,Amount",
            "2026-09-23 20:05,Swiggy,Food,1250",
        ])
    }

    @Test func oldestExpenseComesFirst() throws {
        try db.addExpense(3, to: food, merchant: "Third", on: TestDate.make(2026, 9, 3))
        try db.addExpense(1, to: food, merchant: "First", on: TestDate.make(2026, 9, 1))
        try db.addExpense(2, to: food, merchant: "Second", on: TestDate.make(2026, 9, 2))

        #expect(try export().dropFirst().map { $0.split(separator: ",")[1] } == ["First", "Second", "Third"])
    }

    @Test func datesUseTheGivenTimeZone() throws {
        // 20:05 in India is 14:35 UTC.
        let date = TestDate.make(2026, 9, 23, 20, 5)
        try db.addExpense(10, to: food, on: date)
        let expenses = try db.context.fetch(FetchDescriptor<Expense>())

        let utc = CSVExporter.csv(for: expenses, timeZone: TimeZone(identifier: "UTC")!)
        #expect(utc.contains("2026-09-23 14:35,"))
    }

    @Test func amountsArePlainNumbers() throws {
        try db.addExpense(123456, to: food, merchant: "Laptop")
        #expect(try export().last?.hasSuffix(",123456") == true)
    }

    @Test func merchantWithACommaIsQuoted() throws {
        try db.addExpense(90, to: food, merchant: "Chai, Samosa", on: TestDate.make(2026, 9, 23))
        #expect(try export().last == "2026-09-23 12:00,\"Chai, Samosa\",Food,90")
    }

    @Test func quotesInsideAreDoubled() {
        #expect(CSVExporter.escape("Joe's \"Best\" Café") == "\"Joe's \"\"Best\"\" Café\"")
    }

    @Test func lineBreaksAreQuoted() {
        #expect(CSVExporter.escape("Line one\nLine two") == "\"Line one\nLine two\"")
    }

    @Test func plainTextIsLeftAlone() {
        #expect(CSVExporter.escape("Apollo Pharmacy") == "Apollo Pharmacy")
    }

    @Test(arguments: ["=SUM(A1)", "+91 Store", "-Refund", "@home"])
    func textThatLooksLikeAFormulaIsDefused(text: String) {
        #expect(CSVExporter.escape(text) == "'" + text)
    }

    @Test func categoryNamesAreEscapedToo() throws {
        let odd = try db.makeCategory("Bills, Rent")
        try db.addExpense(15000, to: odd, merchant: "Landlord", on: TestDate.make(2026, 9, 1))
        #expect(try export().last == "2026-09-01 12:00,Landlord,\"Bills, Rent\",15000")
    }
}
