package com.madhav0637.budgetapp.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface CategoryDao {
    @Insert
    suspend fun insertAll(categories: List<Category>)

    /** Most-used first; ties sorted alphabetically, ignoring case. */
    @Query(
        """
        SELECT categories.* FROM categories
        LEFT JOIN expenses ON expenses.categoryId = categories.id
        GROUP BY categories.id
        ORDER BY COUNT(expenses.id) DESC, categories.name COLLATE NOCASE ASC
        """,
    )
    fun observeByUsage(): Flow<List<Category>>
}

@Dao
interface ExpenseDao {
    @Insert
    suspend fun insert(expense: Expense)

    /** Newest first. The returned Flow emits again whenever the data changes. */
    @Transaction
    @Query("SELECT * FROM expenses ORDER BY date DESC")
    fun observeAllWithCategory(): Flow<List<ExpenseWithCategory>>
}
