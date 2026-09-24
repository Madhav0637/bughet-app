package com.madhav0637.budgetapp.domain

import com.madhav0637.budgetapp.data.ExpenseWithCategory
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Turns expenses into a CSV file that opens cleanly in Excel, Numbers or Google Sheets. Same format as iOS. */
object CsvExporter {
    const val HEADER = "Date,Merchant,Category,Amount"

    /** Oldest expense first. Dates are `yyyy-MM-dd HH:mm` in the given time zone; amounts are plain whole rupees. */
    fun csv(expenses: List<ExpenseWithCategory>, zone: ZoneId = ZoneId.systemDefault()): String {
        val dateFormat = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm", Locale.ROOT).withZone(zone)
        val rows = expenses.sortedBy { it.expense.date }.map { item ->
            listOf(
                dateFormat.format(item.expense.date),
                escape(item.expense.merchant),
                escape(item.category.name),
                item.expense.amount.toString(),
            ).joinToString(",")
        }
        return (listOf(HEADER) + rows).joinToString("\n") + "\n"
    }

    /**
     * Quotes a field when it contains a comma, quote or line break (doubling any quotes inside it).
     * Text starting with = + - or @ gets a leading apostrophe so spreadsheets don't run it as a formula.
     */
    fun escape(field: String): String {
        val safe = if (field.firstOrNull()?.let { it in "=+-@" } == true) "'$field" else field
        val needsQuotes = safe.any { it == ',' || it == '"' || it == '\n' || it == '\r' }
        return if (needsQuotes) "\"" + safe.replace("\"", "\"\"") + "\"" else safe
    }
}
