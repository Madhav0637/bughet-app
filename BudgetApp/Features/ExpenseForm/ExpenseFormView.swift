import SwiftData
import SwiftUI

/// Adds a new expense, or edits one. Amount first on the keypad, then "On what?" (recent merchants are one tap away
/// and bring their usual category with them), a category, and optionally a note and a different date.
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

    private enum Field { case merchant, note }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toasts
    @Environment(\.highlight) private var highlight
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @AppStorage(SettingsKey.monthlyBudget) private var monthlyBudget = 0

    @State private var merchant: String
    @State private var amountText: String
    @State private var categoryID: UUID?
    @State private var date: Date
    @State private var note: String
    @State private var showsNote: Bool
    /// The expense being edited, kept as an id so nothing reads the model after it's deleted.
    @State private var editingID: UUID?
    /// Once a category is tapped, merchant suggestions stop changing it.
    @State private var categoryChosenByHand: Bool
    /// The merchant whose usual category was filled in, for the "picked from Zomato" hint.
    @State private var categoryHint: String?
    @State private var categories: [Category] = []
    @State private var isPickingDate = false
    @State private var saved = false
    @State private var errorMessage: String?
    @FocusState private var focus: Field?

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _merchant = State(initialValue: "")
            _amountText = State(initialValue: "")
            _categoryID = State(initialValue: nil)
            _date = State(initialValue: .now)
            _note = State(initialValue: "")
            _showsNote = State(initialValue: false)
            _editingID = State(initialValue: nil)
            _categoryChosenByHand = State(initialValue: false)
        case .edit(let expense):
            _merchant = State(initialValue: expense.merchant)
            _amountText = State(initialValue: String(expense.amount))
            _categoryID = State(initialValue: expense.category?.id)
            _date = State(initialValue: expense.date)
            _note = State(initialValue: expense.note ?? "")
            _showsNote = State(initialValue: expense.note != nil)
            _editingID = State(initialValue: expense.id)
            _categoryChosenByHand = State(initialValue: true)
        }
    }

    private var isAdding: Bool { editingID == nil }

    private var amount: Int? {
        guard let value = Int(amountText), value > 0 else { return nil }
        return value
    }

    private var trimmedMerchant: String { merchant.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var category: Category? { categories.first { $0.id == categoryID } }
    private var canSave: Bool { amount != nil && !trimmedMerchant.isEmpty && category != nil }

    var body: some View {
        let suggestions = MerchantSuggestions(expenses: expenses)

        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 20)

            ScrollView {
                VStack(spacing: 20) {
                    amountDisplay
                    merchantField(suggestions: suggestions)
                    categoryPicker
                    noteField
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 10) {
                if focus == nil {
                    Keypad(text: $amountText)
                        .padding(.horizontal, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                saveButton
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 8)
        }
        .animation(.snappy(duration: 0.3), value: focus)
        .presentationBackground(Color.surface)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .interactiveDismissDisabled(saved)
        .task { categories = (try? CategoryService(context: context).categoriesByUsage()) ?? [] }
        .onChange(of: merchant) { fillCategory(from: suggestions) }
        .alert("Couldn't save", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Parts

    private var topBar: some View {
        ZStack {
            Text(isAdding ? "New expense" : "Edit expense")
                .font(.headline)
                .foregroundStyle(.ink)
            HStack(spacing: 8) {
                Button("Cancel") { dismiss() }
                    .font(.body.weight(.medium))
                    .foregroundStyle(.ink2)
                Spacer()
                if !isAdding {
                    Button(role: .destructive, action: deleteExpense) {
                        Image(systemName: "trash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.warning)
                            .frame(width: 36, height: 36)
                            .background(Color.surface2, in: .circle)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Delete expense")
                }
                datePill
            }
        }
    }

    private var datePill: some View {
        Button { isPickingDate = true } label: {
            HStack(spacing: 5) {
                Image(systemName: "calendar")
                Text(HistoryFilter.title(forDay: date))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.ink)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color.surface2, in: .capsule)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Date, \(date.formatted(date: .abbreviated, time: .shortened))")
        .popover(isPresented: $isPickingDate) {
            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding()
                .frame(width: 340)
                .presentationCompactAdaptation(.popover)
        }
    }

    private var amountDisplay: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("₹")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(.ink2)
                    Text(amount?.indianGrouped ?? "0")
                        .font(.system(size: 68, weight: .bold, design: .rounded))
                        .tracking(-1.5)
                        .monospacedDigit()
                        .foregroundStyle(amount == nil ? Color.ink3 : Color.ink)
                        .contentTransition(.numericText(value: Double(amount ?? 0)))
                }
                Caret(color: highlight.fill)
                    .opacity(focus == nil ? 1 : 0)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Amount")
            .accessibilityValue(amount?.inr ?? "none")
            .accessibilityIdentifier("amount")

            budgetCaption
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture { focus = nil }
    }

    @ViewBuilder
    private var budgetCaption: some View {
        let month = PeriodCalculator().range(of: .month)
        if monthlyBudget > 0, month.contains(date) {
            let spentElsewhere = expenses
                .filter { month.contains($0.date) && $0.id != editingID }
                .reduce(0) { $0 + $1.amount }
            let left = monthlyBudget - spentElsewhere - (amount ?? 0)
            HStack(spacing: 6) {
                Circle()
                    .fill(left >= 0 ? highlight.fill : Color.warning)
                    .frame(width: 6, height: 6)
                Text(left >= 0 ? "\(left.inr) left this month after this" : "\((-left).inr) over budget after this")
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(left)))
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.ink2)
        }
    }

    private func merchantField(suggestions: MerchantSuggestions) -> some View {
        let matches = suggestions.matching(merchant)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "storefront")
                    .foregroundStyle(.ink2)
                TextField("On what?", text: $merchant)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.ink)
                    .focused($focus, equals: .merchant)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { focus = nil }
                    .accessibilityIdentifier("merchant")
                if !merchant.isEmpty {
                    Button {
                        merchant = ""
                        if !categoryChosenByHand { categoryHint = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.ink3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear")
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.surface2, in: .rect(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 20)

            if !matches.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(matches) { suggestion in
                            Button { pick(suggestion) } label: {
                                Chip(title: suggestion.name, isSelected: false, restingBackground: .surface2)
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
                .transition(.opacity)
            }
        }
        .animation(.snappy, value: matches.map(\.id))
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Text("Category")
                if let categoryHint {
                    Image(systemName: "sparkles")
                        .foregroundStyle(highlight.text)
                    Text("picked from \(categoryHint)")
                        .lineLimit(1)
                }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.ink2)
            .padding(.horizontal, 20)
            .animation(.snappy, value: categoryHint)

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(categories) { item in
                            Button {
                                categoryChosenByHand = true
                                categoryHint = nil
                                withAnimation(.snappy) { categoryID = item.id }
                            } label: {
                                Chip(title: item.name, emoji: item.emoji, isSelected: categoryID == item.id,
                                     selectedStyle: .highlight, restingBackground: .surface2)
                            }
                            .buttonStyle(.pressable)
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
                .onChange(of: categoryID) {
                    guard let categoryID else { return }
                    withAnimation(.snappy) { proxy.scrollTo(categoryID, anchor: .center) }
                }
                .onChange(of: categories.map(\.id)) {
                    if let categoryID { proxy.scrollTo(categoryID, anchor: .center) }
                }
            }
            .sensoryFeedback(.selection, trigger: categoryID)
        }
    }

    @ViewBuilder
    private var noteField: some View {
        if showsNote {
            HStack(spacing: 10) {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.ink2)
                TextField("Add a note", text: $note)
                    .font(.body)
                    .foregroundStyle(.ink)
                    .focused($focus, equals: .note)
                    .submitLabel(.done)
                    .onSubmit { focus = nil }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.surface2, in: .rect(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 20)
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else {
            Button {
                withAnimation(.snappy) { showsNote = true }
                focus = .note
            } label: {
                Label("Add a note", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.ink2)
            }
            .buttonStyle(.pressable)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            HStack(spacing: 8) {
                if saved {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.heavy))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(saveTitle)
                    .contentTransition(.interpolate)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.onHighlight)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(highlight.fill.opacity(canSave || saved ? 1 : 0.35), in: .capsule)
        }
        .buttonStyle(.pressable)
        .disabled(!canSave || saved)
        .animation(.snappy, value: saveTitle)
        .sensoryFeedback(.success, trigger: saved)
        .accessibilityIdentifier("saveExpense")
    }

    /// Says what's still missing, then "Save ₹420".
    private var saveTitle: String {
        if saved { return "Saved" }
        guard let amount else { return "Enter an amount" }
        if trimmedMerchant.isEmpty { return "Add what it was for" }
        if category == nil { return "Pick a category" }
        return isAdding ? "Save \(amount.inr)" : "Save changes"
    }

    // MARK: Actions

    private func pick(_ suggestion: MerchantSuggestions.Suggestion) {
        merchant = suggestion.name
        focus = nil
    }

    /// When the merchant matches one used before, pick its usual category, unless one was chosen by hand.
    private func fillCategory(from suggestions: MerchantSuggestions) {
        guard !categoryChosenByHand,
              let id = suggestions.categoryID(for: merchant),
              categories.contains(where: { $0.id == id }) else { return }
        withAnimation(.snappy) {
            categoryID = id
            categoryHint = trimmedMerchant
        }
    }

    private func save() {
        guard let amount, let category else { return }
        let service = ExpenseService(context: context)
        do {
            let alert = try BudgetService(context: context).alert {
                switch mode {
                case .add:
                    try service.add(merchant: merchant, amount: amount, category: category, date: date, note: note)
                case .edit(let expense):
                    try service.update(expense, merchant: merchant, amount: amount, category: category, date: date, note: note)
                }
            }
            focus = nil
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { saved = true }
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                dismiss()
                if let alert {
                    toasts.show(BudgetAlerts.message(for: alert).title, systemImage: "exclamationmark.circle", duration: .seconds(5))
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteExpense() {
        guard case .edit(let expense) = mode else { return }
        let snapshot = ExpenseSnapshot(expense)
        do {
            try ExpenseService(context: context).delete(expense)
            dismiss()
            toasts.show("Deleted \(snapshot.merchant) · \(snapshot.amount.inr)", systemImage: "trash",
                        actionTitle: "Undo") { [context] in
                _ = try? ExpenseService(context: context).restore(snapshot)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// A blinking text cursor in the highlight colour.
struct Caret: View {
    let color: Color

    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: 3, height: 52)
            .phaseAnimator([1.0, 0.0]) { caret, opacity in
                caret.opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: 0.55)
            }
            .accessibilityHidden(true)
    }
}
