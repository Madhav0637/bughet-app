package com.madhav0637.budgetapp.domain

import java.time.DayOfWeek
import java.time.Instant
import java.time.ZoneId
import java.time.temporal.TemporalAdjusters

enum class Period(val title: String, val phrase: String) {
    Week("Week", "this week"),
    Month("Month", "this month"),
    Year("Year", "this year"),
}

/** From [start] up to, but not including, [endExclusive]. */
data class DateRange(val start: Instant, val endExclusive: Instant) {
    operator fun contains(instant: Instant): Boolean = !instant.isBefore(start) && instant.isBefore(endExclusive)

    companion object {
        val Everything = DateRange(Instant.MIN, Instant.MAX)
    }
}

/** Date ranges for the dashboard's periods. Weeks always start on Monday, months on the 1st. */
class PeriodCalculator(private val zone: ZoneId = ZoneId.systemDefault()) {
    fun range(period: Period, containing: Instant = Instant.now()): DateRange {
        val day = containing.atZone(zone).toLocalDate()
        val (first, next) = when (period) {
            Period.Week -> {
                val monday = day.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                monday to monday.plusWeeks(1)
            }
            Period.Month -> day.withDayOfMonth(1).let { it to it.plusMonths(1) }
            Period.Year -> day.withDayOfYear(1).let { it to it.plusYears(1) }
        }
        return DateRange(first.atStartOfDay(zone).toInstant(), next.atStartOfDay(zone).toInstant())
    }
}
