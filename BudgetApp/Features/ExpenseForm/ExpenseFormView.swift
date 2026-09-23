import SwiftData
import SwiftUI

/// Adds a new expense, or edits an existing one. Save stays disabled until everything is valid.
struct ExpenseFormView: View {
    enum Mode: Identifiable {
        case add
        case edit(Expense)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let expense): expense.id.uuidString
            }
        }
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var merchant: String
    @State private var amountText: String
    @State private var category: Category?
    @State private var date: Date
    @State private var categories: [Category] = []
    @State private var errorMessage: String?
    @FocusState private var merchantFocused: Bool

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _merchant = State(initialValue: "")
            _amountText = State(initialValue: "")
            _category = State(initialValue: nil)
            _date = State(initialValue: .now)
        case .edit(let expense):
            _merchant = State(initialValue: expense.merchant)
            _amountText = State(initialValue: String(expense.amount))
            _category = State(initialValue: expense.category)
            _date = State(initialValue: expense.date)
        }
    }

    private var amount: Int? {
        guard let value = Int(amountText), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount != nil && category != nil
    }

    private var isAdding: Bool {
        if case .add = mode { true } else { false }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("On what?") {
                        TextField("Merchant", text: $merchant)
                            .multilineTextAlignment(.trailing)
                            .focused($merchantFocused)
                    }
                    LabeledContent("Amount (₹)") {
                        TextField("0", text: $amountText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Category", selection: $category) {
                        if category == nil {
                            Text("Choose").tag(Category?.none)
                        }
                        ForEach(categories) { category in
                            Text("\(category.emoji) \(category.name)").tag(Optional(category))
                        }
                    }
                    // New expenses are always dated "now"; the date can be changed later by editing.
                    if !isAdding {
                        DatePicker("Date", selection: $date)
                    }
                }
            }
            .navigationTitle(isAdding ? "Add Expense" : "Edit Expense")
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
            .onAppear { merchantFocused = isAdding }
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
        let service = ExpenseService(context: context)
        do {
            switch mode {
            case .add:
                try service.add(merchant: merchant, amount: amount, category: category)
            case .edit(let expense):
                try service.update(expense, merchant: merchant, amount: amount, category: category, date: date)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
