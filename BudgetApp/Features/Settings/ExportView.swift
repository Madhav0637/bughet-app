import SwiftData
import SwiftUI

/// Choose how to export: a CSV spreadsheet or a PDF report. Both files are written fresh when the screen opens,
/// then shared as real files so they keep their .csv or .pdf name.
struct ExportView: View {
    @Query private var expenses: [Expense]
    @State private var files: [ExportFormat: URL] = [:]
    @State private var errorMessage: String?

    private let directory = FileManager.default.temporaryDirectory.appending(path: "Export", directoryHint: .isDirectory)

    var body: some View {
        List {
            Section {
                exportRow(.csv, title: "Spreadsheet (CSV)", systemImage: "tablecells",
                          detail: "Every expense as rows. Opens in Excel, Numbers or Google Sheets.")
                exportRow(.pdf, title: "Report (PDF)", systemImage: "doc.richtext",
                          detail: "A printable summary: total, spending by category, and every expense.")
            } header: {
                Text("Choose a format")
            } footer: {
                Text(footer)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: expenses.count) { writeFiles() }
        .alert("Couldn't create the file", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func exportRow(_ format: ExportFormat, title: String, systemImage: String, detail: String) -> some View {
        let label = Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.secondary) // plain grey, not the button's blue
            }
        } icon: {
            Image(systemName: systemImage)
        }

        if let url = files[format] {
            ShareLink(item: url) { label }
        } else {
            label.foregroundStyle(.secondary)
        }
    }

    private var footer: String {
        if expenses.isEmpty { return "Nothing to export yet." }
        let noun = expenses.count == 1 ? "expense" : "expenses"
        return "Includes all \(expenses.count) \(noun). Your data lives only on this iPhone, so an export is also your backup."
    }

    private func writeFiles() {
        guard !expenses.isEmpty else {
            files = [:]
            return
        }
        do {
            var written: [ExportFormat: URL] = [:]
            for format in ExportFormat.allCases {
                written[format] = try ExportWriter.write(format, expenses: expenses, to: directory)
            }
            files = written
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
