import SwiftUI

/// One expense in a list: category emoji, merchant, category and when, an optional note, and the amount.
struct ExpenseRow: View {
    let expense: Expense
    /// Activity already groups rows under a day heading, so it shows only the time.
    var showsDay = false

    var body: some View {
        HStack(spacing: 12) {
            EmojiTile(emoji: expense.category?.emoji ?? "❔")
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchant)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.ink)
                    .lineLimit(1)
                Text(details)
                    .font(.footnote)
                    .foregroundStyle(.ink2)
                    .lineLimit(1)
            }
            // Lines up list separators with the text rather than the tile.
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            Spacer(minLength: 8)
            Text(expense.amount.inr)
                .font(.body.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.ink)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private var details: AttributedString {
        let when = showsDay
            ? expense.date.dayOrTime()
            : expense.date.formatted(date: .omitted, time: .shortened)
        var text = AttributedString([expense.category?.name, when].compactMap { $0 }.joined(separator: " · "))
        if let note = expense.note {
            var noteText = AttributedString(" · \(note)")
            noteText.inlinePresentationIntent = .emphasized
            text += noteText
        }
        return text
    }
}
