package com.madhav0637.budgetapp.domain

import com.madhav0637.budgetapp.data.Expense
import com.madhav0637.budgetapp.data.ExpenseDao
import java.time.Instant

object DefaultCategories {
    data class Item(val emoji: String, val name: String)

    val all = listOf(
        Item("🍔", "Food"),
        Item("🚕", "Transport"),
        Item("🛍️", "Shopping"),
        Item("🧾", "Bills"),
        Item("🎬", "Entertainment"),
        Item("💊", "Health"),
        Item("📦", "Other"),
    )
}

sealed class ExpenseError(message: String) : Exception(message) {
    data object EmptyMerchant : ExpenseError("Please enter what you spent on.")
    data object NonPositiveAmount : ExpenseError("Amount must be more than ₹0.")
}

object ExpenseRules {
    /** Returns the trimmed merchant, or throws if the merchant or amount isn't allowed. */
    fun validated(merchant: String, amount: Long): String {
        val trimmed = merchant.trim()
        if (trimmed.isEmpty()) throw ExpenseError.EmptyMerchant
        if (amount <= 0) throw ExpenseError.NonPositiveAmount
        return trimmed
    }
}

/** The only place expenses are saved, so the pop-up and the app's screens follow the same rules. */
class ExpenseService(private val dao: ExpenseDao) {
    suspend fun add(merchant: String, amount: Long, categoryId: String, date: Instant = Instant.now()): Expense {
        val expense = Expense(
            merchant = ExpenseRules.validated(merchant, amount),
            amount = amount,
            date = date,
            categoryId = categoryId,
        )
        dao.insert(expense)
        return expense
    }
}
