import Foundation

/// What the dashboard shows for one period: the total, spending per category, and the latest expenses.
struct SpendingSummary {
    struct CategoryTotal {
        let category: Category
        let amount: Int
        /// How many expenses make up the amount.
        let count: Int
    }

    let total: Int
    /// Highest amount first; ties sorted by category name. Categories with no spending are left out.
    let categoryTotals: [CategoryTotal]
    /// Newest first.
    let recent: [Expense]
    /// Every expense in the period, in no particular order.
    let expenses: [Expense]

    init(expenses: [Expense], in range: Range<Date>, recentLimit: Int = 5) {
        let inPeriod = expenses.filter { range.contains($0.date) }
        self.expenses = inPeriod

        total = inPeriod.reduce(0) { $0 + $1.amount }

        var amounts: [UUID: (category: Category, amount: Int, count: Int)] = [:]
        for expense in inPeriod {
            guard let category = expense.category else { continue }
            amounts[category.id, default: (category, 0, 0)].amount += expense.amount
            amounts[category.id, default: (category, 0, 0)].count += 1
        }
        categoryTotals = amounts.values
            .map { CategoryTotal(category: $0.category, amount: $0.amount, count: $0.count) }
            .sorted { lhs, rhs in
                if lhs.amount != rhs.amount { return lhs.amount > rhs.amount }
                return lhs.category.name.localizedCaseInsensitiveCompare(rhs.category.name) == .orderedAscending
            }

        recent = Array(inPeriod.sorted { $0.date > $1.date }.prefix(recentLimit))
    }

    /// This category's share of the total, from 0 to 1.
    func share(of item: CategoryTotal) -> Double {
        total > 0 ? Double(item.amount) / Double(total) : 0
    }
}
