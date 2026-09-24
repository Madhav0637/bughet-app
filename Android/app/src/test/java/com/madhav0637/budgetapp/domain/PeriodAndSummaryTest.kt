package com.madhav0637.budgetapp.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PeriodCalculatorTest {
    private val calculator = PeriodCalculator(IST)

    @Test
    fun weekRunsMondayToMonday() {
        val range = calculator.range(Period.Week, at(2026, 9, 23)) // Wednesday
        assertEquals(at(2026, 9, 21, 0), range.start)
        assertEquals(at(2026, 9, 28, 0), range.endExclusive)
    }

    @Test
    fun sundayBelongsToTheWeekThatStartedOnMonday() {
        assertEquals(at(2026, 9, 21, 0), calculator.range(Period.Week, at(2026, 9, 27, 23, 59)).start)
    }

    @Test
    fun mondayMidnightStartsANewWeek() {
        assertEquals(at(2026, 9, 28, 0), calculator.range(Period.Week, at(2026, 9, 28, 0)).start)
    }

    @Test
    fun weekCanCrossMonthAndYear() {
        val range = calculator.range(Period.Week, at(2026, 1, 1)) // Thursday
        assertEquals(at(2025, 12, 29, 0), range.start)
        assertEquals(at(2026, 1, 5, 0), range.endExclusive)
    }

    @Test
    fun monthRunsFromTheFirst() {
        val range = calculator.range(Period.Month, at(2026, 9, 23))
        assertEquals(at(2026, 9, 1, 0), range.start)
        assertEquals(at(2026, 10, 1, 0), range.endExclusive)
    }

    @Test
    fun februaryInALeapYear() {
        assertEquals(at(2028, 3, 1, 0), calculator.range(Period.Month, at(2028, 2, 10)).endExclusive)
    }

    @Test
    fun yearRunsJanuaryToJanuary() {
        val range = calculator.range(Period.Year, at(2026, 9, 23))
        assertEquals(at(2026, 1, 1, 0), range.start)
        assertEquals(at(2027, 1, 1, 0), range.endExclusive)
    }

    @Test
    fun rangeIncludesItsStartButNotItsEnd() {
        val range = calculator.range(Period.Month, at(2026, 9, 15))
        assertTrue(range.start in range)
        assertFalse(range.endExclusive in range)
    }

    @Test
    fun periodLabels() {
        assertEquals(listOf("Week", "Month", "Year"), Period.entries.map { it.title })
        assertEquals(listOf("this week", "this month", "this year"), Period.entries.map { it.phrase })
    }
}

class SpendingSummaryTest {
    private val food = category("Food")
    private val bills = category("Bills")
    private val transport = category("Transport")
    private val september = PeriodCalculator(IST).range(Period.Month, at(2026, 9, 15))

    @Test
    fun emptyPeriod() {
        val summary = SpendingSummary(emptyList(), september)
        assertEquals(0L, summary.total)
        assertTrue(summary.categoryTotals.isEmpty())
        assertTrue(summary.recent.isEmpty())
    }

    @Test
    fun totalsOnlyExpensesInsideThePeriod() {
        val expenses = listOf(
            expense(100, food, date = at(2026, 9, 10)),
            expense(250, bills, date = at(2026, 9, 20)),
            expense(999, food, date = at(2026, 8, 31, 23, 59)),
            expense(999, food, date = at(2026, 10, 1, 0)),
        )
        assertEquals(350L, SpendingSummary(expenses, september).total)
    }

    @Test
    fun groupsByCategoryHighestFirstAndAddsUp() {
        val expenses = listOf(
            expense(100, food, date = at(2026, 9, 1)),
            expense(150, food, date = at(2026, 9, 2)),
            expense(500, bills, date = at(2026, 9, 3)),
            expense(80, transport, date = at(2026, 9, 4)),
        )
        val summary = SpendingSummary(expenses, september)
        assertEquals(listOf("Bills", "Food", "Transport"), summary.categoryTotals.map { it.category.name })
        assertEquals(listOf(500L, 250L, 80L), summary.categoryTotals.map { it.amount })
        assertEquals(summary.total, summary.categoryTotals.sumOf { it.amount })
    }

    @Test
    fun equalAmountsAreSortedByName() {
        val expenses = listOf(expense(200, transport, date = at(2026, 9, 5)), expense(200, bills, date = at(2026, 9, 6)))
        assertEquals(listOf("Bills", "Transport"), SpendingSummary(expenses, september).categoryTotals.map { it.category.name })
    }

    @Test
    fun recentIsNewestFirstAndLimited() {
        val expenses = (1..7).map { expense(it * 10L, food, merchant = "Day $it", date = at(2026, 9, it)) }
        assertEquals(
            listOf("Day 7", "Day 6", "Day 5", "Day 4", "Day 3"),
            SpendingSummary(expenses, september, recentLimit = 5).recent.map { it.expense.merchant },
        )
    }
}
