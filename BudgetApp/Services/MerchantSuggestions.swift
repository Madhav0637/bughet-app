import Foundation

/// Merchants logged before, offered as one-tap suggestions in Add Expense, with the category each was last used with.
struct MerchantSuggestions {
    struct Suggestion: Identifiable, Equatable {
        let name: String
        let categoryID: UUID?

        var id: String { MerchantSuggestions.key(for: name) }
    }

    /// Unique merchants (ignoring case and surrounding spaces), most recently used first.
    let all: [Suggestion]

    init(expenses: [Expense]) {
        var seen = Set<String>()
        var all: [Suggestion] = []
        for expense in expenses.sorted(by: { $0.date > $1.date }) {
            let key = Self.key(for: expense.merchant)
            guard !key.isEmpty, seen.insert(key).inserted else { continue }
            all.append(Suggestion(name: expense.merchant, categoryID: expense.category?.id))
        }
        self.all = all
    }

    /// With nothing typed, the most recent merchants. Otherwise merchants containing the text (ignoring case and
    /// accents), those starting with it first, leaving out one that already matches exactly.
    func matching(_ text: String, limit: Int = 8) -> [Suggestion] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return Array(all.prefix(limit)) }
        let key = Self.key(for: query)
        let matches = all.filter { $0.id != key && $0.name.localizedStandardContains(query) }
        let startsWith = matches.filter { $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .hasPrefix(query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)) }
        let others = matches.filter { !startsWith.contains($0) }
        return Array((startsWith + others).prefix(limit))
    }

    /// The category this merchant was most recently logged under, or nil for a new merchant.
    func categoryID(for merchant: String) -> UUID? {
        let key = Self.key(for: merchant)
        return all.first { $0.id == key }?.categoryID
    }

    /// How merchant names are compared: trimmed and lowercased.
    static func key(for merchant: String) -> String {
        merchant.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
