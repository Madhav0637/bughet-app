package com.madhav0637.budgetapp.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ExportTest {
    private val food = category("Food", "🍔")
    private val bills = category("Bills", "🧾")
    private val expenses = listOf(
        expense(450, food, "Swiggy", at(2026, 9, 2, 13)),
        expense(1850, bills, "Electricity bill", at(2026, 9, 5, 9)),
        expense(380, food, "Zomato", at(2026, 9, 20, 21)),
    )

    @Test
    fun fileNamesHaveTheDateAndTheRightExtension() {
        val date = at(2026, 9, 4, 23, 30)
        assertEquals("BudgetApp-expenses-2026-09-04.csv", ExportNames.fileName(ExportFormat.Csv, date, IST))
        assertEquals("BudgetApp-expenses-2026-09-04.pdf", ExportNames.fileName(ExportFormat.Pdf, date, IST))
    }

    @Test
    fun mimeTypesTellOtherAppsWhatTheFileIs() {
        assertEquals("text/csv", ExportFormat.Csv.mimeType)
        assertEquals("application/pdf", ExportFormat.Pdf.mimeType)
    }

    @Test
    fun reportHasTitleDateRangeCountAndTotal() {
        val report = ReportContent.from(expenses, generatedAt = at(2026, 9, 24), zone = IST)
        assertEquals("Expense Report", report.title)
        assertEquals("2 Sep 2026 – 20 Sep 2026 · 3 expenses · Generated 24 Sep 2026", report.subtitle)
        assertEquals("₹2,680", report.total)
    }

    @Test
    fun categoriesAreHighestFirstWithRoundedShares() {
        val rows = ReportContent.from(expenses, zone = IST).categoryRows
        assertEquals(
            listOf(
                ReportContent.CategoryRow("🧾  Bills", "69%", "₹1,850"),
                ReportContent.CategoryRow("🍔  Food", "31%", "₹830"),
            ),
            rows,
        )
    }

    @Test
    fun everyExpenseIsListedOldestFirst() {
        val rows = ReportContent.from(expenses.reversed(), zone = IST).expenseRows
        assertEquals(listOf("Swiggy", "Electricity bill", "Zomato"), rows.map { it.merchant })
        assertEquals(ReportContent.ExpenseRow("2 Sep 2026, 13:00", "Swiggy", "🍔 Food", "₹450"), rows.first())
    }

    @Test
    fun emptyReportStillMakesSense() {
        val report = ReportContent.from(emptyList(), generatedAt = at(2026, 9, 24), zone = IST)
        assertEquals("0 expenses · Generated 24 Sep 2026", report.subtitle)
        assertEquals("₹0", report.total)
        assertTrue(report.categoryRows.isEmpty() && report.expenseRows.isEmpty())
    }

    @Test
    fun oneExpenseIsSingular() {
        assertTrue(ReportContent.from(expenses.take(1), zone = IST).subtitle.contains("· 1 expense ·"))
    }
}
