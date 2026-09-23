import SwiftData
import SwiftUI

/// Spending for the current week, month or year: the total, each category, and the latest expenses.
struct DashboardView: View {
    /// Switches to the History tab.
    var onSeeAll: () -> Void = {}

    @Query private var expenses: [Expense]
    @AppStorage("dashboardPeriod") private var period = Period.month

    @State private var form: ExpenseFormView.Mode?

    private var summary: SpendingSummary {
        SpendingSummary(expenses: expenses, in: PeriodCalculator().range(of: period))
    }

    var body: some View {
        let summary = summary

        NavigationStack {
            List {
                Section {
                    Picker("Period", selection: $period) {
                        ForEach(Period.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    VStack(spacing: 4) {
                        Text("Spent \(period.phrase)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(summary.total.inr)
                            .font(.system(size: 48, weight: .bold))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                if summary.total == 0 {
                    ContentUnavailableView(
                        "No Expenses \(period.phrase.capitalized)",
                        systemImage: "indianrupeesign.circle",
                        description: Text("Double-tap the back of your iPhone to add one.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section("By Category") {
                        ForEach(summary.categoryTotals, id: \.category.id) { item in
                            HStack(spacing: 12) {
                                Text(item.category.emoji)
                                    .font(.title2)
                                Text(item.category.name)
                                Spacer()
                                Text(item.amount.inr)
                                    .monospacedDigit()
                            }
                        }
                    }

                    Section {
                        ForEach(summary.recent) { expense in
                            Button { form = .edit(expense) } label: {
                                ExpenseRow(expense: expense, showsDate: true)
                            }
                            .tint(.primary)
                        }
                    } header: {
                        HStack {
                            Text("Recent")
                            Spacer()
                            Button("See All", action: onSeeAll)
                                .font(.subheadline)
                                .textCase(nil)
                        }
                    }
                }
            }
            .animation(.default, value: period)
            .navigationTitle("Dashboard")
            .toolbar {
                Button("Add Expense", systemImage: "plus") { form = .add }
            }
            .sheet(item: $form) { mode in
                ExpenseFormView(mode: mode)
            }
        }
    }
}

extension Period {
    /// Label on the segmented control.
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
}

#Preview {
    DashboardView()
        .modelContainer(for: [Expense.self, Category.self], inMemory: true)
}
