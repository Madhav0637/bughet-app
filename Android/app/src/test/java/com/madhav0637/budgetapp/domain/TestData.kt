package com.madhav0637.budgetapp.domain

import com.madhav0637.budgetapp.data.Category
import com.madhav0637.budgetapp.data.Expense
import com.madhav0637.budgetapp.data.ExpenseWithCategory
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId

/** India Standard Time, so tests give the same result on any machine. */
val IST: ZoneId = ZoneId.of("Asia/Kolkata")

fun at(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0): Instant =
    LocalDateTime.of(year, month, day, hour, minute).atZone(IST).toInstant()

fun category(name: String, emoji: String = "🧪") = Category(name = name, emoji = emoji)

fun expense(amount: Long, category: Category, merchant: String = "Shop", date: Instant = at(2026, 9, 15)) =
    ExpenseWithCategory(Expense(merchant = merchant, amount = amount, date = date, categoryId = category.id), category)
