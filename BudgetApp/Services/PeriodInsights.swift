import Foundation

/// Everything the Insights tab shows for one week, month or year.
struct PeriodInsights {
    /// Spending in one bar of the chart: a day, or a month when looking at a whole year.
    struct Bucket: Identifiable, Equatable {
        let start: Date
        let amount: Int

        var id: Date { start }
    }

    /// One merchant's spending in the period. Names are matched ignoring case and surrounding spaces.
    struct Merchant: Identifiable, Equatable {
        /// The spelling used most recently.
        let name: String
        /// The emoji of the category it was most recently logged under.
        let emoji: String
        let amount: Int
        let count: Int

        var id: String { MerchantSuggestions.key(for: name) }
    }

    let range: Range<Date>
    let total: Int
    let count: Int
    /// Covers the whole period, including days that haven't happened yet (they're zero).
    let buckets: [Bucket]
    let bucketsAreMonths: Bool
    let categoryTotals: [SpendingSummary.CategoryTotal]
    /// The single largest expense; the most recent one wins a tie.
    let biggest: Expense?
    /// Highest total first.
    let topMerchants: [Merchant]
    /// The merchant visited most often; the higher total wins a tie.
    let mostFrequent: Merchant?
    /// Days of the period so far, counting today. The whole period once it's over; zero if it hasn't started.
    let elapsedDays: Int
    /// Days so far with nothing spent.
    let noSpendDays: Int
    /// Total divided by the days so far, rounded to the nearest rupee.
    let averagePerDay: Int
    /// The average bar height so far: per day, or per month for a year.
    let averagePerBucket: Int

    init(expenses: [Expense], period: Period, range: Range<Date>, now: Date = .now,
         calculator: PeriodCalculator = PeriodCalculator()) {
        let calendar = calculator.calendar
        let summary = SpendingSummary(expenses: expenses, in: range)
        let inPeriod = summary.expenses
        self.range = range
        total = summary.total
        count = inPeriod.count
        categoryTotals = summary.categoryTotals

        // Bars
        bucketsAreMonths = period == .year
        let bucketStarts: [Date] = if bucketsAreMonths {
            (0..<12).compactMap { calendar.date(byAdding: .month, value: $0, to: range.lowerBound) }
                .filter { range.contains($0) }
        } else {
            calculator.days(in: range)
        }
        let bucketComponent: Calendar.Component = bucketsAreMonths ? .month : .day
        var amountsByBucket: [Date: Int] = [:]
        for expense in inPeriod {
            guard let start = calendar.dateInterval(of: bucketComponent, for: expense.date)?.start else { continue }
            amountsByBucket[start, default: 0] += expense.amount
        }
        buckets = bucketStarts.map { Bucket(start: $0, amount: amountsByBucket[$0] ?? 0) }

        // Days so far
        let end = min(now, range.upperBound)
        let elapsed = calculator.days(in: range).filter { $0 < end }
        elapsedDays = elapsed.count
        let daysWithSpending = Set(inPeriod.map { calendar.startOfDay(for: $0.date) })
        noSpendDays = elapsed.filter { !daysWithSpending.contains($0) }.count
        averagePerDay = Self.rounded(total, dividedBy: elapsedDays)
        let elapsedBuckets = bucketsAreMonths ? bucketStarts.filter { $0 < end }.count : elapsedDays
        averagePerBucket = Self.rounded(total, dividedBy: elapsedBuckets)

        // Biggest expense
        biggest = inPeriod.max { lhs, rhs in
            lhs.amount != rhs.amount ? lhs.amount < rhs.amount : lhs.date < rhs.date
        }

        // Merchants
        var merchants: [String: (latest: Expense, amount: Int, count: Int)] = [:]
        for expense in inPeriod {
            let key = MerchantSuggestions.key(for: expense.merchant)
            if var entry = merchants[key] {
                entry.amount += expense.amount
                entry.count += 1
                if expense.date > entry.latest.date { entry.latest = expense }
                merchants[key] = entry
            } else {
                merchants[key] = (expense, expense.amount, 1)
            }
        }
        let all: [Merchant] = merchants.values.map { entry in
            let emoji: String = entry.latest.category?.emoji ?? "❔"
            return Merchant(name: entry.latest.merchant, emoji: emoji, amount: entry.amount, count: entry.count)
        }
        topMerchants = all.sorted { lhs, rhs in
            if lhs.amount != rhs.amount { return lhs.amount > rhs.amount }
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        mostFrequent = all.max { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count < rhs.count }
            if lhs.amount != rhs.amount { return lhs.amount < rhs.amount }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
        }
    }

    /// The bar with the most spending, or nil when nothing was spent.
    var peak: Bucket? {
        buckets.filter { $0.amount > 0 }.max { $0.amount < $1.amount }
    }

    /// Spending on each of the last `count` days, ending with today.
    static func lastDays(_ count: Int, expenses: [Expense], now: Date = .now,
                         calculator: PeriodCalculator = PeriodCalculator()) -> [Bucket] {
        let calendar = calculator.calendar
        let today = calendar.startOfDay(for: now)
        guard let first = calendar.date(byAdding: .day, value: -(count - 1), to: today),
              let end = calendar.date(byAdding: .day, value: 1, to: today) else { return [] }
        var amounts: [Date: Int] = [:]
        for expense in expenses where (first..<end).contains(expense.date) {
            amounts[calendar.startOfDay(for: expense.date), default: 0] += expense.amount
        }
        return calculator.days(in: first..<end).map { Bucket(start: $0, amount: amounts[$0] ?? 0) }
    }

    private static func rounded(_ total: Int, dividedBy count: Int) -> Int {
        count > 0 ? Int((Double(total) / Double(count)).rounded()) : 0
    }
}

/// Compares a period's spending with the one before it. While a period is still running, it's compared with the
/// same stretch of the previous one (1–26 Sep against 1–26 Aug), so half a month isn't measured against a whole one.
struct PeriodComparison {
    let current: Int
    let previous: Int
    /// True for the period that's still running, where only the same stretch of the previous period counts.
    let isPartial: Bool

    init(expenses: [Expense], period: Period, offset: Int = 0, now: Date = .now,
         calculator: PeriodCalculator = PeriodCalculator()) {
        let currentRange = calculator.range(of: period, offset: offset, from: now)
        isPartial = currentRange.contains(now)
        let previousRange = isPartial
            ? calculator.samePointInPreviousPeriod(of: period, now: now)
            : calculator.range(of: period, offset: offset - 1, from: now)
        var current = 0
        var previous = 0
        for expense in expenses {
            if currentRange.contains(expense.date) { current += expense.amount }
            if previousRange.contains(expense.date) { previous += expense.amount }
        }
        self.current = current
        self.previous = previous
    }

    /// The change as a fraction: -0.12 means 12% less. Nil when nothing was spent in the previous period.
    var change: Double? {
        previous > 0 ? Double(current - previous) / Double(previous) : nil
    }
}
