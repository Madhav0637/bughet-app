package com.madhav0637.budgetapp.export

import com.madhav0637.budgetapp.data.ExpenseWithCategory
import com.madhav0637.budgetapp.domain.CsvExporter
import com.madhav0637.budgetapp.domain.ExportFormat
import com.madhav0637.budgetapp.domain.ExportNames
import com.madhav0637.budgetapp.domain.ReportContent
import java.io.File
import java.time.Instant
import java.time.ZoneId

/**
 * Writes an export to a real file first, so the share sheet sends it with the right name and extension
 * (handing over plain text is what made the first iOS version save CSVs as .txt).
 */
object ExportWriter {
    fun write(
        format: ExportFormat,
        expenses: List<ExpenseWithCategory>,
        directory: File,
        now: Instant = Instant.now(),
        zone: ZoneId = ZoneId.systemDefault(),
    ): File {
        directory.mkdirs()
        val file = File(directory, ExportNames.fileName(format, now, zone))
        file.outputStream().use { out ->
            when (format) {
                ExportFormat.Csv -> out.write(CsvExporter.csv(expenses, zone).toByteArray(Charsets.UTF_8))
                ExportFormat.Pdf -> PdfReportRenderer.render(ReportContent.from(expenses, now, zone), out)
            }
        }
        return file
    }
}
