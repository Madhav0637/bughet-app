import SwiftData
import SwiftUI

/// Milestone 1: a plain list to confirm Back Tap entries are saved. Becomes the History tab in Milestone 3.
struct ExpenseListView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    var body: some View {
        NavigationStack {
            List(expenses) { expense in
                ExpenseRow(expense: expense)
            }
            .overlay {
                if expenses.isEmpty {
                    ContentUnavailableView(
                        "No Expenses Yet",
                        systemImage: "indianrupeesign.circle",
                        description: Text("Double-tap the back of your iPhone to add one.")
                    )
                }
            }
            .navigationTitle("Expenses")
        }
    }
}

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            Text(expense.category?.emoji ?? "❔")
                .font(.title2)
            VStack(alignment: .leading) {
                Text(expense.merchant)
                Text(expense.date, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(expense.amount.inr)
                .monospacedDigit()
        }
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: [Expense.self, Category.self], inMemory: true)
}
