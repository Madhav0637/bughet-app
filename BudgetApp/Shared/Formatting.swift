import Foundation

extension Int {
    /// Whole rupees with Indian digit grouping, e.g. ₹1,23,456.
    var inr: String {
        formatted(.currency(code: "INR").precision(.fractionLength(0)).locale(Locale(identifier: "en_IN")))
    }

    /// Indian digit grouping without the ₹, e.g. 1,23,456. Used where the ₹ is drawn separately.
    var indianGrouped: String {
        formatted(.number.precision(.fractionLength(0)).locale(Locale(identifier: "en_IN")))
    }

    /// "1 expense", "3 expenses".
    func counted(_ singular: String, _ plural: String? = nil) -> String {
        "\(self) \(self == 1 ? singular : plural ?? singular + "s")"
    }
}

extension Date {
    /// For rows not grouped under a day heading: the time today, "Yesterday", or a date like "21 Sep".
    func dayOrTime(now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(self, inSameDayAs: now) {
            return formatted(Date.FormatStyle(date: .omitted, time: .shortened, calendar: calendar, timeZone: calendar.timeZone))
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(self, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        var style = Date.FormatStyle(calendar: calendar, timeZone: calendar.timeZone).day().month(.abbreviated)
        if !calendar.isDate(self, equalTo: now, toGranularity: .year) { style = style.year() }
        return formatted(style)
    }
}

extension Period {
    /// Label on the period pickers.
    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }

    /// Used in sentences such as "Spent this month".
    var phrase: String {
        switch self {
        case .week: "this week"
        case .month: "this month"
        case .year: "this year"
        }
    }

    /// The Home period menu: "This month".
    var menuTitle: String {
        switch self {
        case .week: "This week"
        case .month: "This month"
        case .year: "This year"
        }
    }

    /// Used in "vs same time last month".
    var previousPhrase: String {
        switch self {
        case .week: "last week"
        case .month: "last month"
        case .year: "last year"
        }
    }
}
