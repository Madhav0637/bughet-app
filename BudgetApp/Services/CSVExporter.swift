import Foundation

/// Turns expenses into a CSV file that opens cleanly in Excel, Numbers or Google Sheets.
enum CSVExporter {
    static let header = "Date,Merchant,Category,Amount"

    /// Oldest expense first. Dates are `yyyy-MM-dd HH:mm` in the given time zone; amounts are plain whole rupees.
    static func csv(for expenses: [Expense], timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        var lines = [header]
        for expense in expenses.sorted(by: { $0.date < $1.date }) {
            lines.append(row(for: expense, formatter: formatter))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func row(for expense: Expense, formatter: DateFormatter) -> String {
        let fields: [String] = [
            formatter.string(from: expense.date),
            escape(expense.merchant),
            escape(expense.category?.name ?? ""),
            String(expense.amount),
        ]
        return fields.joined(separator: ",")
    }

    /// Quotes a field when it contains a comma, quote or line break (doubling any quotes inside it).
    /// Text starting with = + - or @ gets a leading apostrophe so spreadsheets don't run it as a formula.
    static func escape(_ field: String) -> String {
        var field = field
        if let first = field.first, "=+-@".contains(first) {
            field = "'" + field
        }
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
