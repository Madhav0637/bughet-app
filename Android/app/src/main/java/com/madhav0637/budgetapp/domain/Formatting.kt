package com.madhav0637.budgetapp.domain

/**
 * Whole rupees with Indian digit grouping, e.g. ₹1,23,456: the last three digits, then groups of two.
 * Written by hand because Java's built-in number formatting only supports equal-sized groups.
 */
fun Long.inr(): String {
    val digits = kotlin.math.abs(this).toString()
    val grouped = if (digits.length <= 3) {
        digits
    } else {
        val head = digits.dropLast(3)
        val firstGroup = head.length % 2
        val pairs = head.drop(firstGroup).chunked(2)
        (listOfNotNull(head.take(firstGroup).ifEmpty { null }) + pairs + digits.takeLast(3)).joinToString(",")
    }
    return (if (this < 0) "-₹" else "₹") + grouped
}

/** Keeps only 0–9, for the amount box. */
fun digitsOnly(text: String): String = text.filter { it in '0'..'9' }
