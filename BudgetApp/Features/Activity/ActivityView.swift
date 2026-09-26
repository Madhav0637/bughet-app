import SwiftData
import SwiftUI

/// Every expense, grouped by day with each day's total. Search by merchant, filter by category,
/// swipe to delete (with undo), tap to edit.
struct ActivityView: View {
    @Environment(\.modelContext) private var context
    @Environment(ToastCenter.self) private var toasts
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var categories: [Category]

    @State private var filter = HistoryFilter()
    @State private var form: ExpenseFormView.Mode?

    var body: some View {
        let groups = HistoryFilter.groupByDay(filter.apply(to: expenses))

        NavigationStack {
            List {
                if !expenses.isEmpty {
                    Section {
                        categoryChips
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }

                ForEach(groups) { group in
                    Section {
                        ForEach(group.expenses) { expense in
                            Button { form = .edit(expense) } label: {
                                ExpenseRow(expense: expense)
                            }
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) { delete(expense) }
                            }
                        }
                    } header: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(HistoryFilter.title(forDay: group.day))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.ink)
                            Spacer()
                            Text(group.total.inr)
                                .font(.subheadline)
                                .monospacedDigit()
                                .foregroundStyle(.ink2)
                        }
                        .textCase(nil)
                    }
                    .listRowBackground(Color.surface)
                    .listRowSeparatorTint(Color.hairline)
                }
            }
            .listSectionSpacing(18)
            .kokuList()
            .contentMargins(.bottom, 90, for: .scrollContent)
            .overlay { emptyState(hasResults: !groups.isEmpty) }
            .animation(.snappy, value: filter.categoryID)
            .navigationTitle("Activity")
            .searchable(text: $filter.searchText, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search merchants")
            .overlay(alignment: .bottom) { FloatingActions { form = .add } }
            .sheet(item: $form) { ExpenseFormView(mode: $0) }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(title: "All", emoji: nil, id: nil)
                ForEach(CategoryService.sortedByUsage(categories)) { category in
                    chip(title: category.name, emoji: category.emoji, id: category.id)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: filter.categoryID)
    }

    private func chip(title: String, emoji: String?, id: UUID?) -> some View {
        Button {
            withAnimation(.snappy) { filter.categoryID = id }
        } label: {
            Chip(title: title, emoji: emoji, isSelected: filter.categoryID == id)
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private func emptyState(hasResults: Bool) -> some View {
        if expenses.isEmpty {
            ContentUnavailableView {
                Label("No expenses yet", systemImage: "list.bullet.rectangle.portrait")
            } description: {
                Text("Tap + to log one, or double-tap the back of your iPhone.")
            }
        } else if !hasResults {
            ContentUnavailableView {
                Label("Nothing matches", systemImage: "magnifyingglass")
            } description: {
                Text("Try a different search or category.")
            }
        }
    }

    private func delete(_ expense: Expense) {
        let snapshot = ExpenseSnapshot(expense)
        do {
            try ExpenseService(context: context).delete(expense)
            toasts.show("Deleted \(snapshot.merchant) · \(snapshot.amount.inr)", systemImage: "trash",
                        actionTitle: "Undo") { [context] in
                _ = try? ExpenseService(context: context).restore(snapshot)
            }
        } catch {
            toasts.show("Couldn't delete: \(error.localizedDescription)", systemImage: "exclamationmark.circle")
        }
    }
}
