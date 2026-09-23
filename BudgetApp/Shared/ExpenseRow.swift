import SwiftUI

/// One expense in a list: category emoji, merchant, when, and amount.
struct ExpenseRow: View {
    let expense: Expense
    /// History already groups rows under a day heading, so it shows only the time.
    var showsDate = false

    var body: some View {
        HStack(spacing: 12) {
            Text(expense.category?.emoji ?? "❔")
                .font(.title2)
            VStack(alignment: .leading) {
                Text(expense.merchant)
                Text(expense.date, format: showsDate ? .dateTime.day().month().hour().minute() : .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(expense.amount.inr)
                .monospacedDigit()
        }
        .contentShape(.rect)
    }
}
