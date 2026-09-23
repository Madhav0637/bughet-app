import Foundation
import Testing
@testable import BudgetApp

@Suite("PeriodCalculator")
struct PeriodCalculatorTests {
    let calculator = PeriodCalculator(calendar: TestDate.calendar)

    @Test func weekRunsMondayToMonday() {
        // Wednesday 23 September 2026
        let range = calculator.range(of: .week, containing: TestDate.make(2026, 9, 23))
        #expect(range.lowerBound == TestDate.make(2026, 9, 21, 0))
        #expect(range.upperBound == TestDate.make(2026, 9, 28, 0))
    }

    @Test func sundayBelongsToTheWeekThatStartedOnMonday() {
        let range = calculator.range(of: .week, containing: TestDate.make(2026, 9, 27, 23, 59))
        #expect(range.lowerBound == TestDate.make(2026, 9, 21, 0))
    }

    @Test func mondayMidnightStartsANewWeek() {
        let range = calculator.range(of: .week, containing: TestDate.make(2026, 9, 28, 0))
        #expect(range.lowerBound == TestDate.make(2026, 9, 28, 0))
    }

    @Test func weekCanCrossMonthAndYear() {
        // Thursday 1 January 2026; that week starts Monday 29 December 2025
        let range = calculator.range(of: .week, containing: TestDate.make(2026, 1, 1))
        #expect(range.lowerBound == TestDate.make(2025, 12, 29, 0))
        #expect(range.upperBound == TestDate.make(2026, 1, 5, 0))
    }

    @Test func weeksStartOnMondayWhateverTheDeviceSetting() {
        var sundayFirst = TestDate.calendar
        sundayFirst.firstWeekday = 1
        let range = PeriodCalculator(calendar: sundayFirst).range(of: .week, containing: TestDate.make(2026, 9, 23))
        #expect(range.lowerBound == TestDate.make(2026, 9, 21, 0))
    }

    @Test func monthRunsFromTheFirst() {
        let range = calculator.range(of: .month, containing: TestDate.make(2026, 9, 23))
        #expect(range.lowerBound == TestDate.make(2026, 9, 1, 0))
        #expect(range.upperBound == TestDate.make(2026, 10, 1, 0))
    }

    @Test func februaryInALeapYear() {
        let range = calculator.range(of: .month, containing: TestDate.make(2028, 2, 10))
        #expect(range.upperBound == TestDate.make(2028, 3, 1, 0))
    }

    @Test func yearRunsJanuaryToJanuary() {
        let range = calculator.range(of: .year, containing: TestDate.make(2026, 9, 23))
        #expect(range.lowerBound == TestDate.make(2026, 1, 1, 0))
        #expect(range.upperBound == TestDate.make(2027, 1, 1, 0))
    }

    @Test(arguments: Period.allCases)
    func dateIsInsideItsOwnPeriod(period: Period) {
        let date = TestDate.make(2026, 9, 23, 18, 30)
        #expect(calculator.range(of: period, containing: date).contains(date))
    }
}
