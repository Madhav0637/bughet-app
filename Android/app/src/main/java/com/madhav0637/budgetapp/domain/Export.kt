package com.madhav0637.budgetapp.domain

import com.madhav0637.budgetapp.data.ExpenseWithCategory
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.roundToInt

enum class ExportFormat(val extension: String, val mimeType: String) {
    Csv("csv", "text/csv"),
    Pdf("pdf", "application/pdf"),
}

object ExportNames {
    private val day = DateTimeFormatter.ofPattern("yyyy-MM-dd", Locale.ROOT)

    /** A file name like `BudgetApp-expenses-2026-09-24.pdf`, the same as on iOS. */
    fun fileName(format: ExportFormat, now: Instant = Instant.now(), zone: ZoneId = ZoneId.systemDefault()): String =
        "BudgetApp-expenses-${day.format(now.atZone(zone))}.${format.extension}"
}

/**
 * Everything the PDF report says, worked out as plain text so it can be tested without drawing anything.
 * The layout matches the iOS report: title, date range, total, spending by category, and every expense.
 */
data class ReportContent(
    val title: String,
    val subtitle: String,
    val total: String,
    val categoryRows: List<CategoryRow>,
    val expenseRows: List<ExpenseRow>,
) {
    data class CategoryRow(val label: String, val share: String, val amount: String)
    data class ExpenseRow(val date: String, val merchant: String, val category: String, val amount: String)

    companion object {
        private val shortDate = DateTimeFormatter.ofPattern("d MMM yyyy", Locale.ENGLISH)
        private val rowDate = DateTimeFormatter.ofPattern("d MMM yyyy, HH:mm", Locale.ENGLISH)

        fun from(expenses: List<ExpenseWithCategory>, generatedAt: Instant = Instant.now(), zone: ZoneId = ZoneId.systemDefault()): ReportContent {
            val summary = SpendingSummary(expenses, DateRange.Everything)
            val sorted = expenses.sortedBy { it.expense.date }
            val count = "${sorted.size} ${if (sorted.size == 1) "expense" else "expenses"}"
            val generated = "Generated ${shortDate.format(generatedAt.atZone(zone))}"
            val range = if (sorted.isEmpty()) {
                null
            } else {
                "${shortDate.format(sorted.first().expense.date.atZone(zone))} – ${shortDate.format(sorted.last().expense.date.atZone(zone))}"
            }

            return ReportContent(
                title = "Expense Report",
                subtitle = listOfNotNull(range, count, generated).joinToString(" · "),
                total = summary.total.inr(),
                categoryRows = summary.categoryTotals.map {
                    val share = if (summary.total > 0) (it.amount * 100.0 / summary.total).roundToInt() else 0
                    CategoryRow("${it.category.emoji}  ${it.category.name}", "$share%", it.amount.inr())
                },
                expenseRows = sorted.map {
                    ExpenseRow(
                        date = rowDate.format(it.expense.date.atZone(zone)),
                        merchant = it.expense.merchant,
                        category = "${it.category.emoji} ${it.category.name}",
                        amount = it.expense.amount.inr(),
                    )
                },
            )
        }
    }
}
