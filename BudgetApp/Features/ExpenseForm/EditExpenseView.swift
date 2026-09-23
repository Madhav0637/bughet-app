import SwiftData
import SwiftUI

/// Edit an expense's merchant, amount, category and date. Save stays disabled until everything is valid.
struct EditExpenseView: View {
    let expense: Expense

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var merchant: String
    @State private var amountText: String
    @State private var category: Category?
    @State private var date: Date
    @State private var categories: [Category] = []
    @State private var errorMessage: String?

    init(expense: Expense) {
        self.expense = expense
        _merchant = State(initialValue: expense.merchant)
        _amountText = State(initialValue: String(expense.amount))
        _category = State(initialValue: expense.category)
        _date = State(initialValue: expense.date)
    }

    private var amount: Int? {
        guard let value = Int(amountText), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount != nil && category != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("On what?") {
                        TextField("Merchant", text: $merchant)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Amount (₹)") {
                        TextField("0", text: $amountText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(categories) { category in
                            Text("\(category.emoji) \(category.name)").tag(Optional(category))
                        }
                    }
                    DatePicker("Date", selection: $date)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .task { categories = (try? CategoryService(context: context).categoriesByUsage()) ?? [] }
            .alert("Couldn't save", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        guard let amount, let category else { return }
        do {
            try ExpenseService(context: context).update(
                expense, merchant: merchant, amount: amount, category: category, date: date
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
