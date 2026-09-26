import SwiftData
import SwiftUI

/// Edit a category's name and emoji, move all its expenses elsewhere, or delete it once it's empty.
struct CategoryDetailView: View {
    let category: Category

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allCategories: [Category]

    @State private var name: String
    @State private var emoji: String
    @State private var moveTarget: Category?
    @State private var isConfirmingDelete = false
    @State private var errorMessage: String?

    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name)
        _emoji = State(initialValue: category.emoji)
    }

    private var expenseCount: Int { category.expenses.count }

    private var otherCategories: [Category] {
        CategoryService.sortedByUsage(allCategories.filter { $0.id != category.id })
    }

    private var hasChanges: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines) != category.name || emoji != category.emoji
    }

    private var canSave: Bool {
        hasChanges && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && CategoryService.isValidEmoji(emoji)
    }

    private var deleteBlockedReason: String? {
        if expenseCount > 0 {
            return CategoryError.inUse(expenseCount: expenseCount).errorDescription
        }
        if otherCategories.isEmpty {
            return CategoryError.lastCategory.errorDescription
        }
        return nil
    }

    var body: some View {
        Form {
            Section {
                CategoryFields(name: $name, emoji: $emoji)
            }
            .listRowBackground(Color.surface)

            if expenseCount > 0 {
                Section {
                    Menu {
                        ForEach(otherCategories) { target in
                            Button("\(target.emoji) \(target.name)") { moveTarget = target }
                        }
                    } label: {
                        Label(
                            "Move all \(expenseCount) \(expenseCount == 1 ? "expense" : "expenses") to…",
                            systemImage: "arrow.right.circle"
                        )
                    }
                    .disabled(otherCategories.isEmpty)
                }
                .listRowBackground(Color.surface)
            }

            Section {
                Button("Delete Category", role: .destructive) { isConfirmingDelete = true }
                    .disabled(deleteBlockedReason != nil)
            } footer: {
                if let deleteBlockedReason { Text(deleteBlockedReason) }
            }
            .listRowBackground(Color.surface)
        }
        .kokuList()
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Save", action: save)
                .disabled(!canSave)
        }
        .confirmationDialog(
            moveTitle,
            isPresented: .constant(moveTarget != nil),
            titleVisibility: .visible
        ) {
            Button("Move") { moveAll() }
            Button("Cancel", role: .cancel) { moveTarget = nil }
        }
        .confirmationDialog(
            "Delete \(category.emoji) \(category.name)?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: delete)
        }
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var moveTitle: String {
        guard let moveTarget else { return "" }
        let noun = expenseCount == 1 ? "expense" : "expenses"
        return "Move \(expenseCount) \(noun) from \(category.name) to \(moveTarget.emoji) \(moveTarget.name)?"
    }

    private func save() {
        run { try CategoryService(context: context).update(category, name: name, emoji: emoji) }
        name = category.name
        emoji = category.emoji
    }

    private func moveAll() {
        guard let moveTarget else { return }
        self.moveTarget = nil
        run { try CategoryService(context: context).moveAllExpenses(from: category, to: moveTarget) }
    }

    private func delete() {
        run {
            try CategoryService(context: context).delete(category)
            dismiss()
        }
    }

    private func run(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
