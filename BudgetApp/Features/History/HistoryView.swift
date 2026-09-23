import SwiftData
import SwiftUI

/// Every expense, grouped by day. Search by merchant, filter by category, swipe to delete, tap to edit.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var filter = HistoryFilter()
    @State private var editing: Expense?
    @State private var errorMessage: String?

    private var groups: [HistoryFilter.DayGroup] {
        HistoryFilter.groupByDay(filter.apply(to: expenses))
    }

    private var selectedCategory: Category? {
        categories.first { $0.id == filter.categoryID }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    Section(HistoryFilter.title(forDay: group.day)) {
                        ForEach(group.expenses) { expense in
                            Button { editing = expense } label: {
                                ExpenseRow(expense: expense)
                            }
                            .tint(.primary)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    delete(expense)
                                }
                            }
                        }
                    }
                }
            }
            .overlay { emptyState }
            .navigationTitle("History")
            .searchable(text: $filter.searchText, prompt: "Search merchants")
            .toolbar { categoryMenu }
            .sheet(item: $editing) { expense in
                EditExpenseView(expense: expense)
            }
            .alert("Couldn't delete", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if expenses.isEmpty {
            ContentUnavailableView(
                "No Expenses Yet",
                systemImage: "indianrupeesign.circle",
                description: Text("Double-tap the back of your iPhone to add one.")
            )
        } else if groups.isEmpty {
            ContentUnavailableView(
                "No Matching Expenses",
                systemImage: "magnifyingglass",
                description: Text("Try a different search or category.")
            )
        }
    }

    private var categoryMenu: some View {
        Menu {
            Picker("Category", selection: $filter.categoryID) {
                Text("All Categories").tag(UUID?.none)
                ForEach(categories) { category in
                    Text("\(category.emoji) \(category.name)").tag(Optional(category.id))
                }
            }
        } label: {
            if let selectedCategory {
                Text(selectedCategory.emoji)
            } else {
                Label("Filter", systemImage: "line.3.horizontal.decrease")
            }
        }
    }

    private func delete(_ expense: Expense) {
        do {
            try ExpenseService(context: context).delete(expense)
        } catch {
            errorMessage = error.localizedDescription
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
                Text(expense.date, format: .dateTime.hour().minute())
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

#Preview {
    HistoryView()
        .modelContainer(for: [Expense.self, Category.self], inMemory: true)
}
