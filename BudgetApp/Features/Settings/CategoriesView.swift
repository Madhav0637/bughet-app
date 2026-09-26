import SwiftData
import SwiftUI

/// All categories, most-used first, with how many expenses each has.
struct CategoriesView: View {
    @Query private var categories: [Category]
    @State private var isAdding = false

    var body: some View {
        List {
            ForEach(CategoryService.sortedByUsage(categories)) { category in
                NavigationLink {
                    CategoryDetailView(category: category)
                } label: {
                    HStack(spacing: 12) {
                        EmojiTile(emoji: category.emoji, size: 38)
                        Text(category.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.ink)
                        Spacer()
                        Text(expenseCount(category))
                            .font(.subheadline)
                            .foregroundStyle(.ink2)
                    }
                }
            }
            .listRowBackground(Color.surface)
        }
        .kokuList()
        .navigationTitle("Categories")
        .toolbar {
            Button("Add Category", systemImage: "plus") { isAdding = true }
        }
        .sheet(isPresented: $isAdding) {
            CategoryFormView()
        }
    }

    private func expenseCount(_ category: Category) -> String {
        let count = category.expenses.count
        return "\(count) \(count == 1 ? "expense" : "expenses")"
    }
}
