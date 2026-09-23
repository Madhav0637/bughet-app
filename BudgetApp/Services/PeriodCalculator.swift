import Foundation

enum Period: String, CaseIterable, Identifiable {
    case week, month, year

    var id: Self { self }
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
        let component: Calendar.Component = switch period {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
        guard let interval = calendar.dateInterval(of: component, for: date) else {
            fatalError("The calendar has no \(period) containing \(date)")
        }
        return interval.start..<interval.end
    }
}
