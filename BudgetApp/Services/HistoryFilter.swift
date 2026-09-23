import Foundation

/// The History screen's search, category filter and day grouping, kept free of UI code so it can be tested.
struct HistoryFilter {
    struct DayGroup: Identifiable {
        let day: Date
        let expenses: [Expense]

        var id: Date { day }
    }

    var searchText = ""
    var categoryID: UUID?

    var isActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || categoryID != nil
    }

    /// Merchant search ignores case and accents; it combines with the category filter.
    func apply(to expenses: [Expense]) -> [Expense] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return expenses.filter { expense in
            (query.isEmpty || expense.merchant.localizedStandardContains(query))
                && (categoryID == nil || expense.category?.id == categoryID)
        }
    }

    /// Newest day first, and newest expense first within each day.
    static func groupByDay(_ expenses: [Expense], calendar: Calendar = .current) -> [DayGroup] {
        let byDay = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        return byDay.keys.sorted(by: >).map { day in
            DayGroup(day: day, expenses: byDay[day, default: []].sorted { $0.date > $1.date })
        }
    }

    /// "Today", "Yesterday", or a date like "Mon, 21 Sep" (with the year if it isn't this year).
    static func title(forDay day: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        var style = Date.FormatStyle(date: .omitted, time: .omitted, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.abbreviated).day().month(.abbreviated)
        if !calendar.isDate(day, equalTo: now, toGranularity: .year) {
            style = style.year()
        }
        return day.formatted(style)
    }
}
