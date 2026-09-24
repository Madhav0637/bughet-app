package com.madhav0637.budgetapp.domain

import com.madhav0637.budgetapp.data.Category
import com.madhav0637.budgetapp.data.ExpenseWithCategory

/** What the dashboard shows for one period: the total, spending per category, and the latest expenses. */
class SpendingSummary(expenses: List<ExpenseWithCategory>, range: DateRange, recentLimit: Int = 5) {
    data class CategoryTotal(val category: Category, val amount: Long)

    private val inPeriod = expenses.filter { it.expense.date in range }

    val total: Long = inPeriod.sumOf { it.expense.amount }

    /** Highest amount first; ties sorted by category name. Categories with no spending are left out. */
    val categoryTotals: List<CategoryTotal> = inPeriod
        .groupBy { it.category.id }
        .map { (_, items) -> CategoryTotal(items.first().category, items.sumOf { it.expense.amount }) }
        .sortedWith(compareByDescending<CategoryTotal> { it.amount }.thenBy(String.CASE_INSENSITIVE_ORDER) { it.category.name })

    /** Newest first. */
    val recent: List<ExpenseWithCategory> = inPeriod.sortedByDescending { it.expense.date }.take(recentLimit)
}
