import SwiftData
import SwiftUI

/// Sets, changes or removes the monthly budget, on the same keypad as Add Expense.
struct BudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.highlight) private var highlight
    @AppStorage(SettingsKey.monthlyBudget) private var monthlyBudget = 0
    @AppStorage(SettingsKey.budgetAlerts) private var alertsOn = true
    @Query private var expenses: [Expense]

    @State private var amountText = ""

    private let presets = [5_000, 10_000, 15_000, 20_000, 25_000, 30_000, 50_000]

    private var amount: Int? {
        guard let value = Int(amountText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Monthly budget")
                    .font(.headline)
                    .foregroundStyle(.ink)
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.body.weight(.medium))
                        .foregroundStyle(.ink2)
                    Spacer()
                    if monthlyBudget > 0 {
                        Button("Remove", role: .destructive, action: remove)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.warning)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer(minLength: 12)

            VStack(spacing: 10) {
                HStack(alignment: .center, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("₹")
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                            .foregroundStyle(.ink2)
                        Text(amount?.indianGrouped ?? "0")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .tracking(-1.5)
                            .monospacedDigit()
                            .foregroundStyle(amount == nil ? Color.ink3 : Color.ink)
                            .contentTransition(.numericText(value: Double(amount ?? 0)))
                    }
                    Caret(color: highlight.fill)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 20)

                Text(hint)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.ink2)
                    .monospacedDigit()
            }

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            withAnimation(.snappy) { amountText = String(preset) }
                        } label: {
                            Chip(title: preset.inr, isSelected: amount == preset, restingBackground: .surface2)
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 20)

            Spacer(minLength: 12)

            Keypad(text: $amountText)
                .padding(.horizontal, 12)

            Button(action: save) {
                Text(amount.map { "Set budget · \($0.inr)" } ?? "Enter an amount")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.onHighlight)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(highlight.fill.opacity(amount == nil ? 0.35 : 1), in: .capsule)
            }
            .buttonStyle(.pressable)
            .disabled(amount == nil)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .presentationBackground(Color.surface)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .onAppear { amountText = monthlyBudget > 0 ? String(monthlyBudget) : "" }
    }

    /// Last month's total, as a guide.
    private var hint: String {
        let lastMonth = PeriodCalculator().range(of: .month, offset: -1)
        let spent = expenses.filter { lastMonth.contains($0.date) }.reduce(0) { $0 + $1.amount }
        guard spent > 0 else { return "What you plan to spend in a month" }
        return "Last month you spent \(spent.inr)"
    }

    private func save() {
        guard let amount else { return }
        monthlyBudget = amount
        BudgetAlerts().reset()
        if alertsOn {
            Task { await BudgetNotifier.requestPermission() }
        }
        dismiss()
    }

    private func remove() {
        monthlyBudget = 0
        BudgetAlerts().reset()
        dismiss()
    }
}
