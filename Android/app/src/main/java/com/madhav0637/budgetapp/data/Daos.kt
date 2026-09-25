package com.madhav0637.budgetapp.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface CategoryDao {
    @Insert
    suspend fun insert(category: Category)

    @Insert
    suspend fun insertAll(categories: List<Category>)

    @Update
    suspend fun update(category: Category)

    @Delete
    suspend fun delete(category: Category)

    @Query("SELECT * FROM categories")
    suspend fun getAll(): List<Category>

    @Query("SELECT COUNT(*) FROM categories")
    suspend fun count(): Int

    @Query("SELECT COUNT(*) FROM expenses WHERE categoryId = :categoryId")
    suspend fun expenseCount(categoryId: String): Int

    /** Moves every expense from one category to another in a single statement. */
    @Query("UPDATE expenses SET categoryId = :toId WHERE categoryId = :fromId")
    suspend fun moveExpenses(fromId: String, toId: String)

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

    /** Same order as [observeByUsage], with each category's expense count. */
    @Query(
        """
        SELECT categories.*, COUNT(expenses.id) AS expenseCount FROM categories
        LEFT JOIN expenses ON expenses.categoryId = categories.id
        GROUP BY categories.id
        ORDER BY COUNT(expenses.id) DESC, categories.name COLLATE NOCASE ASC
        """,
    )
    fun observeByUsageWithCounts(): Flow<List<CategoryWithCount>>
}

@Dao
interface ExpenseDao {
    @Insert
    suspend fun insert(expense: Expense)

    @Update
    suspend fun update(expense: Expense)

    @Delete
    suspend fun delete(expense: Expense)

    /** Newest first. The returned Flow emits again whenever the data changes. */
    @Transaction
    @Query("SELECT * FROM expenses ORDER BY date DESC")
    fun observeAllWithCategory(): Flow<List<ExpenseWithCategory>>
}
