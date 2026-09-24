import UIKit

/// A printable A4 report: title, date range, total, spending by category, and a table of every expense.
enum PDFReport {
    private static let page = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 in points
    private static let margin: CGFloat = 40
    private static let rowHeight: CGFloat = 20

    /// Table columns: where each starts, and how wide it is. Amount is right-aligned to the margin.
    private static let dateColumn = (x: margin, width: CGFloat(120))
    private static let merchantColumn = (x: margin + 125, width: CGFloat(200))
    private static let categoryColumn = (x: margin + 330, width: CGFloat(110))

    static func data(for expenses: [Expense], generatedAt: Date = .now, timeZone: TimeZone = .current) -> Data {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let summary = SpendingSummary(expenses: expenses, in: Date.distantPast..<Date.distantFuture)
        let sorted = expenses.sorted { $0.date < $1.date }

        let renderer = UIGraphicsPDFRenderer(bounds: page, format: {
            let format = UIGraphicsPDFRendererFormat()
            format.documentInfo = [kCGPDFContextTitle as String: "BudgetApp Expense Report"]
            return format
        }())

        return renderer.pdfData { context in
            var pageNumber = 0
            var y: CGFloat = 0

            func startPage() {
                context.beginPage()
                pageNumber += 1
                y = margin
                draw("Page \(pageNumber)", font: .systemFont(ofSize: 9), color: .secondaryLabel,
                     in: CGRect(x: margin, y: page.height - margin + 12, width: page.width - 2 * margin, height: 12),
                     alignment: .right)
            }

            /// Starts a new page if the next `height` points wouldn't fit.
            func ensureSpace(_ height: CGFloat) -> Bool {
                guard y + height > page.height - margin else { return false }
                startPage()
                return true
            }

            startPage()

            // Title and subtitle
            draw("Expense Report", font: .boldSystemFont(ofSize: 24), in: line(height: 30, y: y))
            y += 32
            draw(subtitle(for: sorted, generatedAt: generatedAt, calendar: calendar),
                 font: .systemFont(ofSize: 11), color: .secondaryLabel, in: line(height: 16, y: y))
            y += 30

            // Total
            draw("Total spent", font: .systemFont(ofSize: 12), color: .secondaryLabel, in: line(height: 16, y: y))
            y += 16
            draw(summary.total.inr, font: .boldSystemFont(ofSize: 28), in: line(height: 36, y: y))
            y += 50

            // By category
            draw("By Category", font: .boldSystemFont(ofSize: 15), in: line(height: 20, y: y))
            y += 26
            for item in summary.categoryTotals {
                _ = ensureSpace(rowHeight)
                let share = summary.total > 0 ? Double(item.amount) / Double(summary.total) : 0
                draw("\(item.category.emoji)  \(item.category.name)", font: .systemFont(ofSize: 11),
                     in: CGRect(x: margin, y: y, width: 300, height: rowHeight))
                draw(share.formatted(.percent.precision(.fractionLength(0))), font: .systemFont(ofSize: 11),
                     color: .secondaryLabel, in: CGRect(x: margin + 300, y: y, width: 100, height: rowHeight), alignment: .right)
                draw(item.amount.inr, font: .systemFont(ofSize: 11),
                     in: CGRect(x: margin + 400, y: y, width: page.width - 2 * margin - 400, height: rowHeight), alignment: .right)
                y += rowHeight
            }
            y += 24

            // Every expense, oldest first, with the column headings repeated on each new page
            _ = ensureSpace(60)
            draw("All Expenses", font: .boldSystemFont(ofSize: 15), in: line(height: 20, y: y))
            y += 26
            drawTableHeader(at: &y)

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_IN")
            formatter.timeZone = timeZone
            formatter.dateFormat = "d MMM yyyy, HH:mm"

            for (index, expense) in sorted.enumerated() {
                if ensureSpace(rowHeight) { drawTableHeader(at: &y) }
                if index.isMultiple(of: 2) {
                    UIColor.secondarySystemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).setFill()
                    UIRectFill(CGRect(x: margin - 4, y: y - 2, width: page.width - 2 * margin + 8, height: rowHeight))
                }
                let font = UIFont.systemFont(ofSize: 10)
                draw(formatter.string(from: expense.date), font: font,
                     in: CGRect(x: dateColumn.x, y: y, width: dateColumn.width, height: rowHeight))
                draw(expense.merchant, font: font,
                     in: CGRect(x: merchantColumn.x, y: y, width: merchantColumn.width, height: rowHeight))
                draw(expense.category.map { "\($0.emoji) \($0.name)" } ?? "", font: font,
                     in: CGRect(x: categoryColumn.x, y: y, width: categoryColumn.width, height: rowHeight))
                draw(expense.amount.inr, font: font,
                     in: CGRect(x: categoryColumn.x + categoryColumn.width, y: y,
                                width: page.width - margin - categoryColumn.x - categoryColumn.width, height: rowHeight),
                     alignment: .right)
                y += rowHeight
            }
        }
    }

    // MARK: Drawing helpers

    private static func drawTableHeader(at y: inout CGFloat) {
        let font = UIFont.boldSystemFont(ofSize: 10)
        draw("Date", font: font, color: .secondaryLabel, in: CGRect(x: dateColumn.x, y: y, width: dateColumn.width, height: rowHeight))
        draw("Merchant", font: font, color: .secondaryLabel, in: CGRect(x: merchantColumn.x, y: y, width: merchantColumn.width, height: rowHeight))
        draw("Category", font: font, color: .secondaryLabel, in: CGRect(x: categoryColumn.x, y: y, width: categoryColumn.width, height: rowHeight))
        draw("Amount", font: font, color: .secondaryLabel,
             in: CGRect(x: categoryColumn.x + categoryColumn.width, y: y,
                        width: page.width - margin - categoryColumn.x - categoryColumn.width, height: rowHeight),
             alignment: .right)
        y += rowHeight
        UIColor.separator.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).setFill()
        UIRectFill(CGRect(x: margin, y: y - 4, width: page.width - 2 * margin, height: 0.5))
    }

    private static func line(height: CGFloat, y: CGFloat) -> CGRect {
        CGRect(x: margin, y: y, width: page.width - 2 * margin, height: height)
    }

    /// Draws one line of text, cut off with "…" if it doesn't fit. Colours are always the light-mode versions,
    /// because the page is white even when the phone is in dark mode.
    private static func draw(_ text: String, font: UIFont, color: UIColor = .label, in rect: CGRect,
                             alignment: NSTextAlignment = .left) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)),
            .paragraphStyle: style,
        ]
        NSAttributedString(string: text, attributes: attributes).draw(in: rect)
    }

    private static func subtitle(for sorted: [Expense], generatedAt: Date, calendar: Calendar) -> String {
        let style = Date.FormatStyle(date: .abbreviated, time: .omitted, locale: Locale(identifier: "en_IN"),
                                     calendar: calendar, timeZone: calendar.timeZone)
        let count = "\(sorted.count) \(sorted.count == 1 ? "expense" : "expenses")"
        let generated = "Generated \(generatedAt.formatted(style))"
        guard let first = sorted.first?.date, let last = sorted.last?.date else {
            return "\(count) · \(generated)"
        }
        return "\(first.formatted(style)) – \(last.formatted(style)) · \(count) · \(generated)"
    }
}
