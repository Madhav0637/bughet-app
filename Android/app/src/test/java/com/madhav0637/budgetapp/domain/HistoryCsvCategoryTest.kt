package com.madhav0637.budgetapp.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class HistoryFilterTest {
    private val food = category("Food")
    private val transport = category("Transport")
    private val expenses = listOf(
        expense(400, transport, merchant = "Uber Intercity", date = at(2026, 9, 23, 8)),
        expense(90, food, merchant = "Café Coffee Day", date = at(2026, 9, 22, 17)),
        expense(250, food, merchant = "Swiggy", date = at(2026, 9, 21, 13)),
        expense(180, transport, merchant = "Uber", date = at(2026, 9, 21, 9)),
    )

    private fun merchants(filter: HistoryFilter) = filter.apply(expenses).map { it.expense.merchant }

    @Test
    fun noFilterReturnsEverything() {
        assertEquals(4, HistoryFilter().apply(expenses).size)
        assertFalse(HistoryFilter().isActive)
        assertFalse(HistoryFilter(searchText = "   ").isActive)
    }

    @Test
    fun searchIgnoresCaseAccentsAndSpaces() {
        assertEquals(listOf("Uber Intercity", "Uber"), merchants(HistoryFilter(searchText = "uBeR")))
        assertEquals(listOf("Café Coffee Day"), merchants(HistoryFilter(searchText = "  cafe ")))
    }

    @Test
    fun filtersByCategoryAndCombinesWithSearch() {
        assertEquals(listOf("Café Coffee Day", "Swiggy"), merchants(HistoryFilter(categoryId = food.id)))
        assertEquals(listOf("Uber Intercity"), merchants(HistoryFilter(searchText = "intercity", categoryId = transport.id)))
        assertTrue(merchants(HistoryFilter(searchText = "swiggy", categoryId = transport.id)).isEmpty())
    }

    @Test
    fun groupsByDayNewestFirst() {
        val groups = HistoryFilter.groupByDay(expenses.shuffled(), IST)
        assertEquals(
            listOf(LocalDate.of(2026, 9, 23), LocalDate.of(2026, 9, 22), LocalDate.of(2026, 9, 21)),
            groups.map { it.day },
        )
        assertEquals(listOf("Swiggy", "Uber"), groups.last().expenses.map { it.expense.merchant })
    }

    @Test
    fun dayTitles() {
        val today = LocalDate.of(2026, 9, 23)
        assertEquals("Today", HistoryFilter.title(today, today))
        assertEquals("Yesterday", HistoryFilter.title(today.minusDays(1), today))
        assertEquals("Mon, 21 Sep", HistoryFilter.title(LocalDate.of(2026, 9, 21), today))
        assertEquals("Wed, 31 Dec 2025", HistoryFilter.title(LocalDate.of(2025, 12, 31), today))
    }
}

class CsvExporterTest {
    private val food = category("Food")

    private fun lines(vararg items: com.madhav0637.budgetapp.data.ExpenseWithCategory) =
        CsvExporter.csv(items.toList(), IST).also { assertTrue(it.endsWith("\n")) }.trimEnd('\n').split("\n")

    @Test
    fun noExpensesGivesJustTheHeader() {
        assertEquals(listOf("Date,Merchant,Category,Amount"), lines())
    }

    @Test
    fun oneRowPerExpenseOldestFirst() {
        assertEquals(
            listOf("Date,Merchant,Category,Amount", "2026-09-01 12:00,First,Food,1", "2026-09-23 20:05,Swiggy,Food,1250"),
            lines(expense(1250, food, "Swiggy", at(2026, 9, 23, 20, 5)), expense(1, food, "First", at(2026, 9, 1))),
        )
    }

    @Test
    fun escapesCommasQuotesAndLineBreaks() {
        assertEquals("\"Chai, Samosa\"", CsvExporter.escape("Chai, Samosa"))
        assertEquals("\"Joe's \"\"Best\"\" Café\"", CsvExporter.escape("Joe's \"Best\" Café"))
        assertEquals("\"Line one\nLine two\"", CsvExporter.escape("Line one\nLine two"))
        assertEquals("Apollo Pharmacy", CsvExporter.escape("Apollo Pharmacy"))
    }

    @Test
    fun textThatLooksLikeAFormulaIsDefused() {
        for (text in listOf("=SUM(A1)", "+91 Store", "-Refund", "@home")) {
            assertEquals("'$text", CsvExporter.escape(text))
        }
    }

    @Test
    fun categoryNamesAreEscapedToo() {
        assertEquals(
            "2026-09-01 12:00,Landlord,\"Bills, Rent\",15000",
            lines(expense(15000, category("Bills, Rent"), "Landlord", at(2026, 9, 1))).last(),
        )
    }
}

class CategoryRulesTest {
    @Test
    fun trimsTheName() {
        assertEquals("Rent", CategoryRules.validated("  Rent ", "🏠", emptyList()))
    }

    @Test
    fun rejectsAnEmptyName() {
        assertThrows(CategoryError.EmptyName::class.java) { CategoryRules.validated("   ", "🏠", emptyList()) }
    }

    @Test
    fun rejectsADuplicateNameIgnoringCase() {
        for (name in listOf("Food", "food", " FOOD ")) {
            assertThrows(CategoryError.DuplicateName::class.java) { CategoryRules.validated(name, "🍕", listOf("Food")) }
        }
    }

    @Test
    fun acceptsSingleEmoji() {
        for (emoji in listOf("🍔", "🛍️", "❤️", "☕", "☕️", "🧑🏽‍🍳", "🇮🇳", "⭐")) {
            assertTrue("expected $emoji to be valid", CategoryRules.isValidEmoji(emoji))
        }
    }

    @Test
    fun rejectsAnythingButOneEmoji() {
        for (text in listOf("", "a", "1", "#", "🍔🍕", "ab", "❤")) {
            assertFalse("expected '$text' to be invalid", CategoryRules.isValidEmoji(text))
        }
    }

    @Test
    fun emojiBoxKeepsOnlyTheLastCharacter() {
        assertEquals("🍕", CategoryRules.lastCharacter("🍔🍕"))
        assertEquals("🧑🏽‍🍳", CategoryRules.lastCharacter("🍔🧑🏽‍🍳")) // a multi-part emoji stays whole
        assertEquals("🇮🇳", CategoryRules.lastCharacter("a🇮🇳"))
        assertEquals("", CategoryRules.lastCharacter(""))
    }

    @Test
    fun inUseMessageUsesTheRightWord() {
        assertTrue(CategoryError.InUse(1).message!!.startsWith("Used by 1 expense."))
        assertTrue(CategoryError.InUse(3).message!!.startsWith("Used by 3 expenses."))
    }
}
