import XCTest

/// Drives the real app on sample data (`-demoData`, an in-memory store) through the main flows.
@MainActor
final class KokuUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-demoData"]
        app.launch()
    }

    private func button(labelContaining text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func type(_ keys: [String]) {
        for key in keys { app.buttons[key].tap() }
    }

    /// Accepts the notification permission prompt if iOS shows it.
    private func allowNotificationsIfAsked() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 3) { allow.tap() }
    }

    func testAddingAnExpenseWithASuggestedMerchant() {
        app.buttons["addExpense"].tap()
        XCTAssertEqual(app.buttons["saveExpense"].label, "Enter an amount")

        type(["4", "3", "2", "1"])
        XCTAssertEqual(app.buttons["saveExpense"].label, "Add what it was for")

        let merchant = app.textFields["merchant"]
        merchant.tap()
        merchant.typeText("Zom")
        app.buttons["Zomato"].firstMatch.tap()

        // Zomato was last logged under Food, so the category is filled in.
        XCTAssertTrue(app.staticTexts["picked from Zomato"].waitForExistence(timeout: 2))
        let save = app.buttons["saveExpense"]
        XCTAssertEqual(save.label, "Save ₹4,321")
        save.tap()

        XCTAssertTrue(button(labelContaining: "₹4,321").waitForExistence(timeout: 3), "The new expense shows under Recent")
    }

    func testNewMerchantNeedsACategory() {
        app.buttons["addExpense"].tap()
        type(["9", "9"])
        let merchant = app.textFields["merchant"]
        merchant.tap()
        merchant.typeText("Corner Bakery\n")
        XCTAssertEqual(app.buttons["saveExpense"].label, "Pick a category")

        button(labelContaining: "Food").tap()
        XCTAssertEqual(app.buttons["saveExpense"].label, "Save ₹99")
        app.buttons["saveExpense"].tap()
        XCTAssertTrue(button(labelContaining: "Corner Bakery").waitForExistence(timeout: 3))
    }

    func testSwipeToDeleteAndUndo() {
        app.tabBars.buttons["Activity"].tap()
        // Expense rows read like "Zomato, Food · 9:39 PM, ₹336"; the category chips don't have a "·".
        let row = app.collectionViews.buttons.matching(NSPredicate(format: "label CONTAINS '·' AND label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        let label = row.label

        row.swipeLeft()
        let delete = app.buttons["Delete"]
        if delete.waitForExistence(timeout: 2) { delete.tap() } // a long swipe deletes straight away
        XCTAssertTrue(app.buttons["toastAction"].waitForExistence(timeout: 2), "Undo appears")
        XCTAssertFalse(app.buttons[label].exists, "The row is gone")

        app.buttons["toastAction"].tap()
        XCTAssertTrue(app.buttons[label].waitForExistence(timeout: 3), "Undo brings the row back")
    }

    func testDeletingFromTheEditSheetAndUndo() {
        app.swipeUp() // down to Recent
        let firstRecent = app.scrollViews.buttons.matching(NSPredicate(format: "label CONTAINS '·' AND label CONTAINS '₹'")).firstMatch
        XCTAssertTrue(firstRecent.waitForExistence(timeout: 3))
        let label = firstRecent.label
        firstRecent.tap()

        app.buttons["Delete expense"].tap()
        XCTAssertTrue(app.buttons["toastAction"].waitForExistence(timeout: 3), "Undo appears after the sheet closes")
        app.buttons["toastAction"].tap()
        XCTAssertTrue(app.buttons[label].waitForExistence(timeout: 3), "Undo brings it back")
    }

    func testFilteringActivityByCategory() {
        app.tabBars.buttons["Activity"].tap()
        button(labelContaining: "Transport").tap()
        let rows = app.collectionViews.cells.buttons
        XCTAssertTrue(rows.element(boundBy: 0).waitForExistence(timeout: 2))
        for index in 0..<min(rows.count, 6) {
            let label = rows.element(boundBy: index).label
            guard label.contains("·") else { continue } // skip the chips
            XCTAssertTrue(label.contains("Transport"), "Only transport shows: \(label)")
        }
    }

    func testInsightsPeriodNavigation() {
        app.tabBars.buttons["Insights"].tap()
        let thisMonth = Date.now.formatted(.dateTime.month(.wide).year())
        XCTAssertTrue(app.staticTexts[thisMonth].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Next month"].isEnabled, "Can't go into the future")

        app.buttons["Previous month"].tap()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: .now)!
        XCTAssertTrue(app.staticTexts[lastMonth.formatted(.dateTime.month(.wide).year())].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Next month"].isEnabled)

        app.buttons["Year"].tap()
        XCTAssertTrue(app.staticTexts[Date.now.formatted(.dateTime.year())].waitForExistence(timeout: 2),
                      "Switching period goes back to the current one")
        XCTAssertTrue(app.staticTexts["Month by month"].exists)
    }

    func testSettingABudget() {
        app.tabBars.buttons["Settings"].tap()
        button(labelContaining: "Monthly budget").tap()
        app.buttons["Delete"].press(forDuration: 0.8) // clears whatever was there
        type(["2", "5", "Double zero", "0"])
        app.buttons["Set budget · ₹25,000"].tap()
        allowNotificationsIfAsked()

        XCTAssertTrue(button(labelContaining: "₹25,000").waitForExistence(timeout: 3))
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(button(labelContaining: "budget").waitForExistence(timeout: 2), "Home shows the budget card")
        XCTAssertTrue(button(labelContaining: "left").exists || button(labelContaining: "over").exists)
    }

    func testThemeAndHighlight() {
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Dark"].tap()
        XCTAssertTrue(app.buttons["Dark"].isSelected)
        app.buttons["Coral"].tap()
        XCTAssertTrue(app.buttons["Coral"].isSelected)
        XCTAssertTrue(app.staticTexts["Coral"].exists)

        // Put things back for the next run.
        app.buttons["System"].tap()
        app.buttons["Mint"].tap()
        XCTAssertTrue(app.buttons["System"].isSelected)
    }
}
