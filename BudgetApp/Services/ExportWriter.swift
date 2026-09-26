import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case csv, pdf

    var id: Self { self }
    var fileExtension: String { rawValue }
}

/// Writes export files to disk, so the share sheet sends a real file with the right name and extension.
enum ExportWriter {
    /// A file name like `Koku-expenses-2026-09-24.pdf`.
    static func fileName(for format: ExportFormat, on date: Date = .now, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let day = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        return "Koku-expenses-\(day).\(format.fileExtension)"
    }

    /// Writes the export into `directory` (replacing any older file with the same name) and returns its location.
    @discardableResult
    static func write(_ format: ExportFormat, expenses: [Expense], to directory: URL,
                      now: Date = .now, timeZone: TimeZone = .current) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: fileName(for: format, on: now, timeZone: timeZone))
        let data: Data = switch format {
        case .csv: Data(CSVExporter.csv(for: expenses, timeZone: timeZone).utf8)
        case .pdf: PDFReport.data(for: expenses, generatedAt: now, timeZone: timeZone)
        }
        try data.write(to: url, options: .atomic)
        return url
    }
}
