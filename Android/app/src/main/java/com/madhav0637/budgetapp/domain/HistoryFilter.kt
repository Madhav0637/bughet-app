package com.madhav0637.budgetapp.domain

import com.madhav0637.budgetapp.data.ExpenseWithCategory
import java.text.Normalizer
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/** The History screen's search, category filter and day grouping, kept free of UI code so it can be tested. */
data class HistoryFilter(val searchText: String = "", val categoryId: String? = null) {
    data class DayGroup(val day: LocalDate, val expenses: List<ExpenseWithCategory>)

    val isActive: Boolean get() = searchText.isNotBlank() || categoryId != null

    /** Merchant search ignores case and accents; it combines with the category filter. */
    fun apply(expenses: List<ExpenseWithCategory>): List<ExpenseWithCategory> {
        val query = fold(searchText.trim())
        return expenses.filter { item ->
            (query.isEmpty() || fold(item.expense.merchant).contains(query)) &&
                (categoryId == null || item.category.id == categoryId)
        }
    }

    companion object {
        /** Newest day first, and newest expense first within each day. */
        fun groupByDay(expenses: List<ExpenseWithCategory>, zone: ZoneId = ZoneId.systemDefault()): List<DayGroup> =
            expenses
                .groupBy { it.expense.date.atZone(zone).toLocalDate() }
                .toSortedMap(reverseOrder())
                .map { (day, items) -> DayGroup(day, items.sortedByDescending { it.expense.date }) }

        private val dayFormat = DateTimeFormatter.ofPattern("EEE, d MMM", Locale.ENGLISH)
        private val dayWithYearFormat = DateTimeFormatter.ofPattern("EEE, d MMM yyyy", Locale.ENGLISH)

        /** "Today", "Yesterday", or a date like "Mon, 21 Sep" (with the year if it isn't this year). */
        fun title(day: LocalDate, today: LocalDate = LocalDate.now()): String = when {
            day == today -> "Today"
            day == today.minusDays(1) -> "Yesterday"
            day.year == today.year -> dayFormat.format(day)
            else -> dayWithYearFormat.format(day)
        }

        /** Lowercase with accents removed, so "Café" matches "cafe". */
        private fun fold(text: String): String =
            Normalizer.normalize(text, Normalizer.Form.NFD)
                .replace(Regex("\\p{Mn}+"), "")
                .lowercase(Locale.ROOT)
    }
}
