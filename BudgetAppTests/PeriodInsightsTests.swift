import Foundation
import SwiftData
import Testing
@testable import BudgetApp

@Suite("PeriodInsights")
struct PeriodInsightsTests {
    let db: TestDatabase
    let food: Category
    let transport: Category
    let calculator = PeriodCalculator(calendar: TestDate.calendar)
    /// 26 Sep 2026, 14:00 IST.
    let now = TestDate.make(2026, 9, 26, 14)

    init() throws {
        db = try TestDatabase()
        food = try db.makeCategory("Food", emoji: "🍔")
        transport = try db.makeCategory("Transport", emoji: "🚕")
    }

    private var expenses: [Expense] {
        get throws { try db.context.fetch(FetchDescriptor<Expense>()) }
    }

    private func insights(_ period: Period = .month, offset: Int = 0) throws -> PeriodInsights {
        let range = calculator.range(of: period, offset: offset, from: now)
        return PeriodInsights(expenses: try expenses, period: period, range: range, now: now, calculator: calculator)
    }

    // MARK: Period offsets

    @Test func offsetMovesWholePeriods() {
        #expect(calculator.range(of: .month, offset: -1, from: now).lowerBound == TestDate.make(2026, 8, 1, 0))
        #expect(calculator.range(of: .month, offset: -9, from: now).lowerBound == TestDate.make(2025, 12, 1, 0))
        #expect(calculator.range(of: .week, offset: -1, from: now).lowerBound == TestDate.make(2026, 9, 14, 0))
        #expect(calculator.range(of: .year, offset: -1, from: now).lowerBound == TestDate.make(2025, 1, 1, 0))
    }

    @Test func offsetFromTheLastDayOfALongMonth() {
        // 31 March minus one month must be February, not early March.
        let range = calculator.range(of: .month, offset: -1, from: TestDate.make(2026, 3, 31))
        #expect(range.lowerBound == TestDate.make(2026, 2, 1, 0))
    }

    @Test func samePointLastMonth() {
        let range = calculator.samePointInPreviousPeriod(of: .month, now: now)
        #expect(range.lowerBound == TestDate.make(2026, 8, 1, 0))
        #expect(range.upperBound == TestDate.make(2026, 8, 26, 14))
    }

    @Test func samePointNeverRunsPastThePreviousPeriod() {
        let range = calculator.samePointInPreviousPeriod(of: .month, now: TestDate.make(2026, 3, 31, 12))
        #expect(range.upperBound == TestDate.make(2026, 3, 1, 0))
    }

    // MARK: Comparison

    @Test func runningMonthIsComparedWithTheSameStretchOfLastMonth() throws {
        try db.addExpense(900, to: food, on: TestDate.make(2026, 9, 10))
        try db.addExpense(1000, to: food, on: TestDate.make(2026, 8, 10))
        try db.addExpense(5000, to: food, on: TestDate.make(2026, 8, 28)) // after 26 Aug: not counted

        let comparison = PeriodComparison(expenses: try expenses, period: .month, now: now, calculator: calculator)
        #expect(comparison.isPartial)
        #expect(comparison.current == 900)
        #expect(comparison.previous == 1000)
        #expect(comparison.change == -0.1)
    }

    @Test func pastMonthIsComparedWithTheWholeMonthBefore() throws {
        try db.addExpense(1500, to: food, on: TestDate.make(2026, 8, 28))
        try db.addExpense(1000, to: food, on: TestDate.make(2026, 7, 30))

        let comparison = PeriodComparison(expenses: try expenses, period: .month, offset: -1, now: now, calculator: calculator)
        #expect(!comparison.isPartial)
        #expect(comparison.current == 1500)
        #expect(comparison.previous == 1000)
        #expect(comparison.change == 0.5)
    }

    @Test func noChangeWithoutEarlierSpending() throws {
        try db.addExpense(900, to: food, on: TestDate.make(2026, 9, 10))
        #expect(PeriodComparison(expenses: try expenses, period: .month, now: now, calculator: calculator).change == nil)
    }

    // MARK: Buckets and stats

    @Test func monthHasOneBucketPerDayIncludingFutureDays() throws {
        try db.addExpense(100, to: food, on: TestDate.make(2026, 9, 2, 9))
        try db.addExpense(50, to: food, on: TestDate.make(2026, 9, 2, 20))

        let insights = try insights()
        #expect(insights.buckets.count == 30)
        #expect(insights.buckets[1].amount == 150)
        #expect(insights.buckets.last?.amount == 0)
        #expect(!insights.bucketsAreMonths)
    }

    @Test func yearHasOneBucketPerMonth() throws {
        try db.addExpense(100, to: food, on: TestDate.make(2026, 2, 14))
        let insights = try insights(.year)
        #expect(insights.buckets.count == 12)
        #expect(insights.buckets[1].amount == 100)
        #expect(insights.bucketsAreMonths)
    }

    @Test func averagesAndNoSpendDaysCountOnlyDaysSoFar() throws {
        // 26 days so far in September; spending on 2 of them.
        try db.addExpense(1300, to: food, on: TestDate.make(2026, 9, 1))
        try db.addExpense(1300, to: food, on: TestDate.make(2026, 9, 26, 9))

        let insights = try insights()
        #expect(insights.elapsedDays == 26)
        #expect(insights.noSpendDays == 24)
        #expect(insights.averagePerDay == 100)
        #expect(insights.averagePerBucket == 100)
    }

    @Test func pastPeriodCountsEveryDay() throws {
        try db.addExpense(3100, to: food, on: TestDate.make(2026, 8, 15))
        let insights = try insights(offset: -1)
        #expect(insights.elapsedDays == 31)
        #expect(insights.averagePerDay == 100)
    }

    @Test func biggestAndPeak() throws {
        try db.addExpense(200, to: food, merchant: "Small", on: TestDate.make(2026, 9, 3))
        try db.addExpense(3499, to: food, merchant: "Myntra", on: TestDate.make(2026, 9, 12))
        try db.addExpense(300, to: food, merchant: "Chai", on: TestDate.make(2026, 9, 12, 18))

        let insights = try insights()
        #expect(insights.biggest?.merchant == "Myntra")
        #expect(insights.peak?.start == TestDate.make(2026, 9, 12, 0))
        #expect(insights.peak?.amount == 3799)
    }

    @Test func merchantsAreGroupedIgnoringCase() throws {
        try db.addExpense(300, to: food, merchant: "Zomato", on: TestDate.make(2026, 9, 3))
        try db.addExpense(200, to: food, merchant: "zomato ", on: TestDate.make(2026, 9, 5))
        try db.addExpense(100, to: food, merchant: "ZOMATO", on: TestDate.make(2026, 9, 7))
        try db.addExpense(900, to: transport, merchant: "Uber", on: TestDate.make(2026, 9, 8))

        let insights = try insights()
        #expect(insights.topMerchants.map(\.name) == ["Uber", "ZOMATO"]) // latest spelling
        #expect(insights.topMerchants.map(\.count) == [1, 3])
        #expect(insights.topMerchants.last?.amount == 600)
        #expect(insights.topMerchants.first?.emoji == "🚕")
        #expect(insights.mostFrequent?.name == "ZOMATO")
    }

    @Test func emptyPeriod() throws {
        let insights = try insights()
        #expect(insights.total == 0)
        #expect(insights.peak == nil)
        #expect(insights.biggest == nil)
        #expect(insights.topMerchants.isEmpty)
        #expect(insights.noSpendDays == 26)
    }

    @Test func lastSevenDaysEndWithToday() throws {
        try db.addExpense(420, to: food, on: TestDate.make(2026, 9, 26, 9))
        try db.addExpense(100, to: food, on: TestDate.make(2026, 9, 20, 9))
        try db.addExpense(999, to: food, on: TestDate.make(2026, 9, 19, 9)) // 8 days ago

        let days = PeriodInsights.lastDays(7, expenses: try expenses, now: now, calculator: calculator)
        #expect(days.count == 7)
        #expect(days.first?.start == TestDate.make(2026, 9, 20, 0))
        #expect(days.map(\.amount) == [100, 0, 0, 0, 0, 0, 420])
    }
}
