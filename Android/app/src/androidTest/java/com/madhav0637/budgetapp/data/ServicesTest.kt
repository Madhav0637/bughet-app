package com.madhav0637.budgetapp.data

import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.madhav0637.budgetapp.domain.CategoryError
import com.madhav0637.budgetapp.domain.CategoryService
import com.madhav0637.budgetapp.domain.ExpenseError
import com.madhav0637.budgetapp.domain.ExpenseService
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.time.Instant

/** Runs on the emulator against a real Room database held in memory, so the real phone data is never touched. */
@RunWith(AndroidJUnit4::class)
class ServicesTest {
    private lateinit var db: AppDatabase
    private lateinit var expenses: ExpenseService
    private lateinit var categories: CategoryService

    @Before
    fun setUp() {
        db = AppDatabase.inMemory(ApplicationProvider.getApplicationContext())
        expenses = ExpenseService(db.expenseDao())
        categories = CategoryService(db.categoryDao())
    }

    @After
    fun tearDown() = db.close()

    private suspend fun allExpenses() = db.expenseDao().observeAllWithCategory().first()
    private suspend fun names() = db.categoryDao().getAll().map { it.name }.sorted()

    private inline fun <reified E : Throwable> assertFails(block: () -> Unit) {
        try {
            block()
            fail("Expected ${E::class.simpleName}")
        } catch (e: Throwable) {
            if (e !is E) throw e
        }
    }

    // MARK: Seeding

    @Test
    fun seedsTheSevenDefaultsWhenTheDatabaseIsCreated() = runBlocking {
        val seeded = AppDatabase.inMemory(ApplicationProvider.getApplicationContext(), seedDefaults = true)
        val seededNames = seeded.categoryDao().getAll().map { it.name }.sorted()
        seeded.close()
        assertEquals(listOf("Bills", "Entertainment", "Food", "Health", "Other", "Shopping", "Transport"), seededNames)
    }

    // MARK: Expenses

    @Test
    fun addsEditsAndDeletesAnExpense() = runBlocking {
        val food = categories.add("Food", "🍔")
        val transport = categories.add("Transport", "🚕")
        val saved = expenses.add("  Swiggy ", 250, food.id, Instant.ofEpochSecond(1_000))
        assertEquals("Swiggy", allExpenses().single().expense.merchant)

        val newDate = Instant.ofEpochSecond(2_000)
        expenses.update(saved, "Uber", 180, transport.id, newDate)
        val edited = allExpenses().single()
        assertEquals(listOf("Uber", 180L, "Transport", newDate), listOf(edited.expense.merchant, edited.expense.amount, edited.category.name, edited.expense.date))

        expenses.delete(edited.expense)
        assertTrue(allExpenses().isEmpty())
    }

    @Test
    fun invalidExpensesAreNotSaved() = runBlocking {
        val food = categories.add("Food", "🍔")
        assertFails<ExpenseError.EmptyMerchant> { runBlocking { expenses.add("  ", 100, food.id) } }
        assertFails<ExpenseError.NonPositiveAmount> { runBlocking { expenses.add("Uber", 0, food.id) } }
        assertTrue(allExpenses().isEmpty())
    }

    @Test
    fun invalidEditChangesNothing() = runBlocking {
        val food = categories.add("Food", "🍔")
        val saved = expenses.add("Swiggy", 250, food.id)
        assertFails<ExpenseError.NonPositiveAmount> { runBlocking { expenses.update(saved, "Uber", 0, food.id, Instant.now()) } }
        assertEquals(saved, allExpenses().single().expense)
    }

    @Test
    fun restoreBringsBackTheSameExpenseAfterDelete() = runBlocking {
        val food = categories.add("Food", "🍔")
        val saved = expenses.add("Pepsi", 40, food.id, Instant.ofEpochSecond(1_000))
        expenses.delete(saved)
        assertTrue(allExpenses().isEmpty())

        expenses.restore(saved)
        assertEquals(saved, allExpenses().single().expense) // same id, merchant, amount and time
    }

    // MARK: Category order

    @Test
    fun categoriesAreMostUsedFirstThenAlphabetical() = runBlocking {
        val food = categories.add("food", "🍔")
        val bills = categories.add("Bills", "🧾")
        val travel = categories.add("Travel", "✈️")
        categories.add("shopping", "🛍️")
        categories.add("Alpha", "🅰️")
        expenses.add("Rent", 10, bills.id)
        repeat(3) { expenses.add("Lunch", 10, food.id) }
        repeat(2) { expenses.add("Taxi", 10, travel.id) }

        assertEquals(
            listOf("food", "Travel", "Bills", "Alpha", "shopping"),
            db.categoryDao().observeByUsage().first().map { it.name },
        )
    }

    @Test
    fun categoriesComeWithTheirExpenseCounts() = runBlocking {
        val food = categories.add("Food", "🍔")
        val bills = categories.add("Bills", "🧾")
        categories.add("Health", "💊")
        repeat(3) { expenses.add("Lunch", 10, food.id) }
        expenses.add("Rent", 10, bills.id)

        val counts = db.categoryDao().observeByUsageWithCounts().first()
        assertEquals(listOf("Food" to 3, "Bills" to 1, "Health" to 0), counts.map { it.category.name to it.expenseCount })
    }

    // MARK: Category management

    @Test
    fun addingRejectsDuplicatesIgnoringCase() = runBlocking {
        categories.add("Food", "🍔")
        assertFails<CategoryError.DuplicateName> { runBlocking { categories.add(" FOOD ", "🍕") } }
        assertEquals(listOf("Food"), names())
    }

    @Test
    fun renamingAllowsOwnCapitalisationButNotAnotherName() = runBlocking {
        val food = categories.add("food", "🍔")
        val bills = categories.add("Bills", "🧾")
        categories.update(food, "Food", "🍽️")
        assertFails<CategoryError.DuplicateName> { runBlocking { categories.update(bills, "FOOD", "🧾") } }
        assertEquals(listOf("Bills", "Food"), names())
    }

    @Test
    fun movesAllExpensesThenDeleteWorks() = runBlocking {
        val food = categories.add("Food", "🍔")
        val other = categories.add("Other", "📦")
        expenses.add("A", 100, food.id)
        expenses.add("B", 200, food.id)

        assertFails<CategoryError.SameCategory> { runBlocking { categories.moveAllExpenses(food, food) } }
        categories.moveAllExpenses(food, other)
        assertTrue(allExpenses().all { it.category.id == other.id })

        categories.delete(food)
        assertEquals(listOf("Other"), names())
        assertEquals(2, allExpenses().size)
    }

    @Test
    fun cannotDeleteACategoryInUse() = runBlocking {
        val food = categories.add("Food", "🍔")
        categories.add("Other", "📦")
        expenses.add("A", 100, food.id)
        expenses.add("B", 200, food.id)
        try {
            categories.delete(food)
            fail("Expected InUse")
        } catch (e: CategoryError.InUse) {
            assertEquals(2, e.expenseCount)
        }
        assertEquals(listOf("Food", "Other"), names())
    }

    @Test
    fun cannotDeleteTheLastCategory() = runBlocking {
        val only = categories.add("Other", "📦")
        assertFails<CategoryError.LastCategory> { runBlocking { categories.delete(only) } }
        assertEquals(listOf("Other"), names())
    }

    @Test
    fun databaseItselfRefusesToDeleteACategoryInUse() = runBlocking {
        // Even if the service check were bypassed, the RESTRICT foreign key protects the data.
        val food = categories.add("Food", "🍔")
        expenses.add("A", 100, food.id)
        assertFails<android.database.sqlite.SQLiteConstraintException> { runBlocking { db.categoryDao().delete(food) } }
    }
}
