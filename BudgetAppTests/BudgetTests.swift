import Foundation
import SwiftData
import Testing
@testable import BudgetApp

@Suite("Budget")
struct BudgetTests {
    let september = PeriodCalculator(calendar: TestDate.calendar).range(of: .month, containing: TestDate.make(2026, 9, 1))
    let defaults: UserDefaults

    init() {
        let name = "BudgetTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
    }

    private var alerts: BudgetAlerts { BudgetAlerts(defaults: defaults, calendar: TestDate.calendar) }

    // MARK: Pace

    @Test func paceOnThe26th() {
        let pace = BudgetPace(budget: 25_000, spent: 18_420, month: september,
                              now: TestDate.make(2026, 9, 26, 14), calendar: TestDate.calendar)
        #expect(pace.daysLeft == 5) // 26th to 30th
        #expect(pace.remaining == 6_580)
        #expect(pace.perDay == 1_316)
        #expect(!pace.isOver)
        #expect(abs(pace.progress - 0.7368) < 0.001)
    }

    @Test func paceOnTheLastDay() {
        let pace = BudgetPace(budget: 1_000, spent: 400, month: september,
                              now: TestDate.make(2026, 9, 30, 23, 59), calendar: TestDate.calendar)
        #expect(pace.daysLeft == 1)
        #expect(pace.perDay == 600)
    }

    @Test func overBudget() {
        let pace = BudgetPace(budget: 1_000, spent: 1_250, month: september,
                              now: TestDate.make(2026, 9, 10), calendar: TestDate.calendar)
        #expect(pace.isOver)
        #expect(pace.remaining == -250)
        #expect(pace.perDay == 0)
        #expect(pace.progress == 1.25)
    }

    // MARK: Alert levels

    @Test func levels() {
        #expect(BudgetAlerts.level(budget: 1000, spent: 799) == nil)
        #expect(BudgetAlerts.level(budget: 1000, spent: 800) == .nearly)
        #expect(BudgetAlerts.level(budget: 1000, spent: 999) == .nearly)
        #expect(BudgetAlerts.level(budget: 1000, spent: 1000) == .over)
        #expect(BudgetAlerts.level(budget: 0, spent: 5000) == nil)
    }

    @Test func alertsOnceAt80AndOnceAt100() {
        let month = TestDate.make(2026, 9, 10)
        #expect(alerts.check(budget: 1000, before: 700, after: 850, month: month)?.level == .nearly)
        #expect(alerts.check(budget: 1000, before: 850, after: 900, month: month) == nil) // already told
        #expect(alerts.check(budget: 1000, before: 900, after: 1100, month: month)?.level == .over)
        #expect(alerts.check(budget: 1000, before: 1100, after: 1500, month: month) == nil)
    }

    @Test func jumpingPast100AlertsOnlyFor100() {
        let alert = alerts.check(budget: 1000, before: 500, after: 1200, month: TestDate.make(2026, 9, 10))
        #expect(alert == BudgetAlerts.Alert(level: .over, budget: 1000, spent: 1200, month: TestDate.make(2026, 9, 10)))
        #expect(alerts.check(budget: 1000, before: 1200, after: 1300, month: TestDate.make(2026, 9, 11)) == nil)
    }

    @Test func noAlertWhenSpendingGoesDown() {
        #expect(alerts.check(budget: 1000, before: 1200, after: 900, month: TestDate.make(2026, 9, 10)) == nil)
    }

    @Test func aNewMonthStartsAfresh() {
        #expect(alerts.check(budget: 1000, before: 0, after: 900, month: TestDate.make(2026, 9, 10)) != nil)
        #expect(alerts.check(budget: 1000, before: 0, after: 900, month: TestDate.make(2026, 10, 3)) != nil)
    }

    @Test func resetForgetsWhatWasSent() {
        let month = TestDate.make(2026, 9, 10)
        _ = alerts.check(budget: 1000, before: 0, after: 900, month: month)
        alerts.reset()
        #expect(alerts.check(budget: 1000, before: 850, after: 900, month: month)?.level == .nearly)
    }

    @Test func messagesNameTheMonthAndAmounts() {
        let nearly = BudgetAlerts.message(for: .init(level: .nearly, budget: 25_000, spent: 20_500, month: TestDate.make(2026, 9, 10)),
                                          calendar: TestDate.calendar)
        #expect(nearly.title == "80% of your September budget is used")
        #expect(nearly.body.contains("₹4,500 left"))

        let over = BudgetAlerts.message(for: .init(level: .over, budget: 25_000, spent: 26_000, month: TestDate.make(2026, 9, 10)),
                                        calendar: TestDate.calendar)
        #expect(over.title == "You've gone over your September budget")
        #expect(over.body.contains("₹1,000 more"))
    }

    // MARK: Service

    @Test func serviceAlertsWhenASaveCrossesALevel() throws {
        let db = try TestDatabase()
        let food = try db.makeCategory("Food")
        let now = Date.now
        defaults.set(1000, forKey: SettingsKey.monthlyBudget)
        let service = BudgetService(context: db.context, defaults: defaults)

        try db.addExpense(700, to: food, on: now)
        let alert = try service.alert(now: now) { try db.addExpense(150, to: food, on: now) }

        #expect(alert?.level == .nearly)
        #expect(alert?.spent == 850)
    }

    @Test func serviceStaysQuietWithoutABudgetOrWithAlertsOff() throws {
        let db = try TestDatabase()
        let food = try db.makeCategory("Food")
        let service = BudgetService(context: db.context, defaults: defaults)

        #expect(try service.alert { try db.addExpense(5000, to: food) } == nil) // no budget

        defaults.set(1000, forKey: SettingsKey.monthlyBudget)
        defaults.set(false, forKey: SettingsKey.budgetAlerts)
        #expect(try service.alert { try db.addExpense(5000, to: food) } == nil)
    }

    @Test func serviceIgnoresExpensesInOtherMonths() throws {
        let db = try TestDatabase()
        let food = try db.makeCategory("Food")
        defaults.set(1000, forKey: SettingsKey.monthlyBudget)
        let service = BudgetService(context: db.context, defaults: defaults)
        let now = Date.now
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: now)!

        #expect(try service.alert(now: now) { try db.addExpense(5000, to: food, on: lastMonth) } == nil)
    }
}
