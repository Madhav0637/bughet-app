import Foundation
import PDFKit
import SwiftData
import Testing
@testable import BudgetApp

@Suite("Export")
struct ExportTests {
    let db: TestDatabase
    let food: Category
    let bills: Category
    let ist = TestDate.calendar.timeZone
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "ExportTests-\(UUID().uuidString)", directoryHint: .isDirectory)

    init() throws {
        db = try TestDatabase()
        food = try db.makeCategory("Food", emoji: "🍔")
        bills = try db.makeCategory("Bills", emoji: "🧾")
        try db.addExpense(450, to: food, merchant: "Swiggy", on: TestDate.make(2026, 9, 2, 13))
        try db.addExpense(1850, to: bills, merchant: "Electricity bill", on: TestDate.make(2026, 9, 5, 9))
        try db.addExpense(380, to: food, merchant: "Zomato", on: TestDate.make(2026, 9, 20, 21))
    }

    private var expenses: [Expense] {
        get throws { try db.context.fetch(FetchDescriptor<Expense>()) }
    }

    private func pdfText(_ data: Data) throws -> String {
        let document = try #require(PDFDocument(data: data))
        return try #require(document.string)
    }

    // MARK: File names and files

    @Test(arguments: ExportFormat.allCases)
    func fileNameHasTheDateAndTheRightExtension(format: ExportFormat) {
        let name = ExportWriter.fileName(for: format, on: TestDate.make(2026, 9, 4, 23, 30), timeZone: ist)
        #expect(name == "BudgetApp-expenses-2026-09-04.\(format.rawValue)")
    }

    @Test func writesARealCSVFile() throws {
        let url = try ExportWriter.write(.csv, expenses: expenses, to: directory, now: TestDate.make(2026, 9, 24), timeZone: ist)
        #expect(url.pathExtension == "csv")
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.hasPrefix("Date,Merchant,Category,Amount\n"))
        #expect(text.contains("2026-09-05 09:00,Electricity bill,Bills,1850"))
    }

    @Test func writesARealPDFFile() throws {
        let url = try ExportWriter.write(.pdf, expenses: expenses, to: directory, now: TestDate.make(2026, 9, 24), timeZone: ist)
        #expect(url.pathExtension == "pdf")
        let data = try Data(contentsOf: url)
        #expect(data.starts(with: Data("%PDF".utf8)))
    }

    @Test func writingAgainReplacesTheOldFile() throws {
        let now = TestDate.make(2026, 9, 24)
        try ExportWriter.write(.csv, expenses: expenses, to: directory, now: now, timeZone: ist)
        try db.addExpense(99, to: food, merchant: "Chai", on: TestDate.make(2026, 9, 23))
        let url = try ExportWriter.write(.csv, expenses: expenses, to: directory, now: now, timeZone: ist)

        #expect(try String(contentsOf: url, encoding: .utf8).contains("Chai"))
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path()).count == 1)
    }

    // MARK: PDF contents

    @Test func pdfHasTheTitleTotalAndDateRange() throws {
        let text = try pdfText(PDFReport.data(for: expenses, generatedAt: TestDate.make(2026, 9, 24), timeZone: ist))
        #expect(text.contains("Expense Report"))
        #expect(text.contains("2,680")) // ₹450 + ₹1,850 + ₹380
        #expect(text.contains("3 expenses"))
        #expect(text.contains("2 Sept 2026") || text.contains("2 Sep 2026"))
        #expect(text.contains("20 Sept 2026") || text.contains("20 Sep 2026"))
    }

    @Test func pdfListsCategoriesAndEveryExpense() throws {
        let text = try pdfText(PDFReport.data(for: expenses, timeZone: ist))
        #expect(text.contains("By Category"))
        #expect(text.contains("Bills"))
        #expect(text.contains("69%")) // 1,850 of 2,680
        for merchant in ["Swiggy", "Electricity bill", "Zomato"] {
            #expect(text.contains(merchant))
        }
    }

    @Test func shortReportFitsOnOnePage() throws {
        let document = try #require(PDFDocument(data: PDFReport.data(for: expenses, timeZone: ist)))
        #expect(document.pageCount == 1)
    }

    @Test func longReportContinuesOnMorePagesWithPageNumbers() throws {
        for day in 1...28 {
            for hour in [9, 13, 20] {
                try db.addExpense(day * 10, to: food, merchant: "Shop \(day)-\(hour)", on: TestDate.make(2026, 8, day, hour))
            }
        }
        let data = PDFReport.data(for: try expenses, timeZone: ist)
        let document = try #require(PDFDocument(data: data))

        #expect(document.pageCount >= 3)
        let lastPage = try #require(document.page(at: document.pageCount - 1)?.string)
        #expect(lastPage.contains("Page \(document.pageCount)"))
        // The column headings repeat at the top of each continued page.
        #expect(try #require(document.page(at: 1)?.string).contains("Merchant"))
        // Every expense makes it into the report.
        #expect(try pdfText(data).contains("Shop 28-20"))
    }

    @Test func emptyReportIsStillAValidPDF() throws {
        let document = try #require(PDFDocument(data: PDFReport.data(for: [], timeZone: ist)))
        #expect(document.pageCount == 1)
        #expect(document.string?.contains("0 expenses") == true)
    }
}
