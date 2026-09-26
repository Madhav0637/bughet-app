import Foundation

enum Period: String, CaseIterable, Identifiable {
    case week, month, year

    var id: Self { self }

    var calendarComponent: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }
}

/// Date ranges for the dashboard's periods. Weeks start on Monday, months on the 1st.
struct PeriodCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        var calendar = calendar
        calendar.firstWeekday = 2 // Monday
        self.calendar = calendar
    }

    /// The period containing `date`, from its first instant up to (not including) the next period's first instant.
    func range(of period: Period, containing date: Date = .now) -> Range<Date> {
        guard let interval = calendar.dateInterval(of: period.calendarComponent, for: date) else {
            fatalError("The calendar has no \(period) containing \(date)")
        }
        return interval.start..<interval.end
    }

    /// The period `offset` steps away from the one containing `date`: -1 is last week, month or year.
    func range(of period: Period, offset: Int, from date: Date = .now) -> Range<Date> {
        let current = range(of: period, containing: date)
        guard offset != 0,
              let shifted = calendar.date(byAdding: period.calendarComponent, value: offset, to: current.lowerBound) else {
            return current
        }
        return range(of: period, containing: shifted)
    }

    /// The start of the previous period up to the same point `now` has reached in the current one.
    /// On 26 Sep at 14:00 that's 1 Aug 00:00 to 26 Aug 14:00, so a month in progress is compared fairly.
    /// It never runs past the end of the previous period (31 Mar is compared with the whole of February).
    func samePointInPreviousPeriod(of period: Period, now: Date = .now) -> Range<Date> {
        let current = range(of: period, containing: now)
        let previous = range(of: period, offset: -1, from: now)
        let elapsed = calendar.dateComponents([.day, .hour, .minute, .second], from: current.lowerBound, to: now)
        let end = calendar.date(byAdding: elapsed, to: previous.lowerBound) ?? previous.upperBound
        return previous.lowerBound..<min(end, previous.upperBound)
    }

    /// The first instant of every day in `range`.
    func days(in range: Range<Date>) -> [Date] {
        var days: [Date] = []
        var day = calendar.startOfDay(for: range.lowerBound)
        while day < range.upperBound {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }
}
