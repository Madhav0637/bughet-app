package com.madhav0637.budgetapp.domain

import com.madhav0637.budgetapp.data.Category
import com.madhav0637.budgetapp.data.CategoryDao
import com.madhav0637.budgetapp.data.Expense
import com.madhav0637.budgetapp.data.ExpenseDao
import java.time.Instant
import java.time.temporal.ChronoUnit

/** The only place expenses are saved, so the pop-up and the app's screens follow the same rules. */
class ExpenseService(private val dao: ExpenseDao) {
    suspend fun add(merchant: String, amount: Long, categoryId: String, date: Instant = Instant.now()): Expense {
        val expense = Expense(
            merchant = ExpenseRules.validated(merchant, amount),
            amount = amount,
            date = date.toStoredPrecision(),
            categoryId = categoryId,
        )
        dao.insert(expense)
        return expense
    }

    /** Validates everything first, so an invalid edit leaves the expense untouched. */
    suspend fun update(expense: Expense, merchant: String, amount: Long, categoryId: String, date: Instant): Expense {
        val updated = expense.copy(
            merchant = ExpenseRules.validated(merchant, amount),
            amount = amount,
            categoryId = categoryId,
            date = date.toStoredPrecision(),
        )
        dao.update(updated)
        return updated
    }

    suspend fun delete(expense: Expense) = dao.delete(expense)

    /** Puts back an expense that was just deleted, for Undo. */
    suspend fun restore(expense: Expense) = dao.insert(expense)

    /** The database keeps milliseconds; rounding first means the returned expense matches what was stored. */
    private fun Instant.toStoredPrecision(): Instant = truncatedTo(ChronoUnit.MILLIS)
}

class CategoryService(private val dao: CategoryDao) {
    suspend fun add(name: String, emoji: String): Category {
        val others = dao.getAll().map { it.name }
        val category = Category(name = CategoryRules.validated(name, emoji, others), emoji = emoji)
        dao.insert(category)
        return category
    }

    suspend fun update(category: Category, name: String, emoji: String): Category {
        val others = dao.getAll().filter { it.id != category.id }.map { it.name }
        val updated = category.copy(name = CategoryRules.validated(name, emoji, others), emoji = emoji)
        dao.update(updated)
        return updated
    }

    suspend fun moveAllExpenses(from: Category, to: Category) {
        if (from.id == to.id) throw CategoryError.SameCategory
        dao.moveExpenses(from.id, to.id)
    }

    /** Only empty categories can be deleted, and never the last one. */
    suspend fun delete(category: Category) {
        val inUse = dao.expenseCount(category.id)
        if (inUse > 0) throw CategoryError.InUse(inUse)
        if (dao.count() <= 1) throw CategoryError.LastCategory
        dao.delete(category)
    }
}
