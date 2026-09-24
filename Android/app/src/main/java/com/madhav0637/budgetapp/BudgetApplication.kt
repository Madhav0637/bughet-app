package com.madhav0637.budgetapp

import android.app.Application
import com.madhav0637.budgetapp.data.AppDatabase
import com.madhav0637.budgetapp.domain.CategoryService
import com.madhav0637.budgetapp.domain.ExpenseService

/** Creates the database and services once, for every screen to share. */
class BudgetApplication : Application() {
    val database: AppDatabase by lazy { AppDatabase.create(this) }
    val expenseService: ExpenseService by lazy { ExpenseService(database.expenseDao()) }
    val categoryService: CategoryService by lazy { CategoryService(database.categoryDao()) }
}
